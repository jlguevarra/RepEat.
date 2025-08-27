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
import 'exercise_guide_data.dart';

class CameraWorkoutScreen extends StatefulWidget {
  final int userId;
  final String category;
  final String exercise;
  final Function(bool) onExerciseCompleted;

  const CameraWorkoutScreen({
    super.key,
    required this.userId,
    required this.category,
    required this.exercise,
    required this.onExerciseCompleted,
  });

  @override
  State<CameraWorkoutScreen> createState() => _CameraWorkoutScreenState();
}

class _CameraWorkoutScreenState extends State<CameraWorkoutScreen> {
  CameraController? _cameraController;
  late PoseDetector _poseDetector;
  bool _isBusy = false;
  int _repCount = 0;
  int _preferredReps = 10; // Default values
  int _preferredSets = 3;  // Default values
  int _currentSet = 1;
  bool _isDownPosition = false;
  Size? _imageSize;
  List<Pose> _poses = [];
  bool _isFrontCamera = true;
  bool _isInitialized = false;
  bool _showDumbbellWarning = false;
  DateTime? _lastRepTime;
  bool _workoutCompleted = false;
  double _accuracyScore = 0.0;
  int _durationSeconds = 0;
  Timer? _workoutTimer;
  bool _showSuccessAnimation = false;

  // Exercise-specific detection functions
  final Map<String, Function> _exerciseDetectors = {
    'Hammer Curls': isHammerCurlRep,
    'Concentration Curls': isConcentrationCurlRep,
    'Dumbbell Curls': isDumbbellCurlRep,
    'Dumbbell Bench Press': _detectBenchPress,
    'Dumbbell Shoulder Press': _detectShoulderPress,
    'Dumbbell Rows': _detectRows,
    'Dumbbell Squats': _detectSquats,
    'Dumbbell Lunges': _detectLunges,
    'Push-ups': _detectPushups,
  };

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _showExerciseGuide().then((_) => _fetchUserGoals().then((_) => _initializeCamera()));
  }

  Future<void> _showExerciseGuide() async {
    final guide = exerciseGuides[widget.exercise];
    if (guide == null) {
      debugPrint('No guide found for exercise: ${widget.exercise}');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(guide.name),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGuideImage(guide.imageAsset),
                  const SizedBox(height: 12),
                  Text(
                    guide.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Target: $_preferredSets sets of $_preferredReps reps',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
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
    } catch (e) {
      debugPrint('Error showing guide: $e');
    }
  }

  Widget _buildGuideImage(String assetPath) {
    try {
      return Image.asset(
        assetPath,
        height: 150,
        errorBuilder: (ctx, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } catch (e) {
      return _buildErrorPlaceholder();
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      height: 150,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.error_outline, color: Colors.red),
      ),
    );
  }

  Future<void> _fetchUserGoals() async {
    final url = Uri.parse('http://localhost/repEatApi/get_user_onboarding.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.userId}),
      ).timeout(const Duration(seconds: 5));

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
      _startWorkoutTimer();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_workoutCompleted) {
        setState(() {
          _durationSeconds++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || !mounted || _workoutCompleted) return;
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
    final detector = _exerciseDetectors[widget.exercise];

    if (detector != null) {
      // For exercises with specific detection functions
      if (widget.exercise == 'Hammer Curls') {
        _isDownPosition = isHammerCurlRep(
          pose: pose,
          isDownPosition: _isDownPosition,
          onRepDetected: _onRepDetected,
        );
      } else if (widget.exercise == 'Concentration Curls') {
        _isDownPosition = isConcentrationCurlRep(
          pose: pose,
          isDownPosition: _isDownPosition,
          onRepDetected: _onRepDetected,
        );
      } else if (widget.exercise == 'Dumbbell Curls') {
        _isDownPosition = isDumbbellCurlRep(
          pose: pose,
          isDownPosition: _isDownPosition,
          onRepDetected: _onRepDetected,
        );
      }
    } else {
      // Generic detection for other exercises
      _genericRepDetection(pose);
    }
  }

  void _genericRepDetection(Pose pose) {
    // This is a simple generic rep counter that works for many exercises
    // by detecting significant vertical movement

    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (leftWrist != null && rightWrist != null &&
        leftShoulder != null && rightShoulder != null) {

      // Calculate average wrist height relative to shoulders
      final avgWristY = (leftWrist.y + rightWrist.y) / 2;
      final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
      final relativeHeight = (avgWristY - avgShoulderY).abs();

      // Simple threshold-based rep detection
      if (relativeHeight < 0.1 && !_isDownPosition) {
        _isDownPosition = true;
      } else if (relativeHeight > 0.3 && _isDownPosition) {
        _onRepDetected();
        _isDownPosition = false;
      }
    }
  }

  // Placeholder functions for other exercises
  static bool _detectBenchPress({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    // Implement bench press detection logic
    return isDownPosition;
  }

  static bool _detectShoulderPress({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    // Implement shoulder press detection logic
    return isDownPosition;
  }

  static bool _detectRows({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    // Implement row detection logic
    return isDownPosition;
  }

  static bool _detectSquats({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    // Implement squat detection logic
    return isDownPosition;
  }

  static bool _detectLunges({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    // Implement lunge detection logic
    return isDownPosition;
  }

  static bool _detectPushups({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    // Implement pushup detection logic
    return isDownPosition;
  }

  void _onRepDetected() {
    final now = DateTime.now();
    if (_lastRepTime != null && now.difference(_lastRepTime!).inMilliseconds < 500) {
      return; // Debounce to prevent multiple detections for the same rep
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
        _completeWorkout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Set $_currentSet started')),
        );
      }
    }
  }

  void _completeWorkout() {
    setState(() {
      _workoutCompleted = true;
      _showSuccessAnimation = true;
    });

    // Calculate accuracy score based on performance
    _accuracyScore = _calculateAccuracyScore();

    // Stop the workout timer
    _workoutTimer?.cancel();

    // Save workout data
    saveCameraWorkout().then((_) {
      // Notify parent widget of completion
      widget.onExerciseCompleted(true);

      // Hide success animation after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showSuccessAnimation = false;
          });
        }
      });
    });
  }

  double _calculateAccuracyScore() {
    // Simple accuracy calculation based on reps completed vs expected
    // In a real app, you'd want more sophisticated form analysis
    final expectedReps = _preferredReps * _preferredSets;
    final completedReps = (_preferredSets - 1) * _preferredReps + _repCount;

    double baseScore = completedReps / expectedReps;

    // Adjust score based on form warnings (if any)
    if (_showDumbbellWarning) {
      baseScore *= 0.8; // Reduce score for form issues
    }

    return baseScore.clamp(0.0, 1.0);
  }

  Future<void> saveCameraWorkout() async {
    final url = Uri.parse('http://localhost/repEatApi/camera_workout_screen.php');

    final data = {
      'user_id': widget.userId,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'category': widget.category,
      'exercise_name': widget.exercise,
      'detected_reps': _repCount + (_currentSet - 1) * _preferredReps,
      'duration_seconds': _durationSeconds,
      'accuracy_score': _accuracyScore,
      'sets_completed': _currentSet - 1,
      'total_sets': _preferredSets,
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

  void _resetWorkout() {
    setState(() {
      _repCount = 0;
      _currentSet = 1;
      _lastRepTime = null;
      _workoutCompleted = false;
      _showSuccessAnimation = false;
      _durationSeconds = 0;
      _accuracyScore = 0.0;
    });

    // Restart the timer
    _workoutTimer?.cancel();
    _startWorkoutTimer();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    _workoutTimer?.cancel();
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
              Text('Initializing camera...'),
            ],
          ),
        ),
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
            tooltip: 'Save Workout',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetWorkout,
            tooltip: 'Reset Workout',
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

          // Workout information overlay
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
                    'Set $_currentSet/$_preferredSets • ${_durationSeconds ~/ 60}:${(_durationSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showDumbbellWarning)
            Positioned(
              top: 100,
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

          // Rep counter
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_repCount / $_preferredReps',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'REPS',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
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

          // Completion message
          if (_workoutCompleted && !_showSuccessAnimation)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.green.withOpacity(0.8),
                child: const Text(
                  'Workout completed! Tap reset to start again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _workoutCompleted
          ? FloatingActionButton(
        onPressed: _resetWorkout,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.refresh),
      )
          : null,
    );
  }
}