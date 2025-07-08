import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraWorkoutScreen extends StatefulWidget {
  const CameraWorkoutScreen({super.key});

  @override
  State<CameraWorkoutScreen> createState() => _CameraWorkoutScreenState();
}

class _CameraWorkoutScreenState extends State<CameraWorkoutScreen> {
  CameraController? _cameraController;
  late final PoseDetector _poseDetector;
  List<Pose> _poses = [];
  bool _isBusy = false;
  bool _isDown = false;
  bool _isWorkoutStarted = false;
  bool _isCameraInitialized = false;
  bool _hasError = false;

  int _repCount = 0;
  int _setCount = 1;
  int _targetReps = 0;
  int _targetSets = 0;

  Size? _imageSize;
  Timer? _timer;
  int _seconds = 0;

  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() => _hasError = true);
        return;
      }

      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      setState(() {
        _imageSize = Size(
          _cameraController!.value.previewSize!.height,
          _cameraController!.value.previewSize!.width,
        );
        _isCameraInitialized = true;
      });

      _cameraController!.startImageStream(_processCameraFrame);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      setState(() => _hasError = true);
      _showErrorSnackbar('Failed to initialize camera');
    }
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    if (!_isBusy && _isWorkoutStarted && mounted) {
      _isBusy = true;

      try {
        final bytes = _concatenatePlanes(image.planes);
        final inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation270deg,
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes.first.bytesPerRow,
          ),
        );

        final poses = await _poseDetector.processImage(inputImage);
        if (mounted) {
          setState(() => _poses = poses);
          _countRepsLogic(poses);
        }
      } catch (e) {
        debugPrint('Image processing error: $e');
      } finally {
        _isBusy = false;
      }
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final bytesBuilder = BytesBuilder();
    for (final plane in planes) {
      bytesBuilder.add(plane.bytes);
    }
    return bytesBuilder.toBytes();
  }

  void _countRepsLogic(List<Pose> poses) {
    if (poses.isEmpty) return;

    final pose = poses.first;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];

    if (leftShoulder != null && leftHip != null) {
      final diff = (leftShoulder.y - leftHip.y).abs();

      if (diff < 50) {
        _isDown = true;
      }

      if (diff > 100 && _isDown) {
        setState(() => _repCount++);
        _isDown = false;

        if (_repCount >= _targetReps) {
          if (_setCount >= _targetSets) {
            _completeWorkout();
          } else {
            setState(() {
              _setCount++;
              _repCount = 0;
            });
            _showSuccessSnackbar('Set $_setCount started!');
          }
        }
      }
    }
  }

  void _startWorkout() {
    if (_setsController.text.isEmpty || _repsController.text.isEmpty) {
      _showErrorSnackbar('Please enter sets and reps');
      return;
    }

    setState(() {
      _targetSets = int.tryParse(_setsController.text) ?? 0;
      _targetReps = int.tryParse(_repsController.text) ?? 0;
      _repCount = 0;
      _setCount = 1;
      _seconds = 0;
      _isWorkoutStarted = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  void _completeWorkout() {
    _timer?.cancel();
    setState(() => _isWorkoutStarted = false);
    _showSuccessSnackbar('Workout completed!');
    Navigator.pop(context, {
      'sets': _setCount,
      'reps': _repCount,
      'duration': _seconds,
    });
  }

  void _cancelWorkout() {
    _timer?.cancel();
    Navigator.pop(context);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String get _formattedTime {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    _timer?.cancel();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera Error')),
        body: const Center(
          child: Text('Failed to initialize camera. Please check permissions.'),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Camera'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),

          if (_isWorkoutStarted)
            CustomPaint(
              painter: PosePainter(
                _poses,
                imageSize: _imageSize!,
                isFrontCamera: true,
              ),
              size: screenSize,
            ),

          if (!_isWorkoutStarted)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildInputField('Sets', _setsController),
                        const SizedBox(height: 16),
                        _buildInputField('Reps per Set', _repsController),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _startWorkout,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text('Start Workout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Workout Info Overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBox('Time', _formattedTime),
                _buildInfoBox('Set', '$_setCount/$_targetSets'),
                _buildInfoBox('Reps', '$_repCount/$_targetReps'),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _cancelWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
                if (_isWorkoutStarted)
                  ElevatedButton(
                    onPressed: _completeWorkout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Complete'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final bool isFrontCamera;

  PosePainter(this.poses, {
    required this.imageSize,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size screenSize) {
    final paint = Paint()
      ..strokeWidth = 4
      ..color = Colors.greenAccent;

    for (final pose in poses) {
      // Draw landmarks
      for (final landmark in pose.landmarks.values) {
        final point = _translate(landmark, screenSize);
        canvas.drawCircle(point, 6, paint);
      }

      // Draw connections
      void drawLine(PoseLandmarkType type1, PoseLandmarkType type2) {
        final point1 = pose.landmarks[type1];
        final point2 = pose.landmarks[type2];
        if (point1 != null && point2 != null) {
          canvas.drawLine(
            _translate(point1, screenSize),
            _translate(point2, screenSize),
            paint,
          );
        }
      }

      // Upper body
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

      // Core
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

      // Lower body
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    }
  }

  Offset _translate(PoseLandmark landmark, Size screenSize) {
    final scaleX = screenSize.width / imageSize.height;
    final scaleY = screenSize.height / imageSize.width;

    double x = landmark.y * scaleX;
    double y = landmark.x * scaleY;

    if (isFrontCamera) {
      x = screenSize.width - x;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}