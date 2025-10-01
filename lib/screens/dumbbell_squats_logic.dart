// workout_logic/dumbbell_squats_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellSquatsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || rightHip == null || leftKnee == null || rightKnee == null) {
      updateFormStatus("Ensure hips and knees are visible", false);
      return "no_pose";
    }

    // Calculate average knee angle
    final leftKneeAngle = leftAnkle != null ? _calculateAngle(leftHip, leftKnee, leftAnkle) : 180.0;
    final rightKneeAngle = rightAnkle != null ? _calculateAngle(rightHip, rightKnee, rightAnkle) : 180.0;
    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    // Check upright position
    if (!_isUprightPosition(pose)) {
      updateFormStatus("Stand tall with dumbbells at sides", false);
      return "not_upright";
    }

    return _analyzeSquatMovement(avgKneeAngle, updateFormStatus);
  }

  static double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = (math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x)).abs();
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  static bool _isUprightPosition(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null) {
      return false;
    }

    final torsoAlignment = ((leftShoulder.y - leftHip.y).abs() + (rightShoulder.y - rightHip.y).abs()) / 2;
    return torsoAlignment < 0.3;
  }

  static String _analyzeSquatMovement(double kneeAngle, Function(String, bool) updateFormStatus) {
    if (kneeAngle > 150) {
      updateFormStatus("Standing position - begin squat", true);
      return "standing";
    } else if (kneeAngle > 120 && kneeAngle <= 150) {
      updateFormStatus("Descending - keep chest up", true);
      return "descending";
    } else if (kneeAngle > 90 && kneeAngle <= 120) {
      updateFormStatus("Good depth - drive up through heels", true);
      return "bottom_position";
    } else if (kneeAngle <= 90) {
      updateFormStatus("Deep squat! Push back up", true);
      return "deep_squat";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    return previousState == "deep_squat" && currentState == "standing";
  }
}