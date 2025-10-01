// workout_logic/dumbbell_rows_logic.dart

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellRowsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null || rightShoulder == null ||
        leftElbow == null || rightElbow == null) {
      updateFormStatus("Ensure back and arms are visible", false);
      return "no_pose";
    }

    // Calculate elbow position relative to shoulder
    final leftElbowPosition = (leftElbow.x - leftShoulder.x).abs();
    final rightElbowPosition = (rightElbow.x - rightShoulder.x).abs();
    final avgElbowPosition = (leftElbowPosition + rightElbowPosition) / 2;

    // Check bent-over position
    if (!_isBentOverPosition(pose)) {
      updateFormStatus("Bend forward with flat back", false);
      return "not_bent_over";
    }

    return _analyzeRowMovement(avgElbowPosition, updateFormStatus);
  }

  static bool _isBentOverPosition(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null) {
      return false;
    }

    final torsoAngle = ((leftShoulder.y - leftHip.y).abs() + (rightShoulder.y - rightHip.y).abs()) / 2;
    return torsoAngle > 0.2; // Shoulders should be higher than hips
  }

  static String _analyzeRowMovement(double elbowPosition, Function(String, bool) updateFormStatus) {
    if (elbowPosition < 0.05) {
      updateFormStatus("Arms extended - pull elbows back", true);
      return "arms_extended";
    } else if (elbowPosition >= 0.05 && elbowPosition < 0.1) {
      updateFormStatus("Pulling back - squeeze shoulder blades", true);
      return "pulling_back";
    } else if (elbowPosition >= 0.1 && elbowPosition < 0.15) {
      updateFormStatus("Good contraction! Hold and lower", true);
      return "full_contraction";
    } else if (elbowPosition >= 0.15) {
      updateFormStatus("Elbows too far back - control the movement", false);
      return "over_pulled";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "full_contraction" && currentState == "arms_extended";
  }
}