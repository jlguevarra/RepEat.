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

// First, modify the constructor to accept planDay
class CameraWorkoutScreen extends StatefulWidget {
  final int userId;
  final String exercise;
  final int reps;
  final int sets;
  final String planDay; // NEW: Add planDay parameter
  final Function(bool, String)? onExerciseCompleted;

  const CameraWorkoutScreen({
    super.key,
    required this.userId,
    required this.exercise,
    required this.reps,
    required this.sets,
    required this.planDay, // NEW: Required planDay
    this.onExerciseCompleted,
  });

  @override
  State<CameraWorkoutScreen> createState() => _CameraWorkoutScreenState();
}

class _CameraWorkoutScreenState extends State<CameraWorkoutScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  int _repCount = 0;
  int _currentSet = 1;
  bool _workoutCompleted = false;
  int _durationSeconds = 0;
  int _restSeconds = 0;
  Timer? _workoutTimer;
  Timer? _restTimer;
  bool _showSuccessAnimation = false;
  bool _personDetected = false;
  DateTime? _lastRepTime;

  late PoseDetector _poseDetector;
  bool _isDetecting = false;

  bool _isRestPeriod = false;
  String _formStatus = "Position yourself in frame";
  Color _formStatusColor = Colors.white;

  bool _isAtTop = false;
  bool _isAtBottom = true;

  bool get _isDumbbellExercise => widget.exercise.toLowerCase().contains('dumbbell');

  @override
  void initState() {
    super.initState();
    _initializeDetectors();
    _initializeCamera();
    _showExerciseInstructions();
  }

  void _initializeDetectors() {
    final poseOptions = PoseDetectorOptions();
    _poseDetector = PoseDetector(options: poseOptions);
  }

  Future<void> _showExerciseInstructions() async {
    // This dialog remains the same
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.exercise),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isDumbbellExercise ? Icons.fitness_center : Icons.directions_run,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.sets} sets × ${widget.reps} reps',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Position yourself clearly in the frame. Reps will count when proper form is detected.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('START', style: TextStyle(fontSize: 18)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startWorkoutTimer();
        _startPoseDetection();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _startWorkoutTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_workoutCompleted && !_isRestPeriod && mounted) {
        setState(() => _durationSeconds++);
      }
    });
  }

  void _startRestTimer() {
    _restSeconds = 60; // 1 minute rest period
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0 && mounted) {
        setState(() => _restSeconds--);
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isRestPeriod = false;
          });
        }
      }
    });
  }

  void _startPoseDetection() {
    if (_cameraController == null) return;
    _cameraController!.startImageStream((CameraImage image) {
      if (_isDetecting || _workoutCompleted || _isRestPeriod) return;
      if (!mounted) return;

      _isDetecting = true;
      _processCameraImage(image);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        if (mounted) {
          _personDetected = true;
          _analyzePose(poses.first);
        }
      } else {
        if (mounted) {
          setState(() {
            _personDetected = false;
            _formStatus = "No person detected";
            _formStatusColor = Colors.orange;
          });
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      if (mounted) {
        _isDetecting = false;
      }
    }
  }

  // FIXED: This is the corrected and simplified image conversion method.
  InputImage? _convertCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation rotation;
    switch (sensorOrientation) {
      case 0:
        rotation = InputImageRotation.rotation0deg;
        break;
      case 90:
        rotation = InputImageRotation.rotation90deg;
        break;
      case 180:
        rotation = InputImageRotation.rotation180deg;
        break;
      case 270:
        rotation = InputImageRotation.rotation270deg;
        break;
      default:
        rotation = InputImageRotation.rotation0deg;
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    // Combine bytes from all planes
    final allBytes = image.planes.fold<List<int>>(
      <int>[],
          (previousValue, element) => previousValue..addAll(element.bytes),
    );
    final bytes = Uint8List.fromList(allBytes);

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  void _analyzePose(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // Default to bicep curl analysis for now
    _analyzeDumbbellExercise(leftShoulder, leftElbow, leftWrist, rightShoulder, rightElbow, rightWrist);
  }

  void _analyzeDumbbellExercise(
      PoseLandmark? leftShoulder,
      PoseLandmark? leftElbow,
      PoseLandmark? leftWrist,
      PoseLandmark? rightShoulder,
      PoseLandmark? rightElbow,
      PoseLandmark? rightWrist) {
    // Prioritize left arm if visible, otherwise use right
    if (leftElbow != null && leftShoulder != null && leftWrist != null) {
      final angle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      _analyzeBicepCurl(angle);
    } else if (rightElbow != null && rightShoulder != null && rightWrist != null) {
      final angle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
      _analyzeBicepCurl(angle);
    }
  }

  void _analyzeBicepCurl(double elbowAngle) {
    if (elbowAngle < 60 && !_isAtTop) {
      _isAtTop = true;
      _isAtBottom = false;
    } else if (elbowAngle > 150 && _isAtTop && !_isAtBottom) {
      _isAtBottom = true;
      _isAtTop = false;
      _countRep();
    }
  }

  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x);
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  void _countRep() {
    if (_workoutCompleted || _isRestPeriod || !_personDetected) return;

    final now = DateTime.now();
    if (_lastRepTime != null && now.difference(_lastRepTime!).inMilliseconds < 800) {
      return;
    }

    if (mounted) {
      setState(() {
        _repCount++;
        _lastRepTime = now;
        _formStatus = "REP COUNTED!";
        _formStatusColor = Colors.green;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _formStatus == "REP COUNTED!") {
          setState(() => _formStatus = "Keep Going!");
        }
      });

      _checkSetCompletion();
    }
  }

  void _checkSetCompletion() {
    if (_repCount >= widget.reps) {
      if (_currentSet >= widget.sets) {
        _completeWorkout();
      } else {
        _startRestPeriod();
      }
    }
  }

  void _startRestPeriod() {
    setState(() {
      _isRestPeriod = true;
      _currentSet++;
      _repCount = 0;
      _isAtTop = false;
      _isAtBottom = true;
      _formStatus = "Set completed! Rest period";
      _formStatusColor = Colors.yellow;
    });
    _startRestTimer();
  }

  void _completeWorkout() {
    if (mounted) {
      setState(() {
        _workoutCompleted = true;
        _showSuccessAnimation = true;
      });
    }

    _workoutTimer?.cancel();
    _restTimer?.cancel();

    if (widget.onExerciseCompleted != null) {
      widget.onExerciseCompleted!(true, widget.exercise);
    }

    _saveWorkoutData();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _saveWorkoutData() async {
    try {
      await http.post(
        Uri.parse('http://192.168.100.78/repEatApi/save_workout_session.php'),
        headers: {'Content-Type': 'application/json'}, // Add headers
        body: jsonEncode({
          'user_id': widget.userId,
          'exercise': widget.exercise,
          'completed_reps': widget.reps * widget.sets,
          'target_reps': widget.reps * widget.sets,
          'duration_seconds': _durationSeconds,
          'date': DateTime.now().toIso8601String(),
          'plan_day': widget.planDay, // NEW: Include plan_day
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Could not save workout data: $e");
    }
  }
  void _restartWorkout() {
    setState(() {
      _repCount = 0;
      _currentSet = 1;
      _workoutCompleted = false;
      _showSuccessAnimation = false;
      _durationSeconds = 0;
      _restSeconds = 0;
      _isRestPeriod = false;
      _isAtTop = false;
      _isAtBottom = true;
      _formStatus = "Workout restarted!";
      _formStatusColor = Colors.white;
    });

    _startWorkoutTimer();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream().catchError((e) {
      debugPrint("Error stopping image stream: $e");
    });
    _cameraController?.dispose();
    _poseDetector.close();
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise),
        backgroundColor: Colors.deepPurple,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _restartWorkout)],
      ),
      body: _isInitialized && _cameraController != null && _cameraController!.value.isInitialized
          ? Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          _buildUIOverlays(),
          if (_showSuccessAnimation)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 100),
                    SizedBox(height: 20),
                    Text('Workout Completed!', style: TextStyle(color: Colors.white, fontSize: 24)),
                  ],
                ),
              ),
            ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildUIOverlays() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text('${_durationSeconds ~/ 60}:${(_durationSeconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(width: 20),
                const Icon(Icons.fitness_center, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text('Set $_currentSet/${widget.sets}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                if (_isRestPeriod)
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text('Rest: $_restSeconds s', style: const TextStyle(color: Colors.yellow, fontSize: 16)),
                  ),
              ],
            ),
          ),
          if (_formStatus.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Text(_formStatus, style: TextStyle(color: _formStatusColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: Text('$_repCount / ${widget.reps}', style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                if (_isRestPeriod && _restSeconds == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isRestPeriod = false),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('START NEXT SET'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}