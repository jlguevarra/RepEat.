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
  late PoseDetector _poseDetector;
  bool isBusy = false;
  int repCount = 0;
  bool isDownPosition = false;
  bool _isDisposed = false;
  String? _errorMessage;
  bool _isInitializing = true;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      WidgetsFlutterBinding.ensureInitialized();
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras found on this device');
      }

      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw Exception('Camera permission not granted');
      }

      final camera = _cameras!.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (!_cameraController!.value.isInitialized) {
        throw Exception('Failed to initialize camera');
      }

      _cameraController!.startImageStream((CameraImage image) {
        if (!isBusy && !_isDisposed) {
          isBusy = true;
          _processCameraImage(image);
        }
      });

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isInitializing = false;
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final inputImage = _convertCameraImage(image);
      final poses = await _poseDetector.processImage(inputImage);
      if (!_isDisposed) {
        _countRepsLogic(poses);
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      if (!_isDisposed) {
        isBusy = false;
      }
    }
  }

  InputImage _convertCameraImage(CameraImage image) {
    final BytesBuilder bytesBuilder = BytesBuilder();
    for (final Plane plane in image.planes) {
      bytesBuilder.add(plane.bytes);
    }
    final bytes = bytesBuilder.toBytes();


    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.yuv_420_888,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  void _countRepsLogic(List<Pose> poses) {
    if (poses.isEmpty || _isDisposed) return;

    final pose = poses.first;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder != null &&
        leftHip != null &&
        rightShoulder != null &&
        rightHip != null) {
      final diff = ((leftShoulder.y - leftHip.y).abs() +
          (rightShoulder.y - rightHip.y).abs()) /
          2;

      if (diff < 50) {
        isDownPosition = true;
      }

      if (diff > 100 && isDownPosition) {
        setState(() => repCount++);
        isDownPosition = false;
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 64, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Camera initialization failed',
              style: const TextStyle(fontSize: 18, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Retry Camera',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing Camera...'),
            ],
          ),
        ),
      );
    }

    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return _buildErrorScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Rep Counter'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Text(
                    '$repCount',
                    style: const TextStyle(
                      fontSize: 80,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'REPS COUNTED',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          blurRadius: 5,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => repCount = 0),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
