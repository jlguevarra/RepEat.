import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final Pose? pose;
  final Size previewSize;
  final Paint jointPaint;
  final Paint linePaint;

  PosePainter(this.pose, this.previewSize)
      : jointPaint = Paint()
    ..color = Colors.red
    ..strokeWidth = 8.0
    ..style = PaintingStyle.fill,
        linePaint = Paint()
          ..color = Colors.green
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (pose == null) return;

    // Calculate proper scaling and offset
    final scale = _calculateScale(size);
    final offset = _calculateOffset(size, scale);

    // Draw connections
    for (final line in _getPoseLines()) {
      final start = pose!.landmarks[line.$1];
      final end = pose!.landmarks[line.$2];
      if (start != null && end != null) {
        canvas.drawLine(
          _transformPoint(start, scale, offset, size),
          _transformPoint(end, scale, offset, size),
          linePaint,
        );
      }
    }

    // Draw joints
    for (final landmark in pose!.landmarks.values) {
      canvas.drawCircle(
        _transformPoint(landmark, scale, offset, size),
        6.0,
        jointPaint,
      );
    }
  }

  double _calculateScale(ui.Size canvasSize) {
    // Calculate scale to maintain aspect ratio
    final double widthScale = canvasSize.width / previewSize.height;
    final double heightScale = canvasSize.height / previewSize.width;
    return widthScale < heightScale ? widthScale : heightScale;
  }

  Offset _calculateOffset(ui.Size canvasSize, double scale) {
    // Center the preview in the canvas
    final double scaledWidth = previewSize.height * scale;
    final double scaledHeight = previewSize.width * scale;
    final double offsetX = (canvasSize.width - scaledWidth) / 2;
    final double offsetY = (canvasSize.height - scaledHeight) / 2;
    return Offset(offsetX, offsetY);
  }

  Offset _transformPoint(PoseLandmark landmark, double scale, Offset offset, ui.Size canvasSize) {
    // For front camera, we need to mirror the x-coordinate to match the preview
    // The preview is mirrored, so we mirror the landmark coordinates too
    final double mirroredX = previewSize.height - landmark.x;
    final double y = landmark.y;

    return Offset(
      offset.dx + mirroredX * scale,
      offset.dy + y * scale,
    );
  }

  List<(PoseLandmarkType, PoseLandmarkType)> _getPoseLines() {
    return [
      // Head
      (PoseLandmarkType.leftEar, PoseLandmarkType.leftEye),
      (PoseLandmarkType.rightEar, PoseLandmarkType.rightEye),
      (PoseLandmarkType.leftEye, PoseLandmarkType.nose),
      (PoseLandmarkType.rightEye, PoseLandmarkType.nose),

      // Torso
      (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
      (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
      (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
      (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),

      // Left arm
      (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
      (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
      (PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb),
      (PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex),

      // Right arm
      (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
      (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
      (PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb),
      (PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex),

      // Left leg
      (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
      (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
      (PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel),

      // Right leg
      (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
      (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
      (PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel),
    ];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}