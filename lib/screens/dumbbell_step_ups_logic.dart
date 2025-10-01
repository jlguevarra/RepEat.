// workout_logic/dumbbell_step_ups_logic.dart

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellStepUpsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (leftHip == null || rightHip == null ||
        leftKnee == null || rightKnee == null) {
      updateFormStatus("Ensure legs are visible", false);
      return "no_pose";
    }

    // Determine which leg is stepping (higher knee)
    final isLeftStepping = leftKnee.y < rightKnee.y;
    final steppingKneeHeight = isLeftStepping ? leftKnee.y : rightKnee.y;
    final standingKneeHeight = isLeftStepping ? rightKnee.y : leftKnee.y;

    final heightDifference = (standingKneeHeight - steppingKneeHeight).abs();

    return _analyzeStepUpMovement(heightDifference, updateFormStatus);
  }

  static String _analyzeStepUpMovement(double heightDiff, Function(String, bool) updateFormStatus) {
    if (heightDiff < 0.05) {
      updateFormStatus("Both feet on ground - step up", true);
      return "both_ground";
    } else if (heightDiff >= 0.05 && heightDiff < 0.1) {
      updateFormStatus("Stepping up - drive through heel", true);
      return "stepping_up";
    } else if (heightDiff >= 0.1 && heightDiff < 0.15) {
      updateFormStatus("Good height! Bring other foot up", true);
      return "top_position";
    } else if (heightDiff >= 0.15) {
      updateFormStatus("High step! Step back down", true);
      return "full_step";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "full_step" && currentState == "both_ground";
  }
}