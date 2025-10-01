// workout_logic/dumbbell_deadlifts_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellDeadliftsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null ||
        leftKnee == null || rightKnee == null) {
      updateFormStatus("Ensure full body is visible", false);
      return "no_pose";
    }

    // Calculate hip hinge angle
    final leftHipAngle = _calculateAngle(leftShoulder, leftHip, leftKnee);
    final rightHipAngle = _calculateAngle(rightShoulder, rightHip, rightKnee);
    final avgHipAngle = (leftHipAngle + rightHipAngle) / 2;

    return _analyzeDeadliftMovement(avgHipAngle, updateFormStatus);
  }

  static double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = (math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x)).abs();
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  static String _analyzeDeadliftMovement(double hipAngle, Function(String, bool) updateFormStatus) {
    if (hipAngle > 160) {
      updateFormStatus("Standing tall - hinge at hips", true);
      return "standing";
    } else if (hipAngle > 120 && hipAngle <= 160) {
      updateFormStatus("Hinging forward - keep back straight", true);
      return "hinging";
    } else if (hipAngle > 90 && hipAngle <= 120) {
      updateFormStatus("Good position! Drive hips forward", true);
      return "bottom_position";
    } else if (hipAngle <= 90) {
      updateFormStatus("Dumbbells low! Stand up straight", true);
      return "full_extension";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "full_extension" && currentState == "standing";
  }
}