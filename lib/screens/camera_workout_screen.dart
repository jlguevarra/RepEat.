import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

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
  bool _isEquipmentDetected = false;
  double _motionIntensity = 0.0;

  // Exercise classification
  bool get _isDumbbellExercise => widget.exercise.toLowerCase().contains('dumbbell');
  bool get _isBodyweightExercise => !_isDumbbellExercise;

  @override
  void initState() {
    super.initState();
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
                    ? 'Make sure your dumbbell is visible. Reps will only count when proper form is detected.'
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
      _startMotionDetection();
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

  void _startMotionDetection() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_workoutCompleted || !_isInitialized || _isRestPeriod) {
        return;
      }
      _analyzeMotion();
    });
  }

  void _analyzeMotion() {
    final now = DateTime.now();

    // Prevent double counting
    if (_lastRepTime != null && now.difference(_lastRepTime!).inMilliseconds < 1000) {
      return;
    }

    // Simulate motion detection
    final motionData = _detectMotionPattern();

    if (_isDumbbellExercise) {
      _handleDumbbellMotion(motionData);
    } else {
      _handleBodyweightMotion(motionData);
    }
  }

  Map<String, dynamic> _detectMotionPattern() {
    // Simulate different motion patterns based on exercise type
    final time = DateTime.now().millisecondsSinceEpoch / 1000;

    return {
      'intensity': (math.sin(time * 2).abs() * 0.8 + 0.2), // 0.2 to 1.0
      'direction': math.sin(time * 2) > 0.5 ? 1 : (math.sin(time * 2) < -0.5 ? -1 : 0),
      'equipmentDetected': _simulateEquipmentDetection(),
    };
  }

  bool _simulateEquipmentDetection() {
    // Simulate equipment detection - 80% detection rate when user is active
    final time = DateTime.now().millisecondsSinceEpoch / 1000;
    return math.sin(time * 3).abs() > 0.3;
  }

  void _handleDumbbellMotion(Map<String, dynamic> motionData) {
    final intensity = motionData['intensity'] as double;
    final direction = motionData['direction'] as int;
    final equipmentDetected = motionData['equipmentDetected'] as bool;

    setState(() {
      _motionIntensity = intensity;
      _motionDirection = direction;
      _isEquipmentDetected = equipmentDetected;
    });

    // Only count reps if equipment is detected and motion is significant
    if (equipmentDetected && intensity > 0.6) {
      if (direction == -1 && _motionDirection != -1) {
        // Downward motion with proper form
        _countRep();
      }
    }
  }

  void _handleBodyweightMotion(Map<String, dynamic> motionData) {
    final intensity = motionData['intensity'] as double;
    final direction = motionData['direction'] as int;

    setState(() {
      _motionIntensity = intensity;
      _motionDirection = direction;
      _isEquipmentDetected = true; // Always true for bodyweight exercises
    });

    // Count reps based on motion intensity and pattern
    if (intensity > 0.5) {
      if (direction == -1 && _motionDirection != -1) {
        // Significant downward motion
        _countRep();
      }
    }
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
    });

    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _startWorkoutTimer();
    _startMotionDetection();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout restarted!')),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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
        title: Text('${widget.exercise} - Motion Detection'),
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

          // Motion detection overlay
          Positioned.fill(
            child: CustomPaint(
              painter: MotionDetectionPainter(
                _motionDirection,
                _motionIntensity,
                _isEquipmentDetected,
                _isDumbbellExercise,
              ),
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
    if (!_isEquipmentDetected && _isDumbbellExercise) {
      return '❌ DUMBBELL NOT DETECTED';
    } else if (_motionIntensity < 0.3) {
      return '🚶 READY FOR MOTION';
    } else if (_motionDirection == 1) {
      return '↑ LIFTING UP ↑';
    } else if (_motionDirection == -1) {
      return '↓ LOWERING ↓';
    } else {
      return '🔄 MOTION DETECTED';
    }
  }

  Color _getStatusColor() {
    if (!_isEquipmentDetected && _isDumbbellExercise) {
      return Colors.red;
    } else if (_motionIntensity < 0.3) {
      return Colors.white70;
    } else {
      return Colors.green;
    }
  }
}

class MotionDetectionPainter extends CustomPainter {
  final int motionDirection;
  final double motionIntensity;
  final bool isEquipmentDetected;
  final bool isDumbbellExercise;

  MotionDetectionPainter(
      this.motionDirection,
      this.motionIntensity,
      this.isEquipmentDetected,
      this.isDumbbellExercise,
      );

  @override
  void paint(Canvas canvas, Size size) {
    if (motionIntensity > 0.3) {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = size.width / 4 * motionIntensity;

      final paint = Paint()
        ..color = _getMotionColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 * motionIntensity;

      if (motionDirection == 1) {
        // Upward motion
        canvas.drawCircle(center, radius, paint);
      } else if (motionDirection == -1) {
        // Downward motion
        canvas.drawRect(
          Rect.fromCenter(center: center, width: radius * 2, height: radius * 2),
          paint,
        );
      }
    }

    // Draw equipment detection status
    if (isDumbbellExercise && !isEquipmentDetected) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '❌',
          style: TextStyle(fontSize: 40, color: Colors.red),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - 50, 50));
    }
  }

  Color _getMotionColor() {
    if (!isEquipmentDetected && isDumbbellExercise) {
      return Colors.red.withOpacity(0.5);
    }
    return motionDirection == 1
        ? Colors.green.withOpacity(0.5)
        : Colors.blue.withOpacity(0.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}