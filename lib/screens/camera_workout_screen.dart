import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'pose_painter.dart';

class CameraWorkoutScreen extends StatefulWidget {
  final int userId;
  final String category;
  final String exercise;

  const CameraWorkoutScreen({
    super.key,
    required this.userId,
    required this.category,
    required this.exercise,
  });

  @override
  State<CameraWorkoutScreen> createState() => _CameraWorkoutScreenState();
}

class _CameraWorkoutScreenState extends State<CameraWorkoutScreen> {
  CameraController? _cameraController;
  late PoseDetector _poseDetector;
  bool _isBusy = false;
  int _repCount = 0;
  bool _isDown = false;
  Size? _imageSize;
  List<Pose> _poses = [];
  bool _isFrontCamera = true;
  bool _isInitialized = false;
  String _feedback = '';
  double _accuracyScore = 0;
  Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();

    setState(() {
      _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
      _imageSize = Size(
        _cameraController!.value.previewSize!.height,
        _cameraController!.value.previewSize!.width,
      );
      _isInitialized = true;
    });

    _cameraController!.startImageStream(_processCameraImage);
    _stopwatch.start();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || !mounted) return;
    _isBusy = true;

    try {
      final inputImage = InputImage.fromBytes(
        bytes: _concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _isFrontCamera ? InputImageRotation.rotation270deg : InputImageRotation.rotation90deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final poses = await _poseDetector.processImage(inputImage);
      if (mounted) {
        setState(() {
          _poses = poses;
        });
        _analyzePushUpPose(poses);
      }
    } catch (e) {
      debugPrint('Pose detection error: $e');
    } finally {
      _isBusy = false;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final buffer = BytesBuilder();
    for (final plane in planes) {
      buffer.add(plane.bytes);
    }
    return buffer.toBytes();
  }

  void _analyzePushUpPose(List<Pose> poses) {
    if (poses.isEmpty) return;

    final pose = poses.first;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if ([leftShoulder, rightShoulder, leftElbow, rightElbow, leftHip, rightHip].any((l) => l == null)) {
      _feedback = 'Ensure full body is visible';
      return;
    }

    final shoulderY = (leftShoulder!.y + rightShoulder!.y) / 2;
    final hipY = (leftHip!.y + rightHip!.y) / 2;
    final elbowAngle = _calculateAngle(leftShoulder, leftElbow!, leftHip);

    // Check if form is correct
    if (elbowAngle < 70) {
      _feedback = 'Too low. Push up!';
      _isDown = true;
    } else if (elbowAngle > 160) {
      if (_isDown) {
        _repCount++;
        _isDown = false;
      }
      _feedback = 'Good Form';
    } else {
      _feedback = 'Lower more';
    }

    // Estimate accuracy
    _accuracyScore = elbowAngle.clamp(70, 160) / 180;
  }

  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);

    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final abMag = sqrt(ab.dx * ab.dx + ab.dy * ab.dy);
    final cbMag = sqrt(cb.dx * cb.dx + cb.dy * cb.dy);
    final cosine = dot / (abMag * cbMag);
    return acos(cosine) * (180 / pi);
  }

  Future<void> _saveWorkout() async {
    final url = Uri.parse('http://192.168.0.11/repEatApi/camera_workout_screen.php');
    final data = {
      'user_id': widget.userId,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'category': widget.category,
      'exercise_name': widget.exercise,
      'detected_reps': _repCount,
      'duration_seconds': _stopwatch.elapsed.inSeconds,
      'accuracy_score': double.parse(_accuracyScore.toStringAsFixed(2)),
    };

    try {
      final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));

      setState(() {
        _repCount = 0;
        _feedback = '';
        _accuracyScore = 0;
      });

      final result = jsonDecode(res.body);



      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Workout Saved')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${result['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Push-Up Counter'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveWorkout)
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
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  '$_repCount',
                  style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text('Reps Counted', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                Text(
                  _feedback,
                  style: const TextStyle(color: Colors.yellowAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  'Accuracy: ${(_accuracyScore * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white70),
                )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => setState(() => _repCount = 0),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
