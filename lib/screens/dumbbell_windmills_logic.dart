// workout_logic/dumbbell_windmills_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellWindmillsLogic {
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

    // Calculate arm arc movement (vertical range)
    final leftArmArc = (leftWrist.y - leftShoulder.y).abs();
    final rightArmArc = (rightWrist.y - rightShoulder.y).abs();
    final avgArmArc = (leftArmArc + rightArmArc) / 2;

    return _analyzeWindmillMovement(avgArmArc, updateFormStatus);
  }

  static String _analyzeWindmillMovement(double armArc, Function(String, bool) updateFormStatus) {
    if (armArc < 0.1) {
      updateFormStatus("Arms at sides - begin windmill", true);
      return "arms_down";
    } else if (armArc >= 0.1 && armArc < 0.2) {
      updateFormStatus("Swinging arms up", true);
      return "swinging_up";
    } else if (armArc >= 0.2 && armArc < 0.3) {
      updateFormStatus("Arms overhead - good form!", true);
      return "overhead";
    } else if (armArc >= 0.3) {
      updateFormStatus("Full windmill! Lower arms", true);
      return "full_windmill";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "full_windmill" && currentState == "arms_down";
  }
}