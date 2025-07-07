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
  List<Pose> poses = [];

  bool isBusy = false;
  bool isDown = false;
  bool isWorkoutStarted = false;

  int repCount = 0;
  int setCount = 1;
  int targetReps = 0;
  int targetSets = 0;

  Size? imageSize;

  Timer? _timer;
  int _seconds = 0;

  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
  }

  Future<void> _initializeCamera() async {
    await Permission.camera.request();

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

    imageSize = Size(
      _cameraController!.value.previewSize!.height,
      _cameraController!.value.previewSize!.width,
    );

    _cameraController!.startImageStream((image) {
      if (!isBusy && isWorkoutStarted) {
        isBusy = true;
        _processCameraImage(image);
      }
    });

    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final bytes = _concatenatePlanes(image.planes);
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg, // ✅ Portrait
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final result = await _poseDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          poses = result;
        });
      }

      _countRepsLogic(result);
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      isBusy = false;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final bytesBuilder = BytesBuilder();
    for (final plane in planes) {
      bytesBuilder.add(plane.bytes);
    }
    return bytesBuilder.toBytes();
  }

  void _countRepsLogic(List<Pose> result) {
    if (result.isEmpty) return;

    final pose = result.first;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];

    if (leftShoulder != null && leftHip != null) {
      final diff = (leftShoulder.y - leftHip.y).abs();

      if (diff < 50) {
        isDown = true;
      }

      if (diff > 100 && isDown) {
        setState(() {
          repCount++;
        });

        isDown = false;

        if (repCount >= targetReps) {
          if (setCount >= targetSets) {
            _endWorkout();
          } else {
            setState(() {
              setCount++;
              repCount = 0;
            });
          }
        }
      }
    }
  }

  void _startWorkout() {
    if (setsController.text.isEmpty || repsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter sets and reps")),
      );
      return;
    }

    setState(() {
      targetSets = int.parse(setsController.text);
      targetReps = int.parse(repsController.text);
      repCount = 0;
      setCount = 1;
      _seconds = 0;
      isWorkoutStarted = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _endWorkout() {
    _timer?.cancel();
    setState(() {
      isWorkoutStarted = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout Completed!')),
    );

    Navigator.pop(context);
  }

  void _cancelWorkout() {
    _timer?.cancel();
    setState(() {
      isWorkoutStarted = false;
      repCount = 0;
      setCount = 1;
      _seconds = 0;
    });
    Navigator.pop(context);
  }

  String get formattedTime {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    _timer?.cancel();
    setsController.dispose();
    repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Camera'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _cameraController == null ||
          !_cameraController!.value.isInitialized ||
          imageSize == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          CameraPreview(_cameraController!),

          if (isWorkoutStarted)
            CustomPaint(
              painter: PosePainter(
                poses,
                imageSize: imageSize!,
                isFrontCamera: true,
              ),
              size: screenSize,
            ),

          if (!isWorkoutStarted)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _inputField('Sets', setsController),
                      const SizedBox(height: 16),
                      _inputField('Reps per Set', repsController),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _startWorkout,
                        child: const Text('Start Workout'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Timer
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                formattedTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          // Rep Counter
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Set: $setCount/$targetSets  |  Reps: $repCount/$targetReps',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          // Bottom Buttons
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _cancelWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _endWorkout,
                  child: const Text('Complete'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white54),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final bool isFrontCamera;

  PosePainter(
      this.poses, {
        required this.imageSize,
        this.isFrontCamera = true,
      });

  @override
  void paint(Canvas canvas, Size screenSize) {
    final paint = Paint()
      ..strokeWidth = 4
      ..color = Colors.greenAccent;

    for (var pose in poses) {
      for (var landmark in pose.landmarks.values) {
        final point = _translate(landmark, screenSize);
        canvas.drawCircle(point, 6, paint);
      }

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

      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    }
  }

  Offset _translate(PoseLandmark landmark, Size screenSize) {
    final double scaleX = screenSize.width / imageSize.height;
    final double scaleY = screenSize.height / imageSize.width;

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
