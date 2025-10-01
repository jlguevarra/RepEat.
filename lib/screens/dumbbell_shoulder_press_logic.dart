// workout_logic/dumbbell_shoulder_press_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellShoulderPressLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null || rightShoulder == null ||
        leftElbow == null || rightElbow == null) {
      updateFormStatus("Ensure shoulders and elbows are visible", false);
      return "no_pose";
    }

    // Calculate average arm position
    final leftAngle = leftWrist != null ? _calculateAngle(leftShoulder, leftElbow, leftWrist) : 180.0;
    final rightAngle = rightWrist != null ? _calculateAngle(rightShoulder, rightElbow, rightWrist) : 180.0;
    final avgAngle = (leftAngle + rightAngle) / 2;

    // Check standing position
    if (!_isStandingPosition(pose)) {
      updateFormStatus("Stand upright with dumbbells at shoulders", false);
      return "not_standing";
    }

    return _analyzePressMovement(avgAngle, updateFormStatus);
  }

  static double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = (math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x)).abs();
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  static bool _isStandingPosition(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null) {
      return false;
    }

    final shoulderAlignment = (leftShoulder.y - rightShoulder.y).abs();
    return shoulderAlignment < 0.1;
  }

  static String _analyzePressMovement(double angle, Function(String, bool) updateFormStatus) {
    if (angle < 80) {
      updateFormStatus("Dumbbells at shoulders - press up", true);
      return "shoulder_position";
    } else if (angle >= 80 && angle < 120) {
      updateFormStatus("Pressing upward", true);
      return "pressing_up";
    } else if (angle >= 120 && angle < 160) {
      updateFormStatus("Almost there - push to full extension", true);
      return "near_extension";
    } else if (angle >= 160) {
      updateFormStatus("Arms fully extended! Lower with control", true);
      return "full_extension";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "full_extension" && currentState == "shoulder_position";
  }
}