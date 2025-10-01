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
import 'dumbbell_bicep_curls_logic.dart';
import 'dumbbell_shoulder_press_logic.dart';
import 'dumbbell_squats_logic.dart';
import 'dumbbell_rows_logic.dart';
import 'dumbbell_triceps_extension_logic.dart';
import 'dumbbell_russian_twists_logic.dart';
import 'dumbbell_shrugs_logic.dart';
import 'dumbbell_flyes_logic.dart';
import 'dumbbell_reverse_flyes_logic.dart';
import 'dumbbell_lunges_logic.dart';
import 'dumbbell_deadlifts_logic.dart';
import 'dumbbell_calf_raises_logic.dart';
import 'dumbbell_step_ups_logic.dart';
import 'dumbbell_side_bends_logic.dart';
import 'dumbbell_wood_chops_logic.dart';
import 'dumbbell_situps_logic.dart';
import 'dumbbell_windmills_logic.dart';
import 'dumbbell_pullover_logic.dart';
import 'dumbbell_hammer_curls_logic.dart';

import 'pose_painter.dart';


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
  int _noPoseFrames = 0;
  final int _maxNoPoseFrames = 10;
  // Exercise State Variables - ADD THESE
  String _currentExerciseState = "starting";
  String _previousExerciseState = "starting";

  // Shrug-specific state
  String _currentShrugState = "starting";
  String _previousShrugState = "starting";

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
      final uri = Uri.parse('http://192.168.100.11/repEatApi/get_profile.php?user_id=${widget.userId}');
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
              const Text(
                'For Dumbbell Shrugs:\n\n'
                    '1. Stand upright with dumbbells at your sides\n'
                    '2. Keep your arms straight\n'
                    '3. Shrug your shoulders upward toward your ears\n'
                    '4. Hold at the top, then lower slowly\n'
                    '5. Ensure your shoulders and head are clearly visible',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
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
      _currentExerciseState = "starting";
      _previousExerciseState = "starting";
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
          _handleNoPoseDetection();
        }
        return;
      }
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty && mounted) {
        _noPoseFrames = 0;

        if (!_isPoseVisible) {
          setState(() => _isPoseVisible = true);
        }
        setState(() => _currentPose = poses.first);
        if (!_isRestPeriod) _analyzePose(poses.first);
      } else if (mounted) {
        _handleNoPoseDetection();
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      if (mounted) {
        _handleNoPoseDetection();
      }
    } finally {
      if (mounted) _isDetecting = false;
    }
  }

  void _handleNoPoseDetection() {
    _noPoseFrames++;

    if (_noPoseFrames >= _maxNoPoseFrames) {
      setState(() {
        _isPoseVisible = false;
        _currentPose = null;
        _formStatus = "Stand in frame with dumbbells at your sides";
        _formStatusColor = Colors.orange;
      });
    }
  }

  void _analyzePose(Pose pose) {
    String currentState = "starting";
    String previousState = _currentExerciseState;

    switch (widget.exercise.toLowerCase()) {
      case "dumbbell bicep curls":
        currentState = DumbbellBicepCurlsLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellBicepCurlsLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell shoulder press":
        currentState = DumbbellShoulderPressLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellShoulderPressLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell squats":
        currentState = DumbbellSquatsLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellSquatsLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell rows":
        currentState = DumbbellRowsLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellRowsLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell triceps extension":
        currentState = DumbbellTricepsExtensionLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellTricepsExtensionLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell russian twists":
        currentState = DumbbellRussianTwistsLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellRussianTwistsLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell shrugs":
        currentState = DumbbellShrugsLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellShrugsLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell hammer curls":
        currentState = DumbbellHammerCurlsLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellHammerCurlsLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell flyes":
        currentState = DumbbellFlyesLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellFlyesLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell reverse flyes":
        currentState = DumbbellReverseFlyesLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellReverseFlyesLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell lunges":
        currentState = DumbbellLungesLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellLungesLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell deadlifts":
        currentState = DumbbellDeadliftsLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellDeadliftsLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell calf raises":
        currentState = DumbbellCalfRaisesLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellCalfRaisesLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell step-ups":
        currentState = DumbbellStepUpsLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellStepUpsLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell side bends":
        currentState = DumbbellSideBendsLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellSideBendsLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell wood chops":
        currentState = DumbbellWoodChopsLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellWoodChopsLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell sit-ups":
        currentState = DumbbellSitupsLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellSitupsLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell windmills":
        currentState = DumbbellWindmillsLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellWindmillsLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      case "dumbbell pullover":
        currentState = DumbbellPulloverLogic.analyzePose(pose, _updateFormStatus);
        if (DumbbellPulloverLogic.shouldCountRep(currentState, previousState)) {
          _countRep();
        }
        break;

      default:
        _updateFormStatus("Exercise analysis not available", false);
        break;
    }

    _currentExerciseState = currentState;
  }
  void _countRep() {
    if (_workoutCompleted || _isRestPeriod || _repCount >= widget.reps) return;

    final now = DateTime.now();
    if (_lastRepTime != null && now.difference(_lastRepTime!).inMilliseconds < 1000) return;

    if (mounted) {
      setState(() {
        _repCount++;
        _lastRepTime = now;
      });
      _updateFormStatus("REP COUNTED! Good shrug!", true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _formStatus.contains("REP COUNTED")) {
          _updateFormStatus("Continue shrugging", true);
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
        Uri.parse('http://192.168.100.11/repEatApi/save_workout_session.php'),
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

  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('End Workout?'),
        content: const Text('Your progress will be discarded if you exit.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              if (mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _updateFormStatus(String text, bool isGoodForm) {
    if(mounted) {
      setState(() {
        _formStatus = text;
        _formStatusColor = isGoodForm ? Colors.green : Colors.orange;
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
      _currentExerciseState = "starting";
      _previousExerciseState = "starting";
      _formStatus = "Workout restarted!";
      _formStatusColor = Colors.white;
      _isSaving = false;
      _currentPose = null;
      _noPoseFrames = 0;
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
          if (_formStatus.isNotEmpty)
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