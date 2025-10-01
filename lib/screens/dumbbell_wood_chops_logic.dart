// workout_logic/dumbbell_wood_chops_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellWoodChopsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftWrist == null || rightWrist == null ||
        leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null) {
      updateFormStatus("Ensure arms and torso are visible", false);
      return "no_pose";
    }

    // Calculate diagonal movement (shoulder to opposite hip)
    final wristHeight = (leftWrist.y + rightWrist.y) / 2;
    final shoulderHeight = (leftShoulder.y + rightShoulder.y) / 2;
    final hipHeight = (leftHip.y + rightHip.y) / 2;

    final verticalMovement = (wristHeight - shoulderHeight).abs();

    return _analyzeWoodChopMovement(verticalMovement, updateFormStatus);
  }

  static String _analyzeWoodChopMovement(double movement, Function(String, bool) updateFormStatus) {
    if (movement < 0.1) {
      updateFormStatus("Start position - chop diagonally", true);
      return "start_position";
    } else if (movement >= 0.1 && movement < 0.2) {
      updateFormStatus("Chopping motion - engage core", true);
      return "chopping";
    } else if (movement >= 0.2 && movement < 0.3) {
      updateFormStatus("Good range! Return to start", true);
      return "full_chop";
    } else if (movement >= 0.3) {
      updateFormStatus("Full extension! Reverse motion", true);
      return "max_extension";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "max_extension" && currentState == "start_position";
  }
}