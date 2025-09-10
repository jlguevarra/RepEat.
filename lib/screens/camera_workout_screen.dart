import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';


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
  int _motionDirection = 0; // 0: neutral, 1: up, -1: down
  bool _isRestPeriod = false;
  double _motionIntensity = 0.0;
  String _formFeedback = 'Get ready to start';
  int _previousMotionDirection = 0;
  bool _isModelLoaded = false;

  // ML Kit Pose Detector
  PoseDetector? _poseDetector;
  List<Pose> _poses = [];
  double _imageHeight = 0;
  double _imageWidth = 0;

  @override
  void initState() {
    super.initState();
    _initializePoseDetector();
    _initializeCamera();
    _showExerciseInstructions();
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
                Icons.fitness_center,
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
                'Position yourself clearly in frame. Make sure your arms and shoulders are visible.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getExerciseInstructions(),
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
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

  String _getExerciseInstructions() {
    if (widget.exercise.toLowerCase().contains('curl')) {
      return 'Perform bicep curls with full range of motion';
    } else if (widget.exercise.toLowerCase().contains('press')) {
      return 'Perform shoulder presses with full extension';
    } else if (widget.exercise.toLowerCase().contains('raise')) {
      return 'Perform lateral raises with controlled movement';
    } else {
      return 'Perform the exercise with clear arm movements';
    }
  }

  Future<void> _initializePoseDetector() async {
    try {
      // Initialize Pose Detector with default options
      _poseDetector = PoseDetector(options: PoseDetectorOptions());

      setState(() {
        _isModelLoaded = true;
      });
    } catch (e) {
      debugPrint('Pose detector initialization error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pose detector error: $e')),
      );
    }
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
      if (!_isModelLoaded || _workoutCompleted || _isRestPeriod) return;

      // Process image with ML Kit
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    if (_poseDetector == null) return;

    // Get image dimensions
    if (_imageHeight == 0 || _imageWidth == 0) {
      _imageHeight = image.height.toDouble();
      _imageWidth = image.width.toDouble();
    }

    try {
      // Convert CameraImage to InputImage using the new API
      final inputImage = _inputImageFromCameraImage(image);

      // Detect poses
      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isNotEmpty) {
        setState(() {
          _poses = poses;
        });

        _analyzePose(poses.first);
      } else {
        setState(() {
          _formFeedback = "Please position yourself in frame";
        });
      }
    } catch (e) {
      debugPrint('Pose detection error: $e');
    }
  }

  InputImage _inputImageFromCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final camera = _cameraController!.description;
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: InputImageFormat.nv21, // Most common format for Android
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation _getImageRotation() {
    // For front camera, rotation is 90 degrees for most devices
    return InputImageRotation.rotation90deg;
  }

  Uint8List _getBytesFromCameraImage(CameraImage image) {
    // Calculate total size
    final int totalBytes = image.planes.fold(0, (sum, plane) => sum + plane.bytes.length);

    // Create a buffer
    final Uint8List bytes = Uint8List(totalBytes);
    int offset = 0;

    // Copy bytes from each plane
    for (final Plane plane in image.planes) {
      bytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }

    return bytes;
  }

  void _analyzePose(Pose pose) {
    // Get key points for the exercise
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (leftWrist == null || rightWrist == null ||
        leftElbow == null || rightElbow == null ||
        leftShoulder == null || rightShoulder == null) {
      setState(() {
        _formFeedback = "Please position yourself in frame";
      });
      return;
    }

    // Exercise-specific form analysis
    if (widget.exercise.toLowerCase().contains('curl')) {
      _checkBicepCurlForm(leftWrist, rightWrist, leftElbow, rightElbow, leftShoulder, rightShoulder);
    } else if (widget.exercise.toLowerCase().contains('press')) {
      _checkShoulderPressForm(leftWrist, rightWrist, leftElbow, rightElbow, leftShoulder, rightShoulder);
    } else if (widget.exercise.toLowerCase().contains('raise')) {
      _checkLateralRaiseForm(leftWrist, rightWrist, leftElbow, rightElbow, leftShoulder, rightShoulder);
    } else {
      _checkGeneralForm(leftWrist, rightWrist, leftElbow, rightElbow, leftShoulder, rightShoulder);
    }
  }

  void _checkBicepCurlForm(
      PoseLandmark leftWrist,
      PoseLandmark rightWrist,
      PoseLandmark leftElbow,
      PoseLandmark rightElbow,
      PoseLandmark leftShoulder,
      PoseLandmark rightShoulder,
      ) {
    // Calculate angles for form analysis
    final double leftArmAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    final double rightArmAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);

    // Determine motion direction based on arm angle
    setState(() {
      if (leftArmAngle < 45 && rightArmAngle < 45) {
        _motionDirection = 1; // Top position (arms fully flexed)
        _motionIntensity = 0.9;
      } else if (leftArmAngle > 135 && rightArmAngle > 135) {
        _motionDirection = -1; // Bottom position (arms extended)
        _motionIntensity = 0.9;
      } else {
        _motionDirection = 0; // Intermediate position
        _motionIntensity = (leftArmAngle + rightArmAngle) / 360;
      }
    });

    // Check for proper form
    final bool isGoodForm = (leftArmAngle > 30 && leftArmAngle < 160) &&
        (rightArmAngle > 30 && rightArmAngle < 160);

    if (isGoodForm) {
      _checkForRepCompletion();
      setState(() {
        _formFeedback = "Good form!";
      });
    } else {
      setState(() {
        _formFeedback = "Extend your arms fully";
      });
    }
  }

  void _checkShoulderPressForm(
      PoseLandmark leftWrist,
      PoseLandmark rightWrist,
      PoseLandmark leftElbow,
      PoseLandmark rightElbow,
      PoseLandmark leftShoulder,
      PoseLandmark rightShoulder,
      ) {
    // Calculate vertical positions
    final double leftExtension = (leftShoulder.y - leftWrist.y).abs();
    final double rightExtension = (rightShoulder.y - rightWrist.y).abs();

    // Determine motion direction
    setState(() {
      if (leftExtension > 0.3 && rightExtension > 0.3) {
        _motionDirection = 1; // Top position (arms extended)
        _motionIntensity = 0.9;
      } else if (leftExtension < 0.1 && rightExtension < 0.1) {
        _motionDirection = -1; // Bottom position (arms bent)
        _motionIntensity = 0.9;
      } else {
        _motionDirection = 0; // Intermediate position
        _motionIntensity = (leftExtension + rightExtension) / 0.6;
      }
    });

    // Count reps with good form
    _checkForRepCompletion();
    setState(() {
      _formFeedback = "Good form!";
    });
  }

  void _checkLateralRaiseForm(
      PoseLandmark leftWrist,
      PoseLandmark rightWrist,
      PoseLandmark leftElbow,
      PoseLandmark rightElbow,
      PoseLandmark leftShoulder,
      PoseLandmark rightShoulder,
      ) {
    // Calculate horizontal extension
    final double leftRaise = (leftShoulder.x - leftWrist.x).abs();
    final double rightRaise = (rightShoulder.x - rightWrist.x).abs();

    // Determine motion direction
    setState(() {
      if (leftRaise > 0.2 && rightRaise > 0.2) {
        _motionDirection = 1; // Top position (arms raised)
        _motionIntensity = 0.9;
      } else if (leftRaise < 0.05 && rightRaise < 0.05) {
        _motionDirection = -1; // Bottom position (arms down)
        _motionIntensity = 0.9;
      } else {
        _motionDirection = 0; // Intermediate position
        _motionIntensity = (leftRaise + rightRaise) / 0.4;
      }
    });

    // Count reps with good form
    _checkForRepCompletion();
    setState(() {
      _formFeedback = "Good form!";
    });
  }

  void _checkGeneralForm(
      PoseLandmark leftWrist,
      PoseLandmark rightWrist,
      PoseLandmark leftElbow,
      PoseLandmark rightElbow,
      PoseLandmark leftShoulder,
      PoseLandmark rightShoulder,
      ) {
    // General motion detection
    final double motionIntensity = (leftWrist.y - rightWrist.y).abs();

    setState(() {
      _motionIntensity = motionIntensity.clamp(0.0, 1.0);
      _motionDirection = motionIntensity > 0.3 ? (_motionDirection == 1 ? -1 : 1) : 0;
    });

    // Count reps
    _checkForRepCompletion();
    setState(() {
      _formFeedback = "Motion detected";
    });
  }

  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    // Calculate angle at point b between points a and c
    final double abX = a.x - b.x;
    final double abY = a.y - b.y;
    final double cbX = c.x - b.x;
    final double cbY = c.y - b.y;

    final double dot = (abX * cbX + abY * cbY);
    final double cross = (abX * cbY - abY * cbX);

    final double alpha = math.atan2(cross, dot);
    return (alpha * 180 / math.pi).abs();
  }

  void _checkForRepCompletion() {
    final now = DateTime.now();

    // Prevent double counting
    if (_lastRepTime != null && now.difference(_lastRepTime!).inMilliseconds < 1000) {
      return;
    }

    // Count rep when completing full range of motion (from top to bottom)
    if (_motionDirection == -1 && _previousMotionDirection == 1 && _motionIntensity > 0.5) {
      _countRep();
    }

    setState(() {
      _previousMotionDirection = _motionDirection;
    });
  }

  void _countRep() {
    if (_workoutCompleted || _isRestPeriod) return;

    setState(() {
      _repCount++;
      _lastRepTime = DateTime.now();
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
      _formFeedback = 'Get ready to start';
    });

    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _startWorkoutTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout restarted!')),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _poseDetector?.close();
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
              Text('Initializing camera and pose detection...'),
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
          // Camera preview
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          // Pose landmarks overlay
          if (_poses.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: PoseLandmarkPainter(_poses.first, _imageHeight, _imageWidth),
              ),
            ),

          // Workout info overlay
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

          // Rep counter
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
                      _formFeedback,
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

  Color _getStatusColor() {
    if (_formFeedback.contains("position yourself")) {
      return Colors.orange;
    } else if (_formFeedback.contains("Good form")) {
      return Colors.green;
    } else {
      return Colors.white70;
    }
  }
}

// Custom painter to draw pose landmarks
class PoseLandmarkPainter extends CustomPainter {
  final Pose pose;
  final double imageHeight;
  final double imageWidth;

  PoseLandmarkPainter(this.pose, this.imageHeight, this.imageWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 8.0
      ..style = PaintingStyle.fill;

    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;

    // Draw connections between landmarks
    _drawConnection(canvas, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, scaleX, scaleY, paint);
    _drawConnection(canvas, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, scaleX, scaleY, paint);
    _drawConnection(canvas, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, scaleX, scaleY, paint);
    _drawConnection(canvas, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, scaleX, scaleY, paint);
    _drawConnection(canvas, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, scaleX, scaleY, paint);

    // Draw key points
    for (final landmark in pose.landmarks.values) {
      final double x = landmark.x * scaleX;
      final double y = landmark.y * scaleY;
      canvas.drawCircle(Offset(x, y), 6, pointPaint);
    }
  }

  void _drawConnection(Canvas canvas, PoseLandmarkType startType, PoseLandmarkType endType,
      double scaleX, double scaleY, Paint paint) {
    final startLandmark = pose.landmarks[startType];
    final endLandmark = pose.landmarks[endType];

    if (startLandmark != null && endLandmark != null) {
      final double startX = startLandmark.x * scaleX;
      final double startY = startLandmark.y * scaleY;
      final double endX = endLandmark.x * scaleX;
      final double endY = endLandmark.y * scaleY;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}