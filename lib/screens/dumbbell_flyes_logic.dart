// workout_logic/dumbbell_flyes_logic.dart

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellFlyesLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (leftWrist == null || rightWrist == null ||
        leftShoulder == null || rightShoulder == null) {
      updateFormStatus("Ensure arms and shoulders are visible", false);
      return "no_pose";
    }

    // Calculate chest distance (between wrists)
    final chestDistance = (leftWrist.x - rightWrist.x).abs();
    final shoulderDistance = (leftShoulder.x - rightShoulder.x).abs();
    final relativeDistance = chestDistance / shoulderDistance;

    return _analyzeFlyesMovement(relativeDistance, updateFormStatus);
  }

  static String _analyzeFlyesMovement(double relativeDistance, Function(String, bool) updateFormStatus) {
    if (relativeDistance < 1.2) {
      updateFormStatus("Arms together - open arms wide", true);
      return "arms_together";
    } else if (relativeDistance >= 1.2 && relativeDistance < 1.6) {
      updateFormStatus("Opening arms - keep going", true);
      return "opening_arms";
    } else if (relativeDistance >= 1.6 && relativeDistance < 2.0) {
      updateFormStatus("Good stretch! Squeeze chest to return", true);
      return "full_stretch";
    } else if (relativeDistance >= 2.0) {
      updateFormStatus("Arms fully extended! Bring together", true);
      return "max_stretch";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "max_stretch" && currentState == "arms_together";
  }
}