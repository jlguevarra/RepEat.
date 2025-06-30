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
  int repCount = 0;

  Timer? timer;
  int secondsElapsed = 0;

  Size? imageSize;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        secondsElapsed++;
      });
    });
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
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();

    imageSize = Size(
      _cameraController!.value.previewSize!.height,
      _cameraController!.value.previewSize!.width,
    );

    _cameraController!.startImageStream((image) {
      if (!isBusy) {
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
          rotation: InputImageRotation.rotation90deg,
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

      // ✅ Rep counting logic example (based on shoulder-hip distance)
      if (result.isNotEmpty) {
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
          }
        }
      }
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

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    timer?.cancel();
    super.dispose();
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // ✅ Mirror the camera for front camera
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(3.1416),
            child: CameraPreview(_cameraController!),
          ),

          // ✅ Draw Skeleton
          if (imageSize != null)
            CustomPaint(
              painter: PosePainter(
                poses,
                imageSize: imageSize!,
                isFrontCamera: true,
              ),
              size: MediaQuery.of(context).size,
            ),

          // ✅ Timer
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                formatTime(secondsElapsed),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ✅ Workout counter
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reps: $repCount',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),

          // ✅ Bottom buttons
          Positioned(
            bottom: 20,
            left: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {},
              child: const Text('Complete'),
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

  PosePainter(this.poses,
      {required this.imageSize, this.isFrontCamera = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4
      ..color = Colors.greenAccent;

    for (var pose in poses) {
      for (var landmark in pose.landmarks.values) {
        final point = _translate(landmark, size);
        canvas.drawCircle(point, 6, paint);
      }

      void drawLine(PoseLandmarkType type1, PoseLandmarkType type2) {
        final point1 = pose.landmarks[type1];
        final point2 = pose.landmarks[type2];
        if (point1 != null && point2 != null) {
          canvas.drawLine(
            _translate(point1, size),
            _translate(point2, size),
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
