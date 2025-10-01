// workout_logic/dumbbell_triceps_extension_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellTricepsExtensionLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null || rightShoulder == null ||
        leftElbow == null || rightElbow == null) {
      updateFormStatus("Ensure arms and shoulders are visible", false);
      return "no_pose";
    }

    // Use the arm with better visibility
    final elbow = leftElbow.y < rightElbow.y ? leftElbow : rightElbow;
    final shoulder = leftElbow.y < rightElbow.y ? leftShoulder : rightShoulder;
    final wrist = leftElbow.y < rightElbow.y ? leftWrist : rightWrist;

    if (wrist == null) {
      updateFormStatus("Ensure wrists are visible", false);
      return "no_wrist";
    }

    final angle = _calculateAngle(shoulder, elbow, wrist);
    return _analyzeExtensionMovement(angle, updateFormStatus);
  }

  static double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = (math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x)).abs();
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  static String _analyzeExtensionMovement(double angle, Function(String, bool) updateFormStatus) {
    if (angle < 60) {
      updateFormStatus("Arms bent - extend elbows", true);
      return "arms_bent";
    } else if (angle >= 60 && angle < 100) {
      updateFormStatus("Extending arms - keep going", true);
      return "extending";
    } else if (angle >= 100 && angle < 140) {
      updateFormStatus("Good extension! Squeeze triceps", true);
      return "near_extension";
    } else if (angle >= 140) {
      updateFormStatus("Arms fully extended! Bend elbows to return", true);
      return "full_extension";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "full_extension" && currentState == "arms_bent";
  }
}