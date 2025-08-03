import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';
import 'dart:ui';

bool isDumbbellCurlRep({
  required Pose pose,
  required bool isDownPosition,
  required Function onRepDetected,
}) {
  // Get relevant landmarks for right arm
  final wrist = pose.landmarks[PoseLandmarkType.rightWrist];
  final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
  final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

  // For hand detection, we'll use wrist and elbow as proxies
  // since finger landmarks aren't available in current ML Kit version
  final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

  // Check if all required landmarks are visible
  if (wrist == null || elbow == null || shoulder == null || rightHip == null) {
    return isDownPosition;
  }

  // Calculate arm angle
  final angle = _calculateAngle(shoulder, elbow, wrist);

  // Calculate hand position relative to hip as proxy for grip detection
  final isHandRaised = wrist.y < rightHip.y;

  // Down position (arms extended)
  if (!isDownPosition && angle > 160 && isHandRaised) {
    return true; // Ready to curl
  }

  // Up position (full curl)
  if (isDownPosition && angle < 45) {
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