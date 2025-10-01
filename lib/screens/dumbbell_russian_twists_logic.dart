// workout_logic/dumbbell_russian_twists_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellRussianTwistsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null) {
      updateFormStatus("Ensure torso and hips are visible", false);
      return "no_pose";
    }

    // Calculate torso rotation
    final rotation = _calculateTorsoRotation(leftShoulder, rightShoulder, leftHip, rightHip);

    // Check seated position
    if (!_isSeatedPosition(pose)) {
      updateFormStatus("Sit on floor with knees bent", false);
      return "not_seated";
    }

    return _analyzeTwistMovement(rotation, updateFormStatus);
  }

  static double _calculateTorsoRotation(PoseLandmark leftShoulder, PoseLandmark rightShoulder,
      PoseLandmark leftHip, PoseLandmark rightHip) {
    final shoulderAngle = math.atan2(
        rightShoulder.y - leftShoulder.y,
        rightShoulder.x - leftShoulder.x
    );

    final hipAngle = math.atan2(
        rightHip.y - leftHip.y,
        rightHip.x - leftHip.x
    );

    return (shoulderAngle - hipAngle).abs();
  }

  static bool _isSeatedPosition(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (leftHip == null || rightHip == null || leftKnee == null || rightKnee == null) {
      return false;
    }

    // Hips should be close to knees (seated position)
    final hipKneeDistance = ((leftHip.y - leftKnee.y).abs() + (rightHip.y - rightKnee.y).abs()) / 2;
    return hipKneeDistance < 0.2;
  }

  static String _analyzeTwistMovement(double rotation, Function(String, bool) updateFormStatus) {
    if (rotation < 0.1) {
      updateFormStatus("Center position - twist to one side", true);
      return "center";
    } else if (rotation >= 0.1 && rotation < 0.3) {
      updateFormStatus("Twisting - rotate torso further", true);
      return "twisting";
    } else if (rotation >= 0.3 && rotation < 0.5) {
      updateFormStatus("Good rotation! Hold and return", true);
      return "full_twist";
    } else if (rotation >= 0.5) {
      updateFormStatus("Maximum rotation! Return to center", true);
      return "max_twist";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to center after full twist
    return (previousState == "full_twist" || previousState == "max_twist") &&
        currentState == "center";
  }
}