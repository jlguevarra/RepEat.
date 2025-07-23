import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';
import 'dart:ui';

bool isConcentrationCurlRep({
  required Pose pose,
  required bool isDownPosition,
  required Function onRepDetected,
}) {
  final wrist = pose.landmarks[PoseLandmarkType.rightWrist];
  final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
  final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

  if (wrist == null || elbow == null || shoulder == null) return isDownPosition;

  final wristY = wrist.y;
  final elbowY = elbow.y;
  final shoulderY = shoulder.y;

  final angle = _calculateAngle(shoulder, elbow, wrist);

  // Down position
  if (!isDownPosition && wristY > elbowY + 30 && angle > 150) {
    return true; // Ready to curl
  }

  // Curl up and count
  if (isDownPosition && wristY < elbowY - 20 && angle < 60) {
    onRepDetected();
    return false; // Reset for next rep
  }

  return isDownPosition;
}

double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
  final ab = Offset(a.x - b.x, a.y - b.y);
  final cb = Offset(c.x - b.x, c.y - b.y);

  final dot = ab.dx * cb.dx + ab.dy * cb.dy;
  final magAB = sqrt(ab.dx * ab.dx + ab.dy * ab.dy);
  final magCB = sqrt(cb.dx * cb.dx + cb.dy * cb.dy);

  final angle = acos(dot / (magAB * magCB));
  return angle * (180 / pi);
}
