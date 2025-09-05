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
  int _preferredReps = 10;
  int _preferredSets = 3;
  int _currentSet = 1;
  bool _isDownPosition = false;
  Size? _imageSize;
  List<Pose> _poses = [];
  bool _isFrontCamera = true;
  bool _isInitialized = false;
  bool _showFormWarning = false;
  DateTime? _lastRepTime;
  bool _workoutCompleted = false;
  double _accuracyScore = 0.0;
  int _durationSeconds = 0;
  Timer? _workoutTimer;
  bool _showSuccessAnimation = false;
  String _formFeedback = '';

  // Complete exercise detection mapping
  final Map<String, Function> _exerciseDetectors = {
    // Weight Loss Exercises (Bodyweight + Cardio)
    'Push-ups': _detectPushups,
    'Bodyweight Squats': _detectSquats,
    'Lunges': _detectLunges,
    'Plank': _detectPlank,
    'Burpees': _detectBurpees,
    'Jumping Jacks': _detectJumpingJacks,
    'Mountain Climbers': _detectMountainClimbers,
    'High Knees': _detectHighKnees,
    'Jump Squats': _detectJumpSquats,
    'Walking Lunges': _detectLunges,
    'Glute Bridges': _detectGluteBridges,
    'Leg Raises': _detectLegRaises,
    'Bicycle Crunches': _detectBicycleCrunches,
    'Tricep Dips': _detectTricepDips,

    // Muscle Gain Exercises (Dumbbell)
    'Dumbbell Bench Press': _detectBenchPress,
    'Dumbbell Shoulder Press': _detectShoulderPress,
    'Dumbbell Rows': _detectRows,
    'Dumbbell Bicep Curls': _detectDumbbellCurls,
    'Dumbbell Flyes': _detectChestFlyes,
    'Dumbbell Pullover': _detectPullovers,
    'Dumbbell Lateral Raises': _detectLateralRaises,
    'Dumbbell Front Raises': _detectFrontRaises,
    'Dumbbell Shrugs': _detectShrugs,
    'Dumbbell Tricep Extension': _detectTricepExtension,
    'Dumbbell Hammer Curls': _detectHammerCurls,
    'Dumbbell Concentration Curls': _detectConcentrationCurls,
    'Dumbbell Step Ups': _detectStepUps,
    'Dumbbell Calf Raises': _detectCalfRaises,
    'Dumbbell Russian Twists': _detectRussianTwists,
    'Dumbbell Side Bends': _detectSideBends,
    'Push-up to Renegade Row': _detectRenegadeRows,
    'Dumbbell Thruster': _detectThrusters,
    'Dumbbell Snatch': _detectSnatch,
    'Dumbbell Swing': _detectSwing,
    'Dumbbell Clean and Press': _detectCleanPress,
  };

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _showExerciseGuide().then((_) => _fetchUserGoals().then((_) => _initializeCamera()));
  }

  Future<void> _showExerciseGuide() async {
    final guide = exerciseGuides[widget.exercise];
    if (guide == null) return;

    await Future.delayed(const Duration(milliseconds: 100));

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
                Text(guide.description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                Text(
                  'Target: $_preferredSets sets of $_preferredReps reps',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
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
  }

  Widget _buildGuideImage(String assetPath) {
    try {
      return Image.asset(assetPath, height: 150, fit: BoxFit.cover);
    } catch (e) {
      return Container(
        height: 150,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.error_outline, color: Colors.red)),
      );
    }
  }

  Future<void> _fetchUserGoals() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost/repEatApi/get_user_onboarding.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.userId}),
      ).timeout(const Duration(seconds: 5));

      final result = jsonDecode(response.body);
      if (result['success']) {
        setState(() {
          _preferredReps = int.tryParse(result['data']['preferred_reps'].toString()) ?? 10;
          _preferredSets = int.tryParse(result['data']['preferred_sets'].toString()) ?? 3;
        });
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
      _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camera error: $e')));
    }
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_workoutCompleted) {
        setState(() => _durationSeconds++);
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
        setState(() => _poses = poses);
        if (poses.isNotEmpty) {
          _detectExerciseReps(poses);
          _updateFormFeedback(poses.first);
        }
      }
    } catch (e) {
      debugPrint('Pose detection error: $e');
    } finally {
      _isBusy = false;
    }
  }

  InputImage _getInputImage(CameraImage image) {
    final rotation = _isFrontCamera ? InputImageRotation.rotation270deg : InputImageRotation.rotation90deg;
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
    for (final plane in planes) buffer.add(plane.bytes);
    return buffer.toBytes();
  }

  void _detectExerciseReps(List<Pose> poses) {
    if (poses.isEmpty || _currentSet > _preferredSets || _workoutCompleted) return;

    final pose = poses.first;
    final detector = _exerciseDetectors[widget.exercise];

    // Validate exercise form
    final isValidForm = _validateExerciseForm(pose, widget.exercise);
    setState(() => _showFormWarning = !isValidForm);

    if (!isValidForm) return;

    if (detector != null) {
      _isDownPosition = detector(
        pose: pose,
        isDownPosition: _isDownPosition,
        onRepDetected: _onRepDetected,
      );
    } else {
      _genericRepDetection(pose);
    }
  }

  void _genericRepDetection(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (leftWrist != null && rightWrist != null && leftShoulder != null && rightShoulder != null) {
      final avgWristY = (leftWrist.y + rightWrist.y) / 2;
      final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
      final relativeHeight = (avgWristY - avgShoulderY).abs();

      if (relativeHeight < 0.1 && !_isDownPosition) {
        _isDownPosition = true;
      } else if (relativeHeight > 0.3 && _isDownPosition) {
        _onRepDetected();
        _isDownPosition = false;
      }
    }
  }

  void _updateFormFeedback(Pose pose) {
    setState(() {
      _formFeedback = _getExerciseFeedback(pose, widget.exercise);
    });
  }

  // WEIGHT LOSS EXERCISE DETECTORS
  static bool _detectPushups({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];

    if (leftShoulder != null && rightShoulder != null && leftElbow != null && rightElbow != null) {
      final leftAngle = _calculateAngle(leftShoulder, leftElbow);
      final rightAngle = _calculateAngle(rightShoulder, rightElbow);
      final avgAngle = (leftAngle + rightAngle) / 2;

      if (avgAngle > 160 && !isDownPosition) {
        isDownPosition = true;
      } else if (avgAngle < 90 && isDownPosition) {
        onRepDetected();
        isDownPosition = false;
      }
    }
    return isDownPosition;
  }

  static bool _detectSquats({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (leftHip != null && rightHip != null && leftKnee != null && rightKnee != null) {
      final leftAngle = _calculateAngle(leftHip, leftKnee);
      final rightAngle = _calculateAngle(rightHip, rightKnee);
      final avgAngle = (leftAngle + rightAngle) / 2;

      if (avgAngle > 170 && !isDownPosition) {
        isDownPosition = true;
      } else if (avgAngle < 100 && isDownPosition) {
        onRepDetected();
        isDownPosition = false;
      }
    }
    return isDownPosition;
  }

  static bool _detectLunges({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftKnee != null && rightKnee != null && leftHip != null && rightHip != null) {
      final leftAngle = _calculateAngle(leftHip, leftKnee);
      final rightAngle = _calculateAngle(rightHip, rightKnee);
      final minAngle = math.min(leftAngle, rightAngle);

      if (minAngle > 120 && !isDownPosition) {
        isDownPosition = true;
      } else if (minAngle < 90 && isDownPosition) {
        onRepDetected();
        isDownPosition = false;
      }
    }
    return isDownPosition;
  }

  static bool _detectPlank({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    return isDownPosition;
  }

  static bool _detectBurpees({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftWrist != null && rightWrist != null && leftAnkle != null && rightAnkle != null) {
      final wristHeight = (leftWrist.y + rightWrist.y) / 2;
      final ankleHeight = (leftAnkle.y + rightAnkle.y) / 2;
      final heightDiff = (wristHeight - ankleHeight).abs();

      if (heightDiff < 0.1 && !isDownPosition) {
        isDownPosition = true;
      } else if (heightDiff > 0.3 && isDownPosition) {
        onRepDetected();
        isDownPosition = false;
      }
    }
    return isDownPosition;
  }

  // MUSCLE GAIN EXERCISE DETECTORS
  static bool _detectBenchPress({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (leftWrist != null && rightWrist != null && leftShoulder != null && rightShoulder != null) {
      final wristHeight = (leftWrist.y + rightWrist.y) / 2;
      final shoulderHeight = (leftShoulder.y + rightShoulder.y) / 2;
      final heightDiff = (wristHeight - shoulderHeight).abs();

      if (heightDiff < 0.05 && !isDownPosition) {
        isDownPosition = true;
      } else if (heightDiff > 0.2 && isDownPosition) {
        onRepDetected();
        isDownPosition = false;
      }
    }
    return isDownPosition;
  }

  static bool _detectShoulderPress({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (leftWrist != null && rightWrist != null && leftShoulder != null && rightShoulder != null) {
      final wristHeight = (leftWrist.y + rightWrist.y) / 2;
      final shoulderHeight = (leftShoulder.y + rightShoulder.y) / 2;
      final heightDiff = (wristHeight - shoulderHeight).abs();

      if (heightDiff < 0.1 && !isDownPosition) {
        isDownPosition = true;
      } else if (heightDiff > 0.3 && isDownPosition) {
        onRepDetected();
        isDownPosition = false;
      }
    }
    return isDownPosition;
  }

  static bool _detectRows({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];

    if (leftWrist != null && rightWrist != null && leftElbow != null && rightElbow != null) {
      final leftAngle = _calculateAngle(leftElbow, leftWrist);
      final rightAngle = _calculateAngle(rightElbow, rightWrist);
      final avgAngle = (leftAngle + rightAngle) / 2;

      if (avgAngle > 150 && !isDownPosition) {
        isDownPosition = true;
      } else if (avgAngle < 90 && isDownPosition) {
        onRepDetected();
        isDownPosition = false;
      }
    }
    return isDownPosition;
  }

  // Add similar detection functions for other exercises...

  static bool _detectDumbbellCurls({required Pose pose, required bool isDownPosition, required Function onRepDetected}) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (leftWrist != null && rightWrist != null && leftShoulder != null && rightShoulder != null) {
      final wristHeight = (leftWrist.y + rightWrist.y) / 2;
      final shoulderHeight = (leftShoulder.y + rightShoulder.y) / 2;
      final heightDiff = (wristHeight - shoulderHeight).abs();

      if (heightDiff < 0.1 && !isDownPosition) {
        isDownPosition = true;
      } else if (heightDiff > 0.3 && isDownPosition) {
        onRepDetected();
        isDownPosition = false;
      }
    }
    return isDownPosition;
  }

  // Placeholder detectors for other exercises
  static bool _detectChestFlyes({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectPullovers({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectLateralRaises({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectFrontRaises({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectShrugs({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectTricepExtension({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectHammerCurls({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectConcentrationCurls({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectStepUps({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectCalfRaises({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectRussianTwists({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectSideBends({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectRenegadeRows({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectThrusters({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectSnatch({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectSwing({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectCleanPress({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectJumpingJacks({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectMountainClimbers({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectHighKnees({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectJumpSquats({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectGluteBridges({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectLegRaises({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectBicycleCrunches({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;
  static bool _detectTricepDips({required Pose pose, required bool isDownPosition, required Function onRepDetected}) => isDownPosition;

  static double _calculateAngle(PoseLandmark a, PoseLandmark b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return math.atan2(dy, dx) * 180 / math.pi;
  }

  void _onRepDetected() {
    final now = DateTime.now();
    if (_lastRepTime != null && now.difference(_lastRepTime!).inMilliseconds < 500) return;
    _lastRepTime = now;

    setState(() => _repCount++);
    _checkSetCompletion();
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
      _accuracyScore = _calculateAccuracyScore();
    });

    _workoutTimer?.cancel();
    saveCameraWorkout().then((_) {
      widget.onExerciseCompleted(true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSuccessAnimation = false);
      });
    });
  }

  double _calculateAccuracyScore() {
    final expectedReps = _preferredReps * _preferredSets;
    final completedReps = (_preferredSets - 1) * _preferredReps + _repCount;
    double baseScore = completedReps / expectedReps;
    if (_showFormWarning) baseScore *= 0.8;
    return baseScore.clamp(0.0, 1.0);
  }

  Future<void> saveCameraWorkout() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost/repEatApi/camera_workout_screen.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'date': DateTime.now().toIso8601String().split('T')[0],
          'category': widget.category,
          'exercise_name': widget.exercise,
          'detected_reps': _repCount + (_currentSet - 1) * _preferredReps,
          'duration_seconds': _durationSeconds,
          'accuracy_score': _accuracyScore,
          'sets_completed': _currentSet - 1,
          'total_sets': _preferredSets,
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
          SnackBar(content: Text('❌ Error saving workout: $e')),
        );
      }
    }
  }

  bool _validateExerciseForm(Pose pose, String exercise) {
    switch (exercise) {
      case 'Push-ups':
        return _validatePushupForm(pose);
      case 'Dumbbell Bench Press':
        return _validateBenchPressForm(pose);
      case 'Bodyweight Squats':
        return _validateSquatForm(pose);
      default:
        return true;
    }
  }

  bool _validatePushupForm(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (leftShoulder != null && leftHip != null && leftAnkle != null) {
      final bodyAlignment = (leftShoulder.y - leftHip.y).abs() + (leftHip.y - leftAnkle.y).abs();
      return bodyAlignment < 0.2;
    }
    return false;
  }

  bool _validateBenchPressForm(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    return leftWrist != null && rightWrist != null && (leftWrist.y - rightWrist.y).abs() < 0.1;
  }

  bool _validateSquatForm(Pose pose) {
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftKnee != null && rightKnee != null && leftAnkle != null && rightAnkle != null) {
      final kneeAlignment = (leftKnee.x - rightKnee.x).abs();
      final ankleAlignment = (leftAnkle.x - rightAnkle.x).abs();
      return kneeAlignment < 0.2 && ankleAlignment < 0.2;
    }
    return false;
  }

  String _getExerciseFeedback(Pose pose, String exercise) {
    switch (exercise) {
      case 'Push-ups':
        return _getPushupFeedback(pose);
      case 'Dumbbell Bench Press':
        return _getBenchPressFeedback(pose);
      case 'Bodyweight Squats':
        return _getSquatFeedback(pose);
      default:
        return 'Maintain good form!';
    }
  }

  String _getPushupFeedback(Pose pose) {
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];

    if (leftElbow != null && rightElbow != null) {
      final elbowAngle = (_calculateAngle(pose.landmarks[PoseLandmarkType.leftShoulder]!, leftElbow) +
          _calculateAngle(pose.landmarks[PoseLandmarkType.rightShoulder]!, rightElbow)) / 2;

      if (elbowAngle < 45) return 'Go deeper!';
      if (elbowAngle > 120) return 'Good depth!';
    }
    return 'Maintain form!';
  }

  String _getBenchPressFeedback(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftWrist != null && rightWrist != null) {
      final heightDiff = (leftWrist.y - rightWrist.y).abs();
      if (heightDiff > 0.15) return 'Keep arms even!';
    }
    return 'Good form!';
  }

  String _getSquatFeedback(Pose pose) {
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (leftKnee != null && rightKnee != null) {
      final kneeAlignment = (leftKnee.x - rightKnee.x).abs();
      if (kneeAlignment > 0.25) return 'Keep knees aligned!';
    }
    return 'Good squat form!';
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
      _showFormWarning = false;
      _formFeedback = '';
    });
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
          IconButton(icon: const Icon(Icons.save), onPressed: saveCameraWorkout, tooltip: 'Save Workout'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetWorkout, tooltip: 'Reset Workout'),
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
              painter: PosePainter(_poses, imageSize: _imageSize!, isFrontCamera: _isFrontCamera),
            ),
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
                  Text(widget.exercise, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Set $_currentSet/$_preferredSets • ${_durationSeconds ~/ 60}:${(_durationSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
          if (_showFormWarning)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withOpacity(0.7),
                child: const Text(
                  'Improve your form to count reps',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (_formFeedback.isNotEmpty)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.blue.withOpacity(0.7),
                child: Text(
                  _formFeedback,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
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
                    Text('$_repCount / $_preferredReps', style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('REPS', style: TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          if (_showSuccessAnimation)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 100),
                      SizedBox(height: 20),
                      Text('Workout Completed!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
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
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _workoutCompleted ? FloatingActionButton(
        onPressed: _resetWorkout,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.refresh),
      ) : null,
    );
  }
}