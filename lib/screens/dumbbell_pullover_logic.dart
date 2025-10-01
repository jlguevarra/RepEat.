// workout_logic/dumbbell_pullover_logic.dart

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellPulloverLogic {
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

    // Calculate average wrist position
    final avgWristY = (leftWrist.y + rightWrist.y) / 2;
    final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final avgHipY = (leftHip.y + rightHip.y) / 2;

    // Calculate how far arms are extended (vertical distance from shoulders)
    final armExtension = (avgWristY - avgShoulderY).abs();

    // Check if lying on bench/floor (hips lower than shoulders)
    final isLyingPosition = avgHipY > avgShoulderY;

    if (!isLyingPosition) {
      updateFormStatus("Lie on bench with dumbbell over chest", false);
      return "not_lying";
    }

    return _analyzePulloverMovement(armExtension, updateFormStatus);
  }

  static String _analyzePulloverMovement(double armExtension, Function(String, bool) updateFormStatus) {
    if (armExtension < 0.05) {
      updateFormStatus("Dumbbell over chest - lower behind head", true);
      return "chest_position";
    } else if (armExtension >= 0.05 && armExtension < 0.15) {
      updateFormStatus("Lowering arms - feel lat stretch", true);
      return "lowering";
    } else if (armExtension >= 0.15 && armExtension < 0.25) {
      updateFormStatus("Good stretch! Arms parallel to floor", true);
      return "full_stretch";
    } else if (armExtension >= 0.25) {
      updateFormStatus("Maximum extension! Pull back to chest", true);
      return "max_extension";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to chest position after full extension
    return previousState == "max_extension" && currentState == "chest_position";
  }
}