import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

class CameraWorkoutScreen extends StatefulWidget {
  final int userId;
  final String exercise;
  final int reps;
  final int sets;
  final Function(bool)? onExerciseCompleted;

  const CameraWorkoutScreen({
    super.key,
    required this.userId,
    required this.exercise,
    required this.reps,
    required this.sets,
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
  DateTime? _lastRepTime;

  // ML Kit detectors
  late PoseDetector _poseDetector;
  bool _isDetecting = false;

  // Exercise state variables
  double _motionIntensity = 0.0;
  bool _isEquipmentDetected = true; // 🔥 Always true now
  bool _isRestPeriod = false;
  String _formStatus = "Position yourself in frame";
  Color _formStatusColor = Colors.white;

  // Pose analysis variables
  double _lastElbowAngle = 0;
  bool _isAtTop = false;
  bool _isAtBottom = true;
  int _motionDirection = 0; // 0: neutral, 1: up, -1: down

  // Exercise classification
  bool get _isDumbbellExercise => widget.exercise.toLowerCase().contains('dumbbell');
  bool get _isBodyweightExercise => !_isDumbbellExercise;

  @override
  void initState() {
    super.initState();
    _initializeDetectors();
    _initializeCamera();
    _showExerciseInstructions();
  }

  void _initializeDetectors() {
    // Initialize pose detector only
    final poseOptions = PoseDetectorOptions();
    _poseDetector = PoseDetector(options: poseOptions);
  }

  Future<void> _showExerciseInstructions() async {
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
              Text(
                _isDumbbellExercise
                    ? 'Reps will only count when proper form is detected.'
                    : 'Position yourself clearly in frame. The system will detect your body movements.',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
      return;
    }

    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(camera, ResolutionPreset.medium);
      await _cameraController!.initialize();

      setState(() {
        _isInitialized = true;
      });

      _startWorkoutTimer();
      _startPoseDetection();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_workoutCompleted && !_isRestPeriod) {
        setState(() => _durationSeconds++);
      }
    });
  }

  void _startRestTimer() {
    _restSeconds = 60; // 1 minute rest period
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0) {
        setState(() => _restSeconds--);
      } else {
        timer.cancel();
        setState(() {
          _isRestPeriod = false;
        });
      }
    });
  }

  void _startPoseDetection() {
    _cameraController!.startImageStream((CameraImage image) {
      if (_isDetecting || _workoutCompleted || _isRestPeriod) return;

      _isDetecting = true;
      _processCameraImage(image);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final inputImage = _convertCameraImage(image);

      // Detect poses
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        final pose = poses.first;
        _analyzePose(pose);
      } else {
        setState(() {
          _formStatus = "No person detected";
          _formStatusColor = Colors.orange;
        });
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage _convertCameraImage(CameraImage image) {
    final allBytes = image.planes.fold<List<int>>([], (previous, plane) {
      previous.addAll(plane.bytes);
      return previous;
    });

    final bytes = Uint8List.fromList(allBytes);

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: InputImageRotation.rotation0deg,
      format: InputImageFormat.nv21,
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

    if (_isDumbbellExercise) {
      _analyzeDumbbellExercise(
        pose,
        leftShoulder,
        leftElbow,
        leftWrist,
        rightShoulder,
        rightElbow,
        rightWrist,
      );
    } else {
      _analyzeBodyweightExercise(
        pose,
        leftShoulder,
        leftElbow,
        leftWrist,
        rightShoulder,
        rightElbow,
        rightWrist,
      );
    }
  }

  void _analyzeDumbbellExercise(
      Pose pose,
      PoseLandmark? leftShoulder,
      PoseLandmark? leftElbow,
      PoseLandmark? leftWrist,
      PoseLandmark? rightShoulder,
      PoseLandmark? rightElbow,
      PoseLandmark? rightWrist,
      ) {
    if (leftElbow != null && leftShoulder != null && leftWrist != null) {
      final angle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      _analyzeBicepCurl(angle);
    } else if (rightElbow != null && rightShoulder != null && rightWrist != null) {
      final angle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
      _analyzeBicepCurl(angle);
    }
  }

  void _analyzeBicepCurl(double elbowAngle) {
    setState(() {
      _motionIntensity = (elbowAngle - 90).abs() / 90;

      if (elbowAngle < _lastElbowAngle) {
        _motionDirection = 1;
        _formStatus = "Lifting up ↑";
        _formStatusColor = Colors.blue;
      } else if (elbowAngle > _lastElbowAngle) {
        _motionDirection = -1;
        _formStatus = "Lowering down ↓";
        _formStatusColor = Colors.green;
      }

      if (elbowAngle < 50 && !_isAtTop) {
        _isAtTop = true;
        _isAtBottom = false;
      } else if (elbowAngle > 160 && _isAtTop && !_isAtBottom) {
        _isAtBottom = true;
        _isAtTop = false;
        _countRep();
      }

      _lastElbowAngle = elbowAngle;
    });
  }

  void _analyzeBodyweightExercise(
      Pose pose,
      PoseLandmark? leftShoulder,
      PoseLandmark? leftElbow,
      PoseLandmark? leftWrist,
      PoseLandmark? rightShoulder,
      PoseLandmark? rightElbow,
      PoseLandmark? rightWrist,
      ) {
    setState(() {
      _formStatus = "Body motion detected";
      _formStatusColor = Colors.white;
      _motionIntensity = 0.5;
    });
  }

  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final baX = a.x - b.x;
    final baY = a.y - b.y;
    final bcX = c.x - b.x;
    final bcY = c.y - b.y;

    final dotProduct = baX * bcX + baY * bcY;
    final magBA = math.sqrt(baX * baX + baY * baY);
    final magBC = math.sqrt(bcX * bcX + bcY * bcY);

    final angle = math.acos(dotProduct / (magBA * magBC));
    return angle * 180 / math.pi;
  }

  void _countRep() {
    if (_workoutCompleted || _isRestPeriod || !_isEquipmentDetected) return;

    final now = DateTime.now();
    if (_lastRepTime != null && now.difference(_lastRepTime!).inMilliseconds < 800) {
      return;
    }

    setState(() {
      _repCount++;
      _lastRepTime = now;
      _formStatus = "REP COUNTED!";
      _formStatusColor = Colors.green;
    });

    _showRepFeedback();
    _checkSetCompletion();
  }

  void _showRepFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('REP $_repCount!', style: const TextStyle(fontWeight: FontWeight.bold)),
        duration: const Duration(milliseconds: 500),
        backgroundColor: Colors.green,
      ),
    );
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
    });

    _startRestTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Set ${_currentSet - 1} completed! Rest time: 60 seconds'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _startNextSet() {
    if (_restSeconds > 0) return;

    setState(() {
      _isRestPeriod = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🏋️ Set $_currentSet started!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _completeWorkout() {
    setState(() {
      _workoutCompleted = true;
      _showSuccessAnimation = true;
    });

    _workoutTimer?.cancel();
    _restTimer?.cancel();

    if (widget.onExerciseCompleted != null) {
      widget.onExerciseCompleted!(true);
    }

    _saveWorkoutData().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSuccessAnimation = false);
      });
    });
  }

  Future<void> _saveWorkoutData() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.78/repEatApi/save_workout_session.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'exercise': widget.exercise,
          'completed_reps': (widget.sets - 1) * widget.reps + _repCount,
          'target_reps': widget.reps * widget.sets,
          'duration_seconds': _durationSeconds,
          'date': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 5));

      final result = jsonDecode(response.body);
      if (result['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Workout saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout completed!')),
        );
      }
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
      _motionDirection = 0;
      _motionIntensity = 0.0;
      _isRestPeriod = false;
      _isAtTop = false;
      _isAtBottom = true;
    });

    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _startWorkoutTimer();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera and motion detection...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exercise} - Smart Rep Counting'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartWorkout,
            tooltip: 'Restart Workout',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black54,
              child: Column(
                children: [
                  Text(
                    widget.exercise,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set $_currentSet/${widget.sets} • ${_durationSeconds ~/ 60}:${(_durationSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  if (_isRestPeriod)
                    Text(
                      'Rest: $_restSeconds seconds',
                      style: const TextStyle(color: Colors.yellow, fontSize: 16),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formStatus,
                  style: TextStyle(
                    color: _formStatusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          if (_isDumbbellExercise)
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isEquipmentDetected ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isEquipmentDetected ? '✅ DUMBBELL DETECTED (Bypassed)' : '❌ DUMBBELL NOT DETECTED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_repCount / ${widget.reps}',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getMotionStatusText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
  
            // Start Next Set Button (during rest period)
            if (_isRestPeriod && _restSeconds == 0)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton(
                    onPressed: _startNextSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: const Text(
                      'START NEXT SET',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
  
            // Success animation
            if (_showSuccessAnimation)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 100,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Workout Completed!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
  
    String _getMotionStatusText() {
      if (_isDumbbellExercise && !_isEquipmentDetected) {
        return 'SHOW DUMBBELL TO CAMERA';
      } else if (_motionIntensity < 0.3) {
        return 'READY FOR MOTION';
      } else if (_motionDirection == 1) {
        return 'LIFTING UP ↑';
      } else if (_motionDirection == -1) {
        return 'LOWERING DOWN ↓';
      } else {
        return 'MOTION DETECTED';
      }
    }
  
    Color _getStatusColor() {
      if (_isDumbbellExercise && !_isEquipmentDetected) {
        return Colors.red;
      } else if (_motionIntensity < 0.3) {
        return Colors.white70;
      } else {
        return Colors.green;
      }
    }
  }