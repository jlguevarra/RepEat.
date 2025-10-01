// workout_logic/dumbbell_hammer_curls_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellHammerCurlsLogic {
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
    return _analyzeHammerCurlMovement(angle, updateFormStatus);
  }

  static double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = (math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x)).abs();
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  static String _analyzeHammerCurlMovement(double angle, Function(String, bool) updateFormStatus) {
    if (angle > 140) {
      updateFormStatus("Arms extended - curl with neutral grip", true);
      return "arms_extended";
    } else if (angle > 90 && angle <= 140) {
      updateFormStatus("Hammer curling - keep thumbs up", true);
      return "curling_up";
    } else if (angle > 60 && angle <= 90) {
      updateFormStatus("Good! Squeeze at top", true);
      return "top_position";
    } else if (angle <= 60) {
      updateFormStatus("Full contraction! Lower slowly", true);
      return "full_contraction";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "full_contraction" && currentState == "arms_extended";
  }
}