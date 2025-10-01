// workout_logic/dumbbell_lunges_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellLungesLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || rightHip == null ||
        leftKnee == null || rightKnee == null) {
      updateFormStatus("Ensure legs are visible", false);
      return "no_pose";
    }

    // Calculate knee angles for both legs
    final leftKneeAngle = leftAnkle != null ? _calculateAngle(leftHip, leftKnee, leftAnkle) : 180.0;
    final rightKneeAngle = rightAnkle != null ? _calculateAngle(rightHip, rightKnee, rightAnkle) : 180.0;

    // Use the leg with the smaller knee angle (forward leg in lunge)
    final forwardKneeAngle = math.min(leftKneeAngle, rightKneeAngle);
    final backKneeAngle = math.max(leftKneeAngle, rightKneeAngle);

    // Check if we're in a proper lunge position
    if (!_isLungePosition(forwardKneeAngle, backKneeAngle)) {
      updateFormStatus("Stand tall - step forward into lunge", true);
      return "standing";
    }

    return _analyzeLungeMovement(forwardKneeAngle, updateFormStatus);
  }

  static double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = (math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x)).abs();
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  static bool _isLungePosition(double forwardKneeAngle, double backKneeAngle) {
    // In a proper lunge, forward knee should be bent and back knee should be straighter
    return forwardKneeAngle < 140 && backKneeAngle > 150;
  }

  static String _analyzeLungeMovement(double forwardKneeAngle, Function(String, bool) updateFormStatus) {
    if (forwardKneeAngle > 120) {
      updateFormStatus("Step forward into lunge", true);
      return "stepping_forward";
    } else if (forwardKneeAngle > 90 && forwardKneeAngle <= 120) {
      updateFormStatus("Good lunge depth - keep chest up", true);
      return "mid_lunge";
    } else if (forwardKneeAngle > 70 && forwardKneeAngle <= 90) {
      updateFormStatus("Perfect lunge! Front knee at 90°", true);
      return "perfect_lunge";
    } else if (forwardKneeAngle <= 70) {
      updateFormStatus("Deep lunge! Push back to start", true);
      return "deep_lunge";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to standing after a deep lunge
    return (previousState == "perfect_lunge" || previousState == "deep_lunge") &&
        currentState == "standing";
  }
}