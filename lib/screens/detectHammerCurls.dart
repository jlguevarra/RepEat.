import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';
import 'dart:ui';

bool isHammerCurlRep({
  required Pose pose,
  required bool isDownPosition,
  required Function onRepDetected,
}) {
  final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
  final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
  final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

  if (leftWrist == null || leftElbow == null || leftShoulder == null) {
    return isDownPosition;
  }

  // Calculate vertical distances
  final wristY = leftWrist.y;
  final elbowY = leftElbow.y;
  final shoulderY = leftShoulder.y;

  // Angle at elbow
  final angle = _calculateAngle(leftShoulder, leftElbow, leftWrist);

  // Down position detection
  if (!isDownPosition && (wristY > elbowY + 40) && angle > 150) {
    return true; // Arm down, ready to curl
  }

  // Curl up detection
  if (isDownPosition && (wristY < elbowY - 30) && angle < 60) {
    onRepDetected(); // Trigger rep count
    return false; // Reset position
  }

  return isDownPosition;
}

double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
  final ab = Offset(a.x - b.x, a.y - b.y);
  final cb = Offset(c.x - b.x, c.y - b.y);

  final dotProduct = ab.dx * cb.dx + ab.dy * cb.dy;
  final magnitudeAB = sqrt(ab.dx * ab.dx + ab.dy * ab.dy);
  final magnitudeCB = sqrt(cb.dx * cb.dx + cb.dy * cb.dy);

  final angleRad = acos(dotProduct / (magnitudeAB * magnitudeCB));
  return angleRad * (180 / pi);
}
