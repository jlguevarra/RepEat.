// workout_logic/dumbbell_situps_logic.dart

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellSitupsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (nose == null || leftHip == null || rightHip == null) {
      updateFormStatus("Ensure upper body and hips are visible", false);
      return "no_pose";
    }

    final hip = PoseLandmark(
      type: PoseLandmarkType.leftHip,
      x: (leftHip.x + rightHip.x) / 2,
      y: (leftHip.y + rightHip.y) / 2,
      z: (leftHip.z + rightHip.z) / 2,
      likelihood: (leftHip.likelihood + rightHip.likelihood) / 2,
    );

    // Calculate torso flexion (distance from nose to hips)
    final verticalDistance = (nose.y - hip.y).abs();

    return _analyzeSitupMovement(verticalDistance, updateFormStatus);
  }

  static String _analyzeSitupMovement(double distance, Function(String, bool) updateFormStatus) {
    if (distance < 0.2) {
      updateFormStatus("Lying down - curl torso up", true);
      return "lying_down";
    } else if (distance >= 0.2 && distance < 0.3) {
      updateFormStatus("Curling up - engage core", true);
      return "curling_up";
    } else if (distance >= 0.3 && distance < 0.4) {
      updateFormStatus("Good sit-up! Squeeze abs", true);
      return "sitting_up";
    } else if (distance >= 0.4) {
      updateFormStatus("Full sit-up! Lower with control", true);
      return "full_situp";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "full_situp" && currentState == "lying_down";
  }
}