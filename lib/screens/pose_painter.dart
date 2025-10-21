import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

// MODIFIED: Added enum to define which side the connection is on
enum PoseSide { left, right, center }

class PosePainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  final Paint jointPaint;
  final Paint leftPaint;
  final Paint rightPaint;
  final Paint centerPaint;

  // Smoothing variables
  static final Map<PoseLandmarkType, Offset> _previousPositions = {};
  static final Map<PoseLandmarkType, double> _motionHistory = {};
  final double _smoothingFactor = 0.3;
  final double _motionThreshold = 8.0;

  PosePainter(
      this.pose,
      this.imageSize,
      this.rotation,
      this.cameraLensDirection,
      )   : jointPaint = Paint()
    ..color = Colors.red
    ..strokeWidth = 6.0
    ..style = PaintingStyle.fill,
        leftPaint = Paint()
          ..color = Colors.yellow
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke,
        rightPaint = Paint()
          ..color = Colors.blueAccent
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke,
        centerPaint = Paint()
          ..color = Colors.green
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke;

  @override
  void paint(ui.Canvas canvas, ui.Size canvasSize) {
    if (pose == null) return;

    // MODIFIED: Define paints based on camera direction
    final Paint paintLeft;
    final Paint paintRight;

    if (cameraLensDirection == CameraLensDirection.front) {
      // Swap paints for front camera to match screen orientation
      // User's left (e.g., leftShoulder) is on the right side of the screen.
      // We want the right side of the screen to be blue.
      paintLeft = this.rightPaint; // User's left side -> draw with blue
      paintRight = this.leftPaint; // User's right side -> draw with yellow
    } else {
      // Use default for back camera
      paintLeft = this.leftPaint;
      paintRight = this.rightPaint;
    }

    // Draw all landmarks first
    for (final landmark in pose!.landmarks.values) {
      final offset = _transformPoint(landmark, canvasSize);
      canvas.drawCircle(offset, 4.0, jointPaint);
    }

    // MODIFIED: Draw pose lines using the correct screen-oriented paint
    for (final connection in _poseConnections) {
      final startLandmark = pose!.landmarks[connection.start];
      final endLandmark = pose!.landmarks[connection.end];

      if (startLandmark != null && endLandmark != null) {
        final startOffset = _transformPoint(startLandmark, canvasSize);
        final endOffset = _transformPoint(endLandmark, canvasSize);

        // Select paint based on connection side
        Paint linePaint;
        switch (connection.side) {
          case PoseSide.left:
            linePaint = paintLeft;
            break;
          case PoseSide.right:
            linePaint = paintRight;
            break;
          case PoseSide.center:
            linePaint = centerPaint;
            break;
        }

        canvas.drawLine(startOffset, endOffset, linePaint);
      }
    }
  }

  Offset _transformPoint(PoseLandmark landmark, ui.Size canvasSize) {
    final double x = translateX(
      landmark.x,
      canvasSize,
      imageSize,
      rotation,
      cameraLensDirection,
    );

    final double y = translateY(
      landmark.y,
      canvasSize,
      imageSize,
      rotation,
      cameraLensDirection,
    );

    return _smoothPoint(landmark.type, Offset(x, y));
  }

  // Coordinate translation functions from reference file
  double translateX(
      double x,
      Size canvasSize,
      Size imageSize,
      InputImageRotation rotation,
      CameraLensDirection cameraLensDirection,
      ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * canvasSize.width / imageSize.height;
      case InputImageRotation.rotation270deg:
        return canvasSize.width - x * canvasSize.width / imageSize.height;
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        switch (cameraLensDirection) {
          case CameraLensDirection.back:
            return x * canvasSize.width / imageSize.width;
          default:
            return canvasSize.width - x * canvasSize.width / imageSize.width;
        }
    }
  }

  double translateY(
      double y,
      Size canvasSize,
      Size imageSize,
      InputImageRotation rotation,
      CameraLensDirection cameraLensDirection,
      ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * canvasSize.height / imageSize.width;
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return y * canvasSize.height / imageSize.height;
    }
  }

  Offset _smoothPoint(PoseLandmarkType type, Offset current) {
    final previous = _previousPositions[type];

    if (previous == null) {
      _previousPositions[type] = current;
      _motionHistory[type] = 0.0;
      return current;
    }

    final double dxDiff = (current.dx - previous.dx).abs();
    final double dyDiff = (current.dy - previous.dy).abs();
    final double motionSpeed = (dxDiff + dyDiff) / 2;

    _motionHistory[type] = (_motionHistory[type] ?? 0.0) * 0.7 + motionSpeed * 0.3;

    double adaptiveSmoothing = _smoothingFactor;
    if (motionSpeed > _motionThreshold) {
      adaptiveSmoothing *= 0.5;
    } else if (motionSpeed < 2.0) {
      adaptiveSmoothing *= 1.5;
    }

    final smoothed = Offset(
      previous.dx + (current.dx - previous.dx) * (1 - adaptiveSmoothing),
      previous.dy + (current.dy - previous.dy) * (1 - adaptiveSmoothing),
    );

    _previousPositions[type] = smoothed;
    return smoothed;
  }

  static void clearSmoothing() {
    _previousPositions.clear();
    _motionHistory.clear();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// MODIFIED: Class now uses PoseSide enum instead of a Paint object
class PoseConnection {
  final PoseLandmarkType start;
  final PoseLandmarkType end;
  final PoseSide side;

  PoseConnection(this.start, this.end, this.side);
}

// MODIFIED: List now uses the PoseSide enum
final List<PoseConnection> _poseConnections = [
  // Face (center - green)
  PoseConnection(PoseLandmarkType.leftEye, PoseLandmarkType.nose, PoseSide.center),
  PoseConnection(PoseLandmarkType.nose, PoseLandmarkType.rightEye, PoseSide.center),
  PoseConnection(PoseLandmarkType.leftEar, PoseLandmarkType.leftEye, PoseSide.center),
  PoseConnection(PoseLandmarkType.rightEar, PoseLandmarkType.rightEye, PoseSide.center),
  PoseConnection(PoseLandmarkType.leftMouth, PoseLandmarkType.rightMouth, PoseSide.center),


  // Left arm (left)
  PoseConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseSide.left),
  PoseConnection(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, PoseSide.left),
  PoseConnection(PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky, PoseSide.left),
  PoseConnection(PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex, PoseSide.left),
  PoseConnection(PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb, PoseSide.left),

  // Right arm (right)
  PoseConnection(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, PoseSide.right),
  PoseConnection(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, PoseSide.right),
  PoseConnection(PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky, PoseSide.right),
  PoseConnection(PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex, PoseSide.right),
  PoseConnection(PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb, PoseSide.right),

  // Torso
  PoseConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseSide.center),
  PoseConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, PoseSide.left), // Left side of torso
  PoseConnection(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, PoseSide.right), // Right side of torso
  PoseConnection(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, PoseSide.center),

  // Left leg (left)
  PoseConnection(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseSide.left),
  PoseConnection(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, PoseSide.left),
  PoseConnection(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel, PoseSide.left),
  PoseConnection(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex, PoseSide.left),
  PoseConnection(PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex, PoseSide.left),


  // Right leg (right)
  PoseConnection(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, PoseSide.right),
  PoseConnection(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, PoseSide.right),
  PoseConnection(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel, PoseSide.right),
  PoseConnection(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex, PoseSide.right),
  PoseConnection(PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex, PoseSide.right),
];