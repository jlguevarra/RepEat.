// workout_logic/dumbbell_russian_twists_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellRussianTwistsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // Check if essential landmarks are visible
    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null ||
        leftKnee == null || rightKnee == null ||
        leftWrist == null || rightWrist == null) {
      updateFormStatus("Ensure torso, arms, and legs are visible", false);
      return "no_pose";
    }

    // Check for proper Russian twist form
    final formCheck = _checkRussianTwistForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate torso rotation (primary movement)
    final rotation = _calculateTorsoRotation(leftShoulder, rightShoulder, leftHip, rightHip);

    // Determine twist direction
    final twistDirection = _determineTwistDirection(leftShoulder, rightShoulder, leftHip, rightHip);

    // Analyze twist movement
    return _analyzeTwistMovement(rotation, twistDirection, updateFormStatus);
  }

  static FormCheckResult _checkRussianTwistForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // Check seated position with bent knees
    final hipKneeDistanceLeft = (leftHip!.y - leftKnee!.y).abs();
    final hipKneeDistanceRight = (rightHip!.y - rightKnee!.y).abs();

    if (hipKneeDistanceLeft > 0.3 || hipKneeDistanceRight > 0.3) {
      updateFormStatus("Sit with knees bent and feet elevated", false);
      return FormCheckResult(false, "not_seated_properly");
    }

    // Check torso angle (should be leaning back slightly)
    final torsoAngle = _calculateTorsoAngle(leftShoulder!, leftHip, rightHip!);
    if (torsoAngle < 100) {
      updateFormStatus("Lean back slightly - engage core", false);
      return FormCheckResult(false, "too_upright");
    }

    if (torsoAngle > 140) {
      updateFormStatus("Don't lean back too far", false);
      return FormCheckResult(false, "leaning_too_far");
    }

    // Check if feet are elevated (ankles higher than knees)
    if (leftAnkle != null && rightAnkle != null) {
      final leftAnkleKnee = (leftAnkle.y - leftKnee.y);
      final rightAnkleKnee = (rightAnkle.y - rightKnee.y);

      if (leftAnkleKnee > 0 || rightAnkleKnee > 0) {
        updateFormStatus("Elevate feet off ground", false);
        return FormCheckResult(false, "feet_on_ground");
      }
    }

    // Check shoulder stability (should rotate together)
    final shoulderAlignment = (leftShoulder.y - rightShoulder!.y).abs();
    if (shoulderAlignment > 0.15) {
      updateFormStatus("Keep shoulders level during twist", false);
      return FormCheckResult(false, "uneven_shoulders");
    }

    return FormCheckResult(true, "good_form");
  }

  static double _calculateTorsoRotation(PoseLandmark leftShoulder, PoseLandmark rightShoulder,
      PoseLandmark leftHip, PoseLandmark rightHip) {
    final shoulderVectorX = rightShoulder.x - leftShoulder.x;
    final shoulderVectorY = rightShoulder.y - leftShoulder.y;

    final hipVectorX = rightHip.x - leftHip.x;
    final hipVectorY = rightHip.y - leftHip.y;

    // Calculate angle between shoulder line and hip line
    final dotProduct = shoulderVectorX * hipVectorX + shoulderVectorY * hipVectorY;
    final magnitudeShoulder = math.sqrt(shoulderVectorX * shoulderVectorX + shoulderVectorY * shoulderVectorY);
    final magnitudeHip = math.sqrt(hipVectorX * hipVectorX + hipVectorY * hipVectorY);

    if (magnitudeShoulder == 0 || magnitudeHip == 0) return 0.0;

    final cosAngle = dotProduct / (magnitudeShoulder * magnitudeHip);
    final angle = math.acos(cosAngle.clamp(-1.0, 1.0));

    return angle;
  }

  static double _calculateTorsoAngle(PoseLandmark shoulder, PoseLandmark hip, PoseLandmark otherHip) {
    // Calculate torso angle relative to vertical
    final verticalDiff = (shoulder.y - hip.y).abs();
    final horizontalDiff = (shoulder.x - hip.x).abs();

    if (horizontalDiff == 0) return 90.0;

    final angle = math.atan(verticalDiff / horizontalDiff) * 180 / math.pi;
    return 180 - angle; // Convert to torso lean angle
  }

  static String _determineTwistDirection(PoseLandmark leftShoulder, PoseLandmark rightShoulder,
      PoseLandmark leftHip, PoseLandmark rightHip) {
    // Determine which direction the torso is twisting
    final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
    final hipMidX = (leftHip.x + rightHip.x) / 2;

    return shoulderMidX > hipMidX ? "right" : "left";
  }

  static String _analyzeTwistMovement(double rotation, String direction, Function(String, bool) updateFormStatus) {
    final side = direction == "left" ? "left" : "right";

    if (rotation < 0.2) {
      updateFormStatus("Center position - ready to twist", true);
      return "center_position";
    } else if (rotation >= 0.2 && rotation < 0.4) {
      updateFormStatus("Twisting to $side side - continue rotating", true);
      return "twisting_phase1";
    } else if (rotation >= 0.4 && rotation < 0.6) {
      updateFormStatus("Good $side rotation - feel oblique engagement", true);
      return "twisting_phase2";
    } else if (rotation >= 0.6 && rotation < 0.8) {
      updateFormStatus("Full $side twist! Hold and return", true);
      return "full_twist";
    } else if (rotation >= 0.8) {
      updateFormStatus("Maximum $side rotation! Return to center", true);
      return "max_twist";
    } else if (rotation >= 0.4 && rotation < 0.6) {
      updateFormStatus("Returning to center - controlled movement", true);
      return "returning_phase1";
    } else if (rotation >= 0.2 && rotation < 0.4) {
      updateFormStatus("Almost centered - maintain core tension", true);
      return "returning_phase2";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when completing full twist to one side and returning to center
    // This ensures counting both left and right twists
    return (previousState == "full_twist" && currentState == "center_position") ||
        (previousState == "max_twist" && currentState == "center_position") ||
        (previousState == "returning_phase2" && currentState == "center_position");
  }

  static bool isValidForm(String state) {
    return state == "center_position" ||
        state == "twisting_phase1" ||
        state == "twisting_phase2" ||
        state == "full_twist" ||
        state == "max_twist" ||
        state == "returning_phase1" ||
        state == "returning_phase2";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}