import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'pose_painter.dart';

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
  double? _prevWristX;
  bool _dumbbellsReady = false;

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _fetchUserGoals().then((_) => _initializeCamera());
  }

  Future<void> _fetchUserGoals() async {
    final url = Uri.parse('http://192.168.100.78/repEatApi/get_user_onboarding.php');
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
        setState(() => _poses = poses);
        _countReps(poses);
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

  void _countReps(List<Pose> poses) {
    if (!_dumbbellsReady || poses.isEmpty || _currentSet > _preferredSets) return;

    final pose = poses.first;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

    if (leftShoulder == null || leftElbow == null || leftWrist == null) return;

    final elbowToWristY = (leftElbow.y - leftWrist.y);
    final wristX = leftWrist.x;
    final wristStabilityThreshold = 20.0;
    _prevWristX ??= wristX;
    final isStableWrist = (wristX - _prevWristX!).abs() < wristStabilityThreshold;
    final distanceToShoulder = (leftWrist.y - leftShoulder.y).abs();
    final isCurlingUp = elbowToWristY > 50;
    final isCloseToShoulder = distanceToShoulder < 80;

    if (isCurlingUp && isStableWrist && isCloseToShoulder) {
      if (!_isDownPosition) {
        _isDownPosition = true;
      }
    }

    if (_isDownPosition && elbowToWristY < 20) {
      setState(() {
        _repCount++;
        _isDownPosition = false;
      });

      if (_repCount >= _preferredReps) {
        setState(() {
          _currentSet++;
          _repCount = 0;
        });

        if (_currentSet > _preferredSets) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Workout Complete!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Set $_currentSet started')),
          );
        }
      }
    }

    _prevWristX = wristX;
  }

  Future<void> saveCameraWorkout() async {
    final url = Uri.parse('http://192.168.100.78/repEatApi/camera_workout_screen.php');
    final data = {
      'user_id': widget.userId,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'category': widget.category,
      'exercise_name': widget.exercise,
      'detected_reps': _repCount,
      'duration_seconds': 0,
      'accuracy_score': 0,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final result = jsonDecode(response.body);
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Workout saved')),
          );
          setState(() {
            _repCount = 0;
            _currentSet = 1;
          });
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
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
        title: const Text('Workout Rep Counter'),
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
          Positioned(
            bottom: 100,
            left: 10,
            child: Row(
              children: [
                const Text('✔ Dumbbells Ready', style: TextStyle(color: Colors.white)),
                Switch(
                  value: _dumbbellsReady,
                  onChanged: (val) => setState(() => _dumbbellsReady = val),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
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
                    ),
                  ),
                  Text(
                    'Set $_currentSet / $_preferredSets',
                    style: const TextStyle(fontSize: 20, color: Colors.white),
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
        }),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
