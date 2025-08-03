import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'pose_painter.dart';
import 'detectHammerCurls.dart';
import 'detect_concentration_curls.dart';
import 'detect_dumbbell_curls.dart';

class CameraWorkoutScreen extends StatefulWidget {
  final int userId;
  final String category;
  final String exercise;

  const CameraWorkoutScreen({
    super.key,
    required this.userId,
    required this.category,
    required this.exercise,
  });

  @override
  State<CameraWorkoutScreen> createState() => _CameraWorkoutScreenState();
}

class _CameraWorkoutScreenState extends State<CameraWorkoutScreen> {
  CameraController? _cameraController;
  late PoseDetector _poseDetector;
  bool _isBusy = false;
  int _repCount = 0;
  int _preferredReps = 0;
  int _preferredSets = 0;
  int _currentSet = 1;
  bool _isDownPosition = false;
  Size? _imageSize;
  List<Pose> _poses = [];
  bool _isFrontCamera = true;
  bool _isInitialized = false;
  bool _showDumbbellWarning = false;
  DateTime? _lastRepTime;

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _fetchUserGoals().then((_) => _initializeCamera());
  }

  Future<void> _fetchUserGoals() async {
    final url = Uri.parse('http://192.168.0.11/repEatApi/get_user_onboarding.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.userId}),
      );

      final result = jsonDecode(response.body);
      if (result['success']) {
        setState(() {
          _preferredReps = int.tryParse(result['data']['preferred_reps'].toString()) ?? 10;
          _preferredSets = int.tryParse(result['data']['preferred_sets'].toString()) ?? 3;
        });
      } else {
        debugPrint('⚠️ ${result['message']}');
      }
    } catch (e) {
      debugPrint('Fetch onboarding error: $e');
    }
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _isFrontCamera = camera.lensDirection == CameraLensDirection.front;

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    setState(() {
      _imageSize = Size(
        _cameraController!.value.previewSize!.height,
        _cameraController!.value.previewSize!.width,
      );
      _isInitialized = true;
    });

    _cameraController!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || !mounted) return;
    _isBusy = true;

    try {
      final inputImage = _getInputImage(image);
      final poses = await _poseDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _poses = poses;
          if (widget.exercise == 'Dumbbell Curls') {
            _showDumbbellWarning = poses.isNotEmpty && !_isHoldingDumbbell(poses.first);
          }
        });
        _detectExerciseReps(poses);
      }
    } catch (e) {
      debugPrint('Pose detection error: $e');
    } finally {
      _isBusy = false;
    }
  }

  InputImage _getInputImage(CameraImage image) {
    final rotation = _isFrontCamera
        ? InputImageRotation.rotation270deg
        : InputImageRotation.rotation90deg;

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final buffer = BytesBuilder();
    for (final plane in planes) {
      buffer.add(plane.bytes);
    }
    return buffer.toBytes();
  }

  void _detectExerciseReps(List<Pose> poses) {
    if (poses.isEmpty || _currentSet > _preferredSets) return;

    final pose = poses.first;

    switch (widget.exercise) {
      case 'Hammer Curls':
        _isDownPosition = isHammerCurlRep(
          pose: pose,
          isDownPosition: _isDownPosition,
          onRepDetected: _onRepDetected,
        );
        break;
      case 'Concentration Curls':
        _isDownPosition = isConcentrationCurlRep(
          pose: pose,
          isDownPosition: _isDownPosition,
          onRepDetected: _onRepDetected,
        );
        break;
      case 'Dumbbell Curls':
        _isDownPosition = isDumbbellCurlRep(
          pose: pose,
          isDownPosition: _isDownPosition,
          onRepDetected: _onRepDetected,
        );
        break;
      default:
        debugPrint('No logic defined for this exercise: ${widget.exercise}');
        break;
    }
  }

  void _onRepDetected() {
    final now = DateTime.now();
    if (_lastRepTime != null && now.difference(_lastRepTime!).inMilliseconds < 500) {
      return;
    }
    _lastRepTime = now;

    setState(() => _repCount++);
    _checkSetCompletion();
  }

  bool _isHoldingDumbbell(Pose pose) {
    final wrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final hip = pose.landmarks[PoseLandmarkType.rightHip];

    if (wrist == null || hip == null) return false;
    return wrist.y < hip.y;
  }

  void _checkSetCompletion() {
    if (_repCount >= _preferredReps) {
      setState(() {
        _currentSet++;
        _repCount = 0;
      });

      if (_currentSet > _preferredSets) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Workout Complete!')),
        );
        saveCameraWorkout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Set $_currentSet started')),
        );
      }
    }
  }

  Future<void> saveCameraWorkout() async {
    final url = Uri.parse('http://192.168.0.11/repEatApi/camera_workout_screen.php');

    final duration = _lastRepTime != null
        ? _repCount * 2 // Approx 2 seconds per rep
        : 0;

    double accuracyScore = 0.9;
    if (widget.exercise == 'Dumbbell Curls' && _poses.isNotEmpty) {
      accuracyScore = _isHoldingDumbbell(_poses.first) ? 0.95 : 0.6;
    }

    final data = {
      'user_id': widget.userId,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'category': widget.category,
      'exercise_name': widget.exercise,
      'detected_reps': _repCount,
      'duration_seconds': duration,
      'accuracy_score': accuracyScore,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));

      final result = jsonDecode(response.body);
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Workout saved successfully!')),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to save workout');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error saving workout: $e')),
        );
      }
      debugPrint('Error saving workout: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exercise} Rep Counter'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveCameraWorkout,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _cameraController!.value.previewSize!.height,
                height: _cameraController!.value.previewSize!.width,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: PosePainter(
                _poses,
                imageSize: _imageSize!,
                isFrontCamera: _isFrontCamera,
              ),
            ),
          ),
          if (_showDumbbellWarning)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withOpacity(0.7),
                child: const Text(
                  'Hold dumbbells properly to count reps',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Text(
                    '$_repCount / $_preferredReps',
                    style: const TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Set $_currentSet / $_preferredSets',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 5,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {
          _repCount = 0;
          _currentSet = 1;
          _lastRepTime = null;
        }),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}