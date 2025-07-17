import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

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
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    for (final pose in poses) {
      // Draw landmarks
      for (final landmark in pose.landmarks.values) {
        final point = _translate(landmark, size);
        canvas.drawCircle(point, 6, paint);
      }

      // Draw connections
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

      // Upper body connections
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

      // Core connections
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

      // Lower body connections
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    }
  }

  Offset _translate(PoseLandmark landmark, Size size) {
    final scaleX = size.width / imageSize.height;
    final scaleY = size.height / imageSize.width;

    double x = landmark.y * scaleX;
    double y = landmark.x * scaleY;

    if (isFrontCamera) {
      x = size.width - x;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}