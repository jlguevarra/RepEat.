// workout_logic/dumbbell_reverse_flyes_logic.dart

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellReverseFlyesLogic {
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

    // Calculate back distance (between wrists behind body)
    final backDistance = (leftWrist.x - rightWrist.x).abs();
    final shoulderDistance = (leftShoulder.x - rightShoulder.x).abs();
    final relativeDistance = backDistance / shoulderDistance;

    return _analyzeReverseFlyesMovement(relativeDistance, updateFormStatus);
  }

  static String _analyzeReverseFlyesMovement(double relativeDistance, Function(String, bool) updateFormStatus) {
    if (relativeDistance < 1.1) {
      updateFormStatus("Arms in front - pull back", true);
      return "arms_forward";
    } else if (relativeDistance >= 1.1 && relativeDistance < 1.4) {
      updateFormStatus("Pulling back - squeeze shoulder blades", true);
      return "pulling_back";
    } else if (relativeDistance >= 1.4 && relativeDistance < 1.7) {
      updateFormStatus("Good contraction! Return slowly", true);
      return "full_contraction";
    } else if (relativeDistance >= 1.7) {
      updateFormStatus("Maximum squeeze! Return to start", true);
      return "max_contraction";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "full_contraction" && currentState == "arms_forward";
  }
}