// workout_logic/dumbbell_calf_raises_logic.dart

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellCalfRaisesLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftHeel = pose.landmarks[PoseLandmarkType.leftHeel];
    final rightHeel = pose.landmarks[PoseLandmarkType.rightHeel];

    if (leftAnkle == null || rightAnkle == null ||
        leftKnee == null || rightKnee == null) {
      updateFormStatus("Ensure legs are visible", false);
      return "no_pose";
    }

    // Calculate heel lift (vertical distance from ankle to knee)
    final leftLift = leftHeel != null ? (leftHeel.y - leftAnkle.y).abs() : 0.0;
    final rightLift = rightHeel != null ? (rightHeel.y - rightAnkle.y).abs() : 0.0;
    final avgLift = (leftLift + rightLift) / 2;

    return _analyzeCalfRaiseMovement(avgLift, updateFormStatus);
  }

  static String _analyzeCalfRaiseMovement(double lift, Function(String, bool) updateFormStatus) {
    if (lift < 0.02) {
      updateFormStatus("Heels down - rise onto toes", true);
      return "heels_down";
    } else if (lift >= 0.02 && lift < 0.05) {
      updateFormStatus("Rising up - push through balls of feet", true);
      return "rising";
    } else if (lift >= 0.05 && lift < 0.08) {
      updateFormStatus("Good lift! Squeeze calves at top", true);
      return "top_position";
    } else if (lift >= 0.08) {
      updateFormStatus("Maximum extension! Lower slowly", true);
      return "full_extension";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "full_extension" && currentState == "heels_down";
  }
}