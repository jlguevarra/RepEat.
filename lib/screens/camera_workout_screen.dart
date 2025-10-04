// camera_workout_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

// Import the PosePainter from its own file
import 'pose_painter.dart';

// Enum to categorize the type of motion for different exercises.
enum MotionType {
  unclassified,
  squat,              // Squats, Lunges, Step-ups
  hipHinge,           // Deadlifts
  horizontalPress,    // Bench Press, Flyes
  verticalPress,      // Shoulder Press
  horizontalPull,     // Rows
  shoulderElevation,  // Shrugs
  legExtension,       // Calf Raises
  torsoRotation,      // Russian Twists, Wood Chops
  lateralBend,        // Side Bends
  coreFlexion,        // Sit-ups
  shoulderArc,        // Pullovers, Windmills
  bicepCurl,          // Bicep Curls
  hammerCurl,         // Hammer Curls
  tricepsExtension,   // Triceps Extensions
  lateralRaise,       // Reverse Flyes
}

// State machine for tracking the phase of a repetition.
enum RepState { starting, down, up, left, right } // Added left/right for rotational exercises

class CameraWorkoutScreen extends StatefulWidget {
  final int userId;
  final String exercise;
  final int reps;
  final int sets;
  final String planDay;
  final Function(bool, String)? onExerciseCompleted;

  const CameraWorkoutScreen({
    super.key,
    required this.userId,
    required this.exercise,
    required this.reps,
    required this.sets,
    required this.planDay,
    this.onExerciseCompleted,
  });

  @override
  State<CameraWorkoutScreen> createState() => _CameraWorkoutScreenState();
}

class _CameraWorkoutScreenState extends State<CameraWorkoutScreen> with WidgetsBindingObserver {
  // General State Variables
  CameraController? _cameraController;
  bool _isInitialized = false;
  int _repCount = 0;
  int _currentSet = 1;
  bool _workoutCompleted = false;
  int _durationSeconds = 0;
  Timer? _masterTimer;
  bool _isRestPeriod = false;
  int _restSeconds = 0;
  Timer? _restTimer;
  bool _showSuccessAnimation = false;
  double _caloriesBurned = 0.0;
  bool _isSaving = false;

  // Pose Detection Variables
  late PoseDetector _poseDetector;
  bool _isDetecting = false;
  DateTime? _lastRepTime;
  String _formStatus = "Position yourself in frame";
  Color _formStatusColor = Colors.white;
  bool _isPoseVisible = false;
  Size? _imageSize;

  // Rep state variables
  RepState _repState = RepState.starting;
  double _previousAngle = 0.0;
  double _previousVerticalPosition = 0.0;
  double _previousHorizontalPosition = 0.0;

  // Constants for Calorie Calculation
  double _userWeightKg = 70.0;
  final double _metValue = 4.0;

  // Store current pose for overlay
  Pose? _currentPose;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserWeight();
    _initializeDetectors();
    _initializeCamera();
    _showExerciseInstructions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      if (mounted) setState(() => _isInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _fetchUserWeight() async {
    try {
      final uri = Uri.parse('http://192.168.100.76/repEatApi/get_profile.php?user_id=${widget.userId}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data']['current_weight'] != null) {
          final weight = double.tryParse(data['data']['current_weight'].toString());
          if (weight != null && weight > 0 && mounted) {
            setState(() => _userWeightKg = weight);
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch user weight, using default. Error: $e");
    }
  }

  void _initializeDetectors() {
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
              const Icon(Icons.fitness_center, size: 60, color: Colors.blue),
              const SizedBox(height: 16),
              Text('${widget.sets} sets × ${widget.reps} reps', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Position yourself clearly in the frame. Reps will count when proper form is detected.', textAlign: TextAlign.center),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('START', style: TextStyle(fontSize: 18)))],
        );
      },
    );
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission is required')));
      return;
    }
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);

      _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: false);

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _startMasterTimer();
        _startPoseDetection();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _startMasterTimer() {
    _masterTimer?.cancel();
    _masterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPoseVisible && !_isRestPeriod && !_workoutCompleted && mounted) {
        setState(() {
          _durationSeconds++;
        });
      }
    });
  }

  void _startRestTimer() {
    _restSeconds = 60;
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0 && mounted) {
        setState(() => _restSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _startNextSet() {
    setState(() {
      _isRestPeriod = false;
      _repState = RepState.starting;
      _formStatus = "Begin next set!";
      _formStatusColor = Colors.white;
    });
  }

  void _startPoseDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    _cameraController!.startImageStream((CameraImage image) {
      if (_isDetecting || _workoutCompleted || !mounted) return;
      _isDetecting = true;
      _processCameraImage(image);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_imageSize == null && mounted) {
      setState(() {
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      });
    }

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        if (mounted) {
          _isDetecting = false;
          setState(() => _isPoseVisible = false);
        }
        return;
      }
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty && mounted) {
        if (_formStatus == "No person detected") {
          _updateFormStatus("Position yourself correctly", Colors.white);
        }

        if (!_isPoseVisible) setState(() => _isPoseVisible = true);
        setState(() => _currentPose = poses.first);
        if (!_isRestPeriod) _analyzePose(poses.first);
      } else if (mounted) {
        setState(() {
          _isPoseVisible = false;
          _currentPose = null;
          _formStatus = "No person detected";
          _formStatusColor = Colors.orange;
        });
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      if (mounted) _isDetecting = false;
    }
  }

  MotionType _classifyExercise(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('bench press') || name.contains('flyes')) return MotionType.horizontalPress;
    if (name.contains('shoulder press')) return MotionType.verticalPress;
    if (name.contains('triceps extension')) return MotionType.tricepsExtension;
    if (name.contains('pullover')) return MotionType.shoulderArc;
    if (name.contains('rows')) return MotionType.horizontalPull;
    if (name.contains('bicep curl')) return MotionType.bicepCurl;
    if (name.contains('hammer curl')) return MotionType.hammerCurl;
    if (name.contains('shrugs')) return MotionType.shoulderElevation;
    if (name.contains('reverse flyes') || name.contains('lateral raise')) return MotionType.lateralRaise;
    if (name.contains('squat') || name.contains('lunge') || name.contains('step-up')) return MotionType.squat;
    if (name.contains('deadlift')) return MotionType.hipHinge;
    if (name.contains('calf raise')) return MotionType.legExtension;
    if (name.contains('russian twist') || name.contains('wood chop')) return MotionType.torsoRotation;
    if (name.contains('side bend')) return MotionType.lateralBend;
    if (name.contains('sit-up') || name.contains('crunch')) return MotionType.coreFlexion;
    if (name.contains('windmill')) return MotionType.shoulderArc;
    return MotionType.unclassified;
  }

  void _analyzePose(Pose pose) {
    MotionType motionType = _classifyExercise(widget.exercise);
    switch (motionType) {
      case MotionType.bicepCurl:
      case MotionType.hammerCurl:
        _analyzeBicepCurl(pose);
        break;
      case MotionType.tricepsExtension:
        _analyzeTricepsExtension(pose);
        break;
      case MotionType.squat:
        _analyzeSquat(pose);
        break;
      case MotionType.verticalPress:
        _analyzeVerticalPress(pose);
        break;
      case MotionType.horizontalPress:
        _analyzeHorizontalPress(pose);
        break;
      case MotionType.lateralRaise:
        _analyzeLateralRaise(pose);
        break;
      case MotionType.shoulderElevation:
        _analyzeShoulderElevation(pose);
        break;
      case MotionType.hipHinge:
        _analyzeHipHinge(pose);
        break;
      case MotionType.horizontalPull:
        _analyzeHorizontalPull(pose);
        break;
      case MotionType.coreFlexion:
        _analyzeCoreFlexion(pose);
        break;
      case MotionType.legExtension:
        _analyzeLegExtension(pose);
        break;
      case MotionType.shoulderArc:
        _analyzeShoulderArc(pose);
        break;
      case MotionType.lateralBend:
        _analyzeLateralBend(pose);
        break;
      case MotionType.torsoRotation:
        _analyzeTorsoRotation(pose);
        break;
      default:
        _updateFormStatus("Exercise analysis not implemented.", Colors.red);
        break;
    }
  }

  // CORRECTED: This helper now takes a String and correctly finds the left/right landmarks.
  PoseLandmark? _getLandmark(Pose pose, String landmarkName) {
    final leftLandmarkName = 'left${landmarkName.capitalize()}';
    final rightLandmarkName = 'right${landmarkName.capitalize()}';

    final leftLandmark = pose.landmarks[PoseLandmarkType.values.byName(leftLandmarkName)];
    final rightLandmark = pose.landmarks[PoseLandmarkType.values.byName(rightLandmarkName)];

    // Prefer left landmark, fallback to right
    return leftLandmark ?? rightLandmark;
  }

  // Angle-based exercises
  void _analyzeBicepCurl(Pose pose) {
    // CORRECTED: Pass strings to _getLandmark
    final shoulder = _getLandmark(pose, "shoulder");
    final elbow = _getLandmark(pose, "elbow");
    final wrist = _getLandmark(pose, "wrist");
    if (shoulder == null || elbow == null || wrist == null) return;

    final angle = _calculateAngle(shoulder, elbow, wrist);
    if (angle < 60 && _repState == RepState.starting) {
      _updateFormStatus("Good form!", Colors.green);
      setState(() => _repState = RepState.up);
    } else if (angle > 140 && _repState == RepState.up) {
      _countRep();
      setState(() => _repState = RepState.starting);
    }
  }

  void _analyzeTricepsExtension(Pose pose) {
    final shoulder = _getLandmark(pose, "shoulder");
    final elbow = _getLandmark(pose, "elbow");
    final wrist = _getLandmark(pose, "wrist");
    if (shoulder == null || elbow == null || wrist == null) return;

    final angle = _calculateAngle(shoulder, elbow, wrist);
    if (angle > 160 && _repState == RepState.down) {
      _countRep();
      setState(() => _repState = RepState.starting);
    } else if (angle < 90 && _repState == RepState.starting) {
      _updateFormStatus("Good Form!", Colors.green);
      setState(() => _repState = RepState.down);
    }
  }

  void _analyzeSquat(Pose pose) {
    final hip = _getLandmark(pose, "hip");
    final knee = _getLandmark(pose, "knee");
    final ankle = _getLandmark(pose, "ankle");
    if (hip == null || knee == null || ankle == null) return;

    final kneeAngle = _calculateAngle(hip, knee, ankle);
    if (kneeAngle < 100 && _repState == RepState.starting) {
      _updateFormStatus("Go deeper!", Colors.orange);
      setState(() => _repState = RepState.down);
    } else if (kneeAngle > 160 && _repState == RepState.down) {
      _countRep();
      setState(() => _repState = RepState.starting);
    }
  }

  void _analyzeVerticalPress(Pose pose) { // Shoulder Press
    final shoulder = _getLandmark(pose, "shoulder");
    final elbow = _getLandmark(pose, "elbow");
    final wrist = _getLandmark(pose, "wrist");
    if (shoulder == null || elbow == null || wrist == null) return;

    final angle = _calculateAngle(shoulder, elbow, wrist);
    if (angle > 160 && _repState == RepState.down) {
      _countRep();
      setState(() => _repState = RepState.starting);
    } else if (angle < 80 && _repState == RepState.starting) {
      _updateFormStatus("Good form!", Colors.green);
      setState(() => _repState = RepState.down);
    }
  }

  void _analyzeHorizontalPress(Pose pose) { // Bench Press
    final shoulder = _getLandmark(pose, "shoulder");
    final elbow = _getLandmark(pose, "elbow");
    final wrist = _getLandmark(pose, "wrist");
    if (shoulder == null || elbow == null || wrist == null) return;

    final angle = _calculateAngle(shoulder, elbow, wrist);
    if (angle < 90 && _repState == RepState.starting) {
      setState(() => _repState = RepState.down);
    } else if (angle > 150 && _repState == RepState.down) {
      _countRep();
      setState(() => _repState = RepState.starting);
    }
  }

  void _analyzeLateralRaise(Pose pose) {
    final hip = _getLandmark(pose, "hip");
    final shoulder = _getLandmark(pose, "shoulder");
    final elbow = _getLandmark(pose, "elbow");
    if (hip == null || shoulder == null || elbow == null) return;

    final angle = _calculateAngle(hip, shoulder, elbow);
    if (angle > 80 && _repState == RepState.starting) {
      setState(() => _repState = RepState.up);
    } else if (angle < 30 && _repState == RepState.up) {
      _countRep();
      setState(() => _repState = RepState.starting);
    }
  }

  void _analyzeHipHinge(Pose pose) { // Deadlifts
    final shoulder = _getLandmark(pose, "shoulder");
    final hip = _getLandmark(pose, "hip");
    final knee = _getLandmark(pose, "knee");
    if (shoulder == null || hip == null || knee == null) return;

    final angle = _calculateAngle(shoulder, hip, knee);
    if (angle < 100 && _repState == RepState.starting) {
      setState(() => _repState = RepState.down);
    } else if (angle > 160 && _repState == RepState.down) {
      _countRep();
      setState(() => _repState = RepState.starting);
    }
  }

  void _analyzeHorizontalPull(Pose pose) { // Rows
    final shoulder = _getLandmark(pose, "shoulder");
    final elbow = _getLandmark(pose, "elbow");
    final wrist = _getLandmark(pose, "wrist");
    if (shoulder == null || elbow == null || wrist == null) return;

    final angle = _calculateAngle(shoulder, elbow, wrist);
    if (angle < 80 && _repState == RepState.starting) {
      setState(() => _repState = RepState.up);
    } else if (angle > 140 && _repState == RepState.up) {
      _countRep();
      setState(() => _repState = RepState.starting);
    }
  }

  void _analyzeCoreFlexion(Pose pose) { // Sit-ups
    final shoulder = _getLandmark(pose, "shoulder");
    final hip = _getLandmark(pose, "hip");
    final knee = _getLandmark(pose, "knee");
    if (shoulder == null || hip == null || knee == null) return;

    final angle = _calculateAngle(shoulder, hip, knee);
    if (angle < 100 && _repState == RepState.starting) {
      setState(() => _repState = RepState.up);
    } else if (angle > 150 && _repState == RepState.up) {
      _countRep();
      setState(() => _repState = RepState.starting);
    }
  }

  void _analyzeShoulderArc(Pose pose) { // Pullovers
    final elbow = _getLandmark(pose, "elbow");
    final shoulder = _getLandmark(pose, "shoulder");
    final hip = _getLandmark(pose, "hip");
    if (elbow == null || shoulder == null || hip == null) return;

    final angle = _calculateAngle(elbow, shoulder, hip);
    if (angle < 100 && _repState == RepState.starting) {
      setState(() => _repState = RepState.down);
    } else if (angle > 160 && _repState == RepState.down) {
      _countRep();
      setState(() => _repState = RepState.starting);
    }
  }

  // Position-based exercises
  // Position-based exercises
  void _analyzeShoulderElevation(Pose pose) { // Shrugs
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final rightEar = pose.landmarks[PoseLandmarkType.rightEar];

    if (leftShoulder == null || rightShoulder == null || leftEar == null || rightEar == null) return;

    // Use a relative distance (shoulder to ear) to be less sensitive to the user moving up/down.
    // A smaller distance means a higher shrug.
    final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final earY = (leftEar.y + rightEar.y) / 2;
    final shrugDistance = (shoulderY - earY).abs();

    // On the first frame, establish the baseline "down" (relaxed) distance.
    if (_repState == RepState.starting) {
      setState(() {
        // This variable now stores the relaxed shoulder-to-ear distance.
        _previousVerticalPosition = shrugDistance;
        _repState = RepState.down;
      });
      return;
    }

    // Define the "up" and "down" thresholds based on the user's own body.
    // A shrug is counted when the shoulders get ~15% closer to the ears.
    final downThreshold = _previousVerticalPosition;
    final upThreshold = downThreshold * 0.85;

    // If shoulders are relaxed, we are looking for them to move up.
    if (_repState == RepState.down && shrugDistance < upThreshold) {
      _updateFormStatus("Shrug Up!", Colors.green);
      setState(() {
        _repState = RepState.up;
      });
    }
    // If shoulders are up, we are looking for them to return to the relaxed position.
    else if (_repState == RepState.up && shrugDistance > downThreshold * 0.95) {
      _countRep();
      setState(() {
        _repState = RepState.down;
      });
    }
  }

  void _analyzeLegExtension(Pose pose) { // Calf Raises
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftHeel = pose.landmarks[PoseLandmarkType.leftHeel];
    final rightHeel = pose.landmarks[PoseLandmarkType.rightHeel];
    if (leftAnkle == null || rightAnkle == null || leftHeel == null || rightHeel == null) return;

    final heelY = (leftHeel.y + rightHeel.y) / 2;
    if (_repState == RepState.starting) {
      setState(() {
        _previousVerticalPosition = heelY;
        _repState = RepState.down;
      });
      return;
    }

    final verticalDisplacement = _previousVerticalPosition - heelY;
    if (verticalDisplacement > 15 && _repState == RepState.down) { // Heels up
      setState(() => _repState = RepState.up);
    } else if (verticalDisplacement < 5 && _repState == RepState.up) { // Heels down
      _countRep();
      setState(() => _repState = RepState.down);
    }
  }

  void _analyzeLateralBend(Pose pose) { // Side Bends
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    if (leftShoulder == null || rightShoulder == null) return;

    final shoulderYDiff = (leftShoulder.y - rightShoulder.y).abs();
    if (_repState == RepState.starting) {
      if (shoulderYDiff < 20) {
        setState(() => _repState = RepState.up); // Using 'up' for neutral
      }
    } else if (shoulderYDiff > 40) {
      if (_repState == RepState.up) setState(() => _repState = RepState.down);
    } else if (shoulderYDiff < 20 && _repState == RepState.down) {
      _countRep();
      setState(() => _repState = RepState.up);
    }
  }

  void _analyzeTorsoRotation(Pose pose) { // Russian Twists
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    if (leftHip == null || rightHip == null || leftWrist == null || rightWrist == null) return;

    final hipCenterX = (leftHip.x + rightHip.x) / 2;
    final wristCenterX = (leftWrist.x + rightWrist.x) / 2;

    if (_repState == RepState.starting) {
      setState(() => _repState = RepState.up); // Using 'up' as center state
    }

    if (wristCenterX < hipCenterX - 50 && _repState != RepState.left) { // Twisted Left
      if(_repState == RepState.right) _countRep();
      setState(() => _repState = RepState.left);
    } else if (wristCenterX > hipCenterX + 50 && _repState != RepState.right) { // Twisted Right
      if(_repState == RepState.left) _countRep();
      setState(() => _repState = RepState.right);
    }
  }

  void _countRep() {
    if (_workoutCompleted || _isRestPeriod || _repCount >= widget.reps) return;

    final now = DateTime.now();
    if (_lastRepTime != null && now.difference(_lastRepTime!).inMilliseconds < 500) return;

    if (mounted) {
      final double caloriesPerRep = (_metValue * 3.5 * _userWeightKg) / (200 * 20);

      setState(() {
        _repCount++;
        _caloriesBurned += caloriesPerRep;
        _lastRepTime = now;
      });

      _updateFormStatus("REP COUNTED!", Colors.green);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _formStatus == "REP COUNTED!") _updateFormStatus("Keep Going!", Colors.white);
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
    _repState = RepState.starting;
    setState(() {
      _isRestPeriod = true;
      _currentSet++;
      _repCount = 0;
      _formStatus = "Set completed! Rest period";
      _formStatusColor = Colors.yellow;
    });
    _startRestTimer();
  }

  void _completeWorkout() {
    if (_isSaving) return;
    _isSaving = true;

    if (mounted) setState(() => _showSuccessAnimation = true);
    _masterTimer?.cancel();
    _restTimer?.cancel();
    if (widget.onExerciseCompleted != null) widget.onExerciseCompleted!(true, widget.exercise);
    _saveWorkoutData(isFullWorkout: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _saveWorkoutData({bool isFullWorkout = false}) async {
    int totalCompletedReps = isFullWorkout
        ? widget.reps * widget.sets
        : (_currentSet - 1) * widget.reps + _repCount;

    if (totalCompletedReps == 0) return;
    _isSaving = true;

    try {
      await http.post(
        Uri.parse('http://192.168.100.76/repEatApi/save_workout_session.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'exercise': widget.exercise,
          'completed_reps': totalCompletedReps,
          'target_reps': widget.reps * widget.sets,
          'duration_seconds': _durationSeconds,
          'date': DateTime.now().toIso8601String(),
          'plan_day': widget.planDay,
          'calories_burned': _caloriesBurned.round(),
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Could not save workout  $e");
    } finally {
      if (mounted) _isSaving = false;
    }
  }

  Future<void> _showRestartConfirmationDialog() async {
    final bool? shouldRestart = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF2C2C2E),
          title: const Center(
            child: Text(
              'Restart Workout?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 50),
              const SizedBox(height: 16),
              const Text(
                'Are you sure? This will reset your reps and sets for this exercise.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orangeAccent,
                    side: const BorderSide(color: Colors.orangeAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Restart'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldRestart == true) {
      _restartWorkout();
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    _masterTimer?.cancel();

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF2C2C2E),
          title: const Center(
            child: Text('End Workout?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 50),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to exit? Your current progress will be discarded.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continue Workout'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Discard'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      return true;
    } else {
      _startMasterTimer();
      return false;
    }
  }

  void _updateFormStatus(String text, Color color) {
    if(mounted) {
      setState(() {
        _formStatus = text;
        _formStatusColor = color;
      });
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation rotation;
    switch (sensorOrientation) {
      case 0: rotation = InputImageRotation.rotation0deg; break;
      case 90: rotation = InputImageRotation.rotation90deg; break;
      case 180: rotation = InputImageRotation.rotation180deg; break;
      case 270: rotation = InputImageRotation.rotation270deg; break;
      default: rotation = InputImageRotation.rotation0deg;
    }
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
    final allBytes = image.planes.fold<List<int>>(<int>[], (p, e) => p..addAll(e.bytes));
    final bytes = Uint8List.fromList(allBytes);
    final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow);
    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x);
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  void _restartWorkout() {
    setState(() {
      _repCount = 0;
      _currentSet = 1;
      _workoutCompleted = false;
      _showSuccessAnimation = false;
      _durationSeconds = 0;
      _restSeconds = 0;
      _caloriesBurned = 0.0;
      _isRestPeriod = false;
      _repState = RepState.starting;
      _formStatus = "Workout restarted!";
      _formStatusColor = Colors.white;
      _previousAngle = 0.0;
      _previousVerticalPosition = 0.0;
      _isSaving = false;
      _currentPose = null;
    });
    _startMasterTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _poseDetector.close();
    _masterTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showExitConfirmationDialog,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.exercise),
          backgroundColor: Colors.deepPurple,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _showRestartConfirmationDialog)],
        ),
        body: _isInitialized && _cameraController != null && _cameraController!.value.isInitialized
            ? Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _cameraController!.value.previewSize!.height,
                height: _cameraController!.value.previewSize!.width,
                child: CameraPreview(_cameraController!),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: PosePainter(
                    (_isRestPeriod || !_isPoseVisible) ? null : _currentPose,
                    _imageSize ?? _cameraController!.value.previewSize!
                ),
              ),
            ),
            _buildUIOverlays(),
            if (_showSuccessAnimation)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 100),
                    SizedBox(height: 20),
                    Text('Workout Completed!', style: TextStyle(color: Colors.white, fontSize: 24)),
                  ]),
                ),
              ),
          ],
        )
            : const Center(child: CircularProgressIndicator()),
      ),
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
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text('${_durationSeconds ~/ 60}:${(_durationSeconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.fitness_center, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text('Set $_currentSet/${widget.sets}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 6),
                  Text('${_caloriesBurned.toStringAsFixed(1)} kcal', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ]),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: _isRestPeriod
                ? Text(
              'REST: $_restSeconds s',
              style: const TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold),
            )
                : Text(
              _formStatus,
              style: TextStyle(color: _formStatusColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: Text('$_repCount / ${widget.reps}', style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (_isRestPeriod && _restSeconds == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: _startNextSet,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('START NEXT SET'),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

// Helper extension to capitalize strings for landmark lookups
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}