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

// Enum to categorize the type of motion for different exercises.
enum MotionType {
  unclassified,
  elbowFlexion,       // Curls, Triceps Extensions
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

class _CameraWorkoutScreenState extends State<CameraWorkoutScreen> {
  // General State Variables
  CameraController? _cameraController;
  bool _isInitialized = false;
  int _repCount = 0;
  int _currentSet = 1;
  bool _workoutCompleted = false;
  int _durationSeconds = 0;
  Timer? _workoutTimer;
  bool _isRestPeriod = false;
  int _restSeconds = 0;
  Timer? _restTimer;
  bool _showSuccessAnimation = false;

  // Pose Detection Variables
  late PoseDetector _poseDetector;
  bool _isDetecting = false;
  DateTime? _lastRepTime;
  String _formStatus = "Position yourself in frame";
  Color _formStatusColor = Colors.white;

  // Rep state variables
  bool _isUpPhase = false;
  bool _isDownPhase = true;
  bool _isFormCorrectForCurrentRep = true;
  double _previousAngle = 0.0;
  double _previousWristY = 0.0;
  double _previousElbowY = 0.0;
  double _previousShoulderY = 0.0;
  double _previousHeelY = 0.0;
  int _consecutiveGoodFrames = 0;

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
    _restSeconds = 60;
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0 && mounted) {
        setState(() => _restSeconds--);
      } else {
        timer.cancel();
        if (mounted) setState(() => _isRestPeriod = false);
      }
    });
  }

  void _startPoseDetection() {
    if (_cameraController == null) return;
    _cameraController!.startImageStream((CameraImage image) {
      if (_isDetecting || _workoutCompleted || _isRestPeriod || !mounted) return;
      _isDetecting = true;
      _processCameraImage(image);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        if (mounted) _isDetecting = false;
        return;
      }
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty && mounted) {
        _analyzePose(poses.first);
      } else if (mounted) {
        setState(() {
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
        _analyzeHipHinge(pose);
        break;
      case MotionType.horizontalPress:
        _analyzeBenchPress(pose);
        break;
      case MotionType.verticalPress:
        _analyzeShoulderPress(pose);
        break;
      case MotionType.horizontalPull:
        _analyzeRows(pose);
        break;
      case MotionType.shoulderElevation:
        _analyzeShrugs(pose);
        break;
      case MotionType.legExtension:
        _analyzeCalfRaises(pose);
        break;
      case MotionType.torsoRotation:
        _analyzeTorsoRotation(pose);
        break;
      case MotionType.lateralBend:
        _analyzeSideBends(pose);
        break;
      case MotionType.coreFlexion:
        _analyzeSitups(pose);
        break;
      case MotionType.shoulderArc:
        _analyzePullovers(pose);
        break;
      case MotionType.lateralRaise:
        _analyzeLateralRaises(pose);
        break;
      default:
        _analyzeGenericMovement(pose);
        break;
    }
  }

  // --- ANALYZER FUNCTIONS ---

  void _analyzeBicepCurl(Pose pose, MotionType motionType) {
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow] ?? pose.landmarks[PoseLandmarkType.rightElbow];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist] ?? pose.landmarks[PoseLandmarkType.rightWrist];
    if (shoulder == null || elbow == null || wrist == null) return;
    final elbowStability = (elbow.x - shoulder.x).abs() < 0.1;
    if (!elbowStability) {
      _updateFormStatus("Keep elbows stable", Colors.orange);
      _isFormCorrectForCurrentRep = false;
      return;
    }
    final angle = _calculateAngle(shoulder, elbow, wrist);
    if (angle < 40 && !_isUpPhase && _previousAngle > 60) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    } else if (angle > 140 && !_isDownPhase && _previousAngle < 120) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    }
    _previousAngle = angle;
  }

  void _analyzeTricepsExtension(Pose pose) {
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow] ?? pose.landmarks[PoseLandmarkType.rightElbow];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist] ?? pose.landmarks[PoseLandmarkType.rightWrist];
    if (shoulder == null || elbow == null || wrist == null) return;
    if (elbow.y > shoulder.y) {
      _updateFormStatus("Keep elbow up", Colors.orange);
      _isFormCorrectForCurrentRep = false;
      return;
    }
    final angle = _calculateAngle(shoulder, elbow, wrist);
    if (angle > 160 && !_isDownPhase && _previousAngle < 140) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    } else if (angle < 90 && !_isUpPhase && _previousAngle > 110) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    }
    _previousAngle = angle;
  }

  void _analyzeSquat(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee] ?? pose.landmarks[PoseLandmarkType.rightKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle] ?? pose.landmarks[PoseLandmarkType.rightAnkle];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    if (hip == null || knee == null || ankle == null || shoulder == null) return;
    final kneeAngle = _calculateAngle(hip, knee, ankle);
    final backAngle = _calculateAngle(shoulder, hip, knee);
    if (backAngle < 160) {
      _updateFormStatus("Keep back straight", Colors.orange);
      _isFormCorrectForCurrentRep = false;
    }
    if (kneeAngle > 160 && !_isDownPhase && _previousAngle < 140) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    } else if (kneeAngle < 100 && !_isUpPhase && _previousAngle > 120) {
      if (backAngle >= 160) {
        _isUpPhase = true;
        _isDownPhase = false;
        _isFormCorrectForCurrentRep = true;
      }
    }
    _previousAngle = kneeAngle;
  }

  void _analyzeHipHinge(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    final hip = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee] ?? pose.landmarks[PoseLandmarkType.rightKnee];
    if (shoulder == null || hip == null || knee == null) return;
    final hipAngle = _calculateAngle(shoulder, hip, knee);
    if (hipAngle > 160 && !_isDownPhase) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    } else if (hipAngle < 90 && !_isUpPhase) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    }
  }

  void _analyzeBenchPress(Pose pose) {
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow] ?? pose.landmarks[PoseLandmarkType.rightElbow];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist] ?? pose.landmarks[PoseLandmarkType.rightWrist];
    final hip = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee] ?? pose.landmarks[PoseLandmarkType.rightKnee];
    if (shoulder == null || elbow == null || wrist == null || hip == null || knee == null) return;
    final angle = _calculateAngle(shoulder, elbow, wrist);
    if (angle < 90 && !_isDownPhase) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    } else if (angle > 160 && !_isUpPhase) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    }
    _previousAngle = angle;
  }

  void _analyzeShoulderPress(Pose pose) {
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow] ?? pose.landmarks[PoseLandmarkType.rightElbow];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist] ?? pose.landmarks[PoseLandmarkType.rightWrist];
    if (shoulder == null || elbow == null || wrist == null) return;
    final angle = _calculateAngle(shoulder, elbow, wrist);
    if (angle < 80 && !_isDownPhase) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    } else if (angle > 160 && !_isUpPhase) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    }
    _previousAngle = angle;
  }

  void _analyzeRows(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow] ?? pose.landmarks[PoseLandmarkType.rightElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist] ?? pose.landmarks[PoseLandmarkType.rightWrist];
    final hip = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee] ?? pose.landmarks[PoseLandmarkType.rightKnee];
    if (shoulder == null || elbow == null || wrist == null || hip == null || knee == null) return;
    if (wrist.y < hip.y && !_isUpPhase) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    } else if (wrist.y > hip.y + 0.1 && !_isDownPhase) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    }
    _previousWristY = wrist.y;
  }

  void _analyzeShrugs(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    if (shoulder == null) return;
    if (shoulder.y < _previousShoulderY - 0.05 && !_isUpPhase) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    } else if (shoulder.y > _previousShoulderY && !_isDownPhase) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    }
    _previousShoulderY = shoulder.y;
  }

  void _analyzeCalfRaises(Pose pose) {
    final heel = pose.landmarks[PoseLandmarkType.leftHeel] ?? pose.landmarks[PoseLandmarkType.rightHeel];
    if (heel == null) return;
    if (heel.y < _previousHeelY - 0.05 && !_isUpPhase) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    } else if (heel.y > _previousHeelY && !_isDownPhase) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    }
    _previousHeelY = heel.y;
  }

  void _analyzeTorsoRotation(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    if (leftShoulder == null || rightShoulder == null) return;
    if (leftShoulder.x < rightShoulder.x - 0.1 && !_isUpPhase) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    } else if (leftShoulder.x > rightShoulder.x && !_isDownPhase) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    }
  }

  void _analyzeSideBends(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    final hip = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];
    if (shoulder == null || hip == null) return;
    if ((shoulder.x - hip.x).abs() > 0.1 && !_isUpPhase) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    } else if ((shoulder.x - hip.x).abs() < 0.05 && !_isDownPhase) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    }
  }

  void _analyzeSitups(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    final hip = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee] ?? pose.landmarks[PoseLandmarkType.rightKnee];
    if (shoulder == null || hip == null || knee == null) return;
    final angle = _calculateAngle(shoulder, hip, knee);
    if (angle < 90 && !_isUpPhase) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    } else if (angle > 160 && !_isDownPhase) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    }
  }

  void _analyzePullovers(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow] ?? pose.landmarks[PoseLandmarkType.rightElbow];
    final hip = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];
    if (shoulder == null || elbow == null || hip == null) return;
    final angle = _calculateAngle(elbow, shoulder, hip);
    if (angle > 160 && !_isUpPhase) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    } else if (angle < 90 && !_isDownPhase) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    }
  }

  void _analyzeLateralRaises(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow] ?? pose.landmarks[PoseLandmarkType.rightElbow];
    if (shoulder == null || elbow == null) return;
    if (elbow.y < shoulder.y && !_isUpPhase) {
      _isUpPhase = true;
      _isDownPhase = false;
      _isFormCorrectForCurrentRep = true;
    } else if (elbow.y > shoulder.y && !_isDownPhase) {
      if (_isFormCorrectForCurrentRep) _countRep();
      _isDownPhase = true;
      _isUpPhase = false;
    }
    _previousElbowY = elbow.y;
  }

  void _analyzeGenericMovement(Pose pose) {
    _isFormCorrectForCurrentRep = true;
    if (_isDownPhase) {
      _isUpPhase = true;
      _isDownPhase = false;
      if (_isFormCorrectForCurrentRep) _countRep();
    } else {
      _isUpPhase = false;
      _isDownPhase = true;
    }
  }

  // --- Core Logic ---
  void _countRep() {
    if (_workoutCompleted || _isRestPeriod) return;
    final now = DateTime.now();
    if (_lastRepTime != null && now.difference(_lastRepTime!).inMilliseconds < 1000) return;
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
    _isUpPhase = false;
    _isDownPhase = true;
    _isFormCorrectForCurrentRep = true;
    setState(() {
      _isRestPeriod = true;
      _currentSet++;
      _repCount = 0;
    });
    _updateFormStatus("Set completed! Rest period", Colors.yellow);
    _startRestTimer();
  }

  void _completeWorkout() {
    if (mounted) setState(() => _showSuccessAnimation = true);
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    if (widget.onExerciseCompleted != null) widget.onExerciseCompleted!(true, widget.exercise);
    _saveWorkoutData();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _saveWorkoutData() async {
    try {
      await http.post(
        Uri.parse('http://192.168.100.78/repEatApi/save_workout_session.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'exercise': widget.exercise,
          'completed_reps': widget.reps * widget.sets,
          'target_reps': widget.reps * widget.sets,
          'duration_seconds': _durationSeconds,
          'date': DateTime.now().toIso8601String(),
          'plan_day': widget.planDay,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Could not save workout data: $e");
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
      _isRestPeriod = false;
      _isUpPhase = false;
      _isDownPhase = true;
      _isFormCorrectForCurrentRep = true;
      _formStatus = "Workout restarted!";
      _formStatusColor = Colors.white;
      _previousAngle = 0.0;
      _consecutiveGoodFrames = 0;
    });
    _startWorkoutTimer();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream().catchError((e) => debugPrint("Error: $e"));
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
          // This ensures the camera preview is not stretched and fills the screen.
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize!.height,
              height: _cameraController!.value.previewSize!.width,
              child: CameraPreview(_cameraController!),
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
            child: Row(mainAxisSize: MainAxisSize.min, children: [
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
            ]),
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
                    onPressed: () => setState(() => _isRestPeriod = false),
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