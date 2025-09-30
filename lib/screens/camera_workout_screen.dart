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
enum RepState { starting, down, up }

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

// Added WidgetsBindingObserver to handle app lifecycle changes.
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

  // Rep state variables
  RepState _repState = RepState.starting;
  double _previousAngle = 0.0;
  double _previousVerticalPosition = 0.0;

  // Constants for Calorie Calculation
  double _userWeightKg = 70.0;
  final double _metValue = 4.0;

  // Store current pose for overlay
  Pose? _currentPose;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register the lifecycle observer.
    _fetchUserWeight();
    _initializeDetectors();
    _initializeCamera();
    _showExerciseInstructions();
  }

  // Handles app lifecycle state changes to prevent camera freezes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _fetchUserWeight() async {
    try {
      final uri = Uri.parse('http://192.168.100.79/repEatApi/get_profile.php?user_id=${widget.userId}');
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
          final caloriesPerSecond = (_metValue * 3.5 * _userWeightKg) / (200 * 60);
          _caloriesBurned += caloriesPerSecond;
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
        if (!_isPoseVisible) setState(() => _isPoseVisible = true);
        setState(() => _currentPose = poses.first); // Store current pose
        if (!_isRestPeriod) _analyzePose(poses.first);
      } else if (mounted) {
        setState(() {
          _isPoseVisible = false;
          _currentPose = null; // Clear pose when not detected
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
    if (name.contains('reverse flyes')) return MotionType.lateralRaise;
    if (name.contains('squat') || name.contains('lunge') || name.contains('step-up')) return MotionType.squat;
    if (name.contains('deadlift')) return MotionType.hipHinge;
    if (name.contains('calf raise')) return MotionType.legExtension;
    if (name.contains('russian twist') || name.contains('wood chop')) return MotionType.torsoRotation;
    if (name.contains('side bend')) return MotionType.lateralBend;
    if (name.contains('sit-up')) return MotionType.coreFlexion;
    if (name.contains('windmill')) return MotionType.shoulderArc;
    return MotionType.unclassified;
  }

  void _analyzePose(Pose pose) {
    MotionType motionType = _classifyExercise(widget.exercise);
    switch (motionType) {
      case MotionType.bicepCurl:
      case MotionType.hammerCurl:
        _analyzeBicepCurl(pose, motionType);
        break;
      case MotionType.tricepsExtension:
        _analyzeTricepsExtension(pose);
        break;
      case MotionType.squat:
        _analyzeSquat(pose);
        break;
      case MotionType.hipHinge:
        _analyzeGenericVerticalMovement(pose);
        break;
      case MotionType.horizontalPress:
        _analyzeShoulderPress(pose); // Similar logic
        break;
      case MotionType.verticalPress:
        _analyzeShoulderPress(pose);
        break;
      case MotionType.horizontalPull:
      case MotionType.shoulderElevation:
      case MotionType.legExtension:
      case MotionType.torsoRotation:
      case MotionType.lateralBend:
      case MotionType.coreFlexion:
      case MotionType.shoulderArc:
      case MotionType.lateralRaise:
        _analyzeGenericVerticalMovement(pose);
        break;
      default:
        _analyzeGenericMovement(pose);
        break;
    }
  }

  // **REMOVED** the _getMirroredLandmark method entirely.

  // **MODIFIED** to use raw landmark data.
  void _analyzeBicepCurl(Pose pose, MotionType motionType) {
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // Use the side that's more visible/available
    final elbow = leftElbow ?? rightElbow;
    final shoulder = leftShoulder ?? rightShoulder;
    final wrist = leftWrist ?? rightWrist;

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

  // **MODIFIED** to use raw landmark data.
  void _analyzeTricepsExtension(Pose pose) {
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    final elbow = leftElbow ?? rightElbow;
    final shoulder = leftShoulder ?? rightShoulder;
    final wrist = leftWrist ?? rightWrist;

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

  // **MODIFIED** to use raw landmark data.
  void _analyzeSquat(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    final hip = leftHip ?? rightHip;
    final knee = leftKnee ?? rightKnee;
    final ankle = leftAnkle ?? rightAnkle;

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

  // **MODIFIED** to use raw landmark data.
  void _analyzeShoulderPress(Pose pose) {
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    final elbow = leftElbow ?? rightElbow;
    final shoulder = leftShoulder ?? rightShoulder;
    final wrist = leftWrist ?? rightWrist;

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

  // **MODIFIED** to use raw landmark data.
  void _analyzeGenericVerticalMovement(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    final ankle = leftAnkle ?? rightAnkle;
    if (nose == null || ankle == null) return;

    double verticalPosition = (nose.y + ankle.y) / 2;
    if (_repState == RepState.starting) {
      setState(() {
        _repState = RepState.down;
        _previousVerticalPosition = verticalPosition;
      });
    } else if (verticalPosition < _previousVerticalPosition - 10 && _repState == RepState.down) {
      setState(() {
        _repState = RepState.up;
        _previousVerticalPosition = verticalPosition;
      });
    } else if (verticalPosition > _previousVerticalPosition + 10 && _repState == RepState.up) {
      _countRep();
      setState(() {
        _repState = RepState.down;
        _previousVerticalPosition = verticalPosition;
      });
    }
  }

  void _analyzeGenericMovement(Pose pose) {
    _updateFormStatus("Analysis not implemented.", Colors.red);
  }

  void _countRep() {
    if (_workoutCompleted || _isRestPeriod || _repCount >= widget.reps) return;

    final now = DateTime.now();
    if (_lastRepTime != null && now.difference(_lastRepTime!).inMilliseconds < 500) return;

    if (mounted) {
      setState(() {
        _repCount++;
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

    try {
      await http.post(
        Uri.parse('http://192.168.100.79/repEatApi/save_workout_session.php'),
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
    }
  }

  // MODIFIED: This dialog now shows "Continue" and "Discard" options.
  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('End Workout?'),
        content: const Text('Your progress will be discarded if you exit.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Returns false to onWillPop, stays on screen
            child: const Text('Continue'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              if (mounted) Navigator.of(context).pop(true); // Returns true to onWillPop, exits screen
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
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
    WidgetsBinding.instance.removeObserver(this); // Unregister the lifecycle observer.
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
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _restartWorkout)],
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
            // Skeletal overlay
            Positioned.fill(
              child: CustomPaint(
                painter: PosePainter(_currentPose, _cameraController!.value.previewSize!),
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
                if (_isRestPeriod)
                  Text('Rest: $_restSeconds s', style: const TextStyle(color: Colors.yellow, fontSize: 16)),
              ],
            ),
          ),
          if (_formStatus.isNotEmpty && !_isRestPeriod)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Text(_formStatus, style: TextStyle(color: _formStatusColor, fontSize: 18, fontWeight: FontWeight.bold)),
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

// **REMOVED** the duplicate PosePainter class from this file.
// Make sure it is defined in `pose_painter.dart`.