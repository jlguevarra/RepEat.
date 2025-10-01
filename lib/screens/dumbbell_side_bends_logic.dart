// workout_logic/dumbbell_side_bends_logic.dart

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellSideBendsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null) {
      updateFormStatus("Ensure torso is visible", false);
      return "no_pose";
    }

    // Calculate lateral bend (side-to-side lean)
    final leftBend = (leftShoulder.y - leftHip.y).abs();
    final rightBend = (rightShoulder.y - rightHip.y).abs();
    final bendDifference = (leftBend - rightBend).abs();

    return _analyzeSideBendMovement(bendDifference, updateFormStatus);
  }

  static String _analyzeSideBendMovement(double bendDiff, Function(String, bool) updateFormStatus) {
    if (bendDiff < 0.05) {
      updateFormStatus("Upright position - bend to side", true);
      return "upright";
    } else if (bendDiff >= 0.05 && bendDiff < 0.1) {
      updateFormStatus("Bending sideways - feel the stretch", true);
      return "bending";
    } else if (bendDiff >= 0.1 && bendDiff < 0.15) {
      updateFormStatus("Good stretch! Return to center", true);
      return "full_bend";
    } else if (bendDiff >= 0.15) {
      updateFormStatus("Deep side bend! Come back up", true);
      return "deep_bend";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "full_bend" && currentState == "upright";
  }
}