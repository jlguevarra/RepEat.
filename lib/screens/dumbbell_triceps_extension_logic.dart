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
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Check if essential landmarks are visible
    if (leftShoulder == null || rightShoulder == null ||
        leftElbow == null || rightElbow == null ||
        leftWrist == null || rightWrist == null ||
        leftHip == null || rightHip == null) {
      updateFormStatus("Ensure arms, shoulders, and torso are visible", false);
      return "no_pose";
    }

    // Check for proper triceps extension form
    final formCheck = _checkTricepsExtensionForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate angles for both arms
    final leftAngle = _calculateElbowAngle(leftShoulder, leftElbow, leftWrist);
    final rightAngle = _calculateElbowAngle(rightShoulder, rightElbow, rightWrist);
    final avgAngle = (leftAngle + rightAngle) / 2;

    // Calculate shoulder stability
    final shoulderStability = _calculateShoulderStability(leftShoulder, rightShoulder, leftHip, rightHip);

    // Analyze triceps extension movement
    return _analyzeExtensionMovement(avgAngle, shoulderStability, updateFormStatus);
  }

  static FormCheckResult _checkTricepsExtensionForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Check standing or seated position with upright torso
    final torsoAngle = _calculateTorsoAngle(leftShoulder!, rightShoulder!, leftHip!, rightHip!);
    if (torsoAngle < 70) {
      updateFormStatus("Sit/stand upright - don't lean back", false);
      return FormCheckResult(false, "leaning_back");
    }

    // Check elbow position (should be close to head)
    final leftElbowHeadPosition = _checkElbowHeadPosition(leftElbow!, leftShoulder);
    final rightElbowHeadPosition = _checkElbowHeadPosition(rightElbow!, rightShoulder);

    if (!leftElbowHeadPosition || !rightElbowHeadPosition) {
      updateFormStatus("Keep elbows close to head", false);
      return FormCheckResult(false, "elbows_too_wide");
    }

    // Check shoulder stability (shoulders shouldn't move forward)
    final leftShoulderStability = (leftShoulder.x - leftHip.x).abs();
    final rightShoulderStability = (rightShoulder.x - rightHip.x).abs();

    if (leftShoulderStability > 0.25 || rightShoulderStability > 0.25) {
      updateFormStatus("Keep shoulders stable - don't push forward", false);
      return FormCheckResult(false, "shoulders_forward");
    }

    // Check upper arm position (should be vertical)
    final leftUpperArmAngle = _calculateUpperArmAngle(leftShoulder, leftElbow);
    final rightUpperArmAngle = _calculateUpperArmAngle(rightShoulder, rightElbow);

    if (leftUpperArmAngle < 70 || rightUpperArmAngle < 70) {
      updateFormStatus("Keep upper arms vertical", false);
      return FormCheckResult(false, "upper_arms_angled");
    }

    // Check for symmetric movement
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftWrist != null && rightWrist != null) {
      final wristSymmetry = (leftWrist.y - rightWrist.y).abs();
      if (wristSymmetry > 0.15) {
        updateFormStatus("Extend arms evenly", false);
        return FormCheckResult(false, "asymmetric_extension");
      }
    }

    return FormCheckResult(true, "good_form");
  }

  static double _calculateElbowAngle(PoseLandmark shoulder, PoseLandmark elbow, PoseLandmark wrist) {
    final radians = math.atan2(wrist.y - elbow.y, wrist.x - elbow.x) -
        math.atan2(shoulder.y - elbow.y, shoulder.x - elbow.x);
    double angle = (radians * 180.0 / math.pi).abs();

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  static double _calculateUpperArmAngle(PoseLandmark shoulder, PoseLandmark elbow) {
    // Calculate angle of upper arm relative to vertical
    final verticalDiff = (shoulder.y - elbow.y).abs();
    final horizontalDiff = (shoulder.x - elbow.x).abs();

    if (verticalDiff == 0) return 90.0;

    final angle = math.atan(horizontalDiff / verticalDiff) * 180 / math.pi;
    return 90 - angle; // Convert to angle from vertical
  }

  static double _calculateTorsoAngle(PoseLandmark leftShoulder, PoseLandmark rightShoulder,
      PoseLandmark leftHip, PoseLandmark rightHip) {
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipMidY = (leftHip.y + rightHip.y) / 2;
    final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
    final hipMidX = (leftHip.x + rightHip.x) / 2;

    final verticalDiff = (shoulderMidY - hipMidY).abs();
    final horizontalDiff = (shoulderMidX - hipMidX).abs();

    if (horizontalDiff == 0) return 90.0;

    final angle = math.atan(verticalDiff / horizontalDiff) * 180 / math.pi;
    return angle;
  }

  static double _calculateShoulderStability(PoseLandmark leftShoulder, PoseLandmark rightShoulder,
      PoseLandmark leftHip, PoseLandmark rightHip) {
    // Calculate how stable shoulders are during the movement
    final leftStability = (leftShoulder.x - leftHip.x).abs();
    final rightStability = (rightShoulder.x - rightHip.x).abs();

    return (leftStability + rightStability) / 2;
  }

  static bool _checkElbowHeadPosition(PoseLandmark elbow, PoseLandmark shoulder) {
    // Check if elbow is positioned close to head (proper form)
    final horizontalDistance = (elbow.x - shoulder.x).abs();
    return horizontalDistance < 0.15;
  }

  static String _analyzeExtensionMovement(double angle, double shoulderStability, Function(String, bool) updateFormStatus) {
    // Check shoulder stability
    if (shoulderStability > 0.2) {
      updateFormStatus("Stabilize shoulders - minimize movement", false);
      return "unstable_shoulders";
    }

    if (angle < 50) {
      updateFormStatus("Arms fully bent - dumbbell behind head", true);
      return "starting_position";
    } else if (angle >= 50 && angle < 80) {
      updateFormStatus("Extending arms - isolate triceps", true);
      return "extending_phase1";
    } else if (angle >= 80 && angle < 110) {
      updateFormStatus("Continuing extension - keep elbows in", true);
      return "extending_phase2";
    } else if (angle >= 110 && angle < 140) {
      updateFormStatus("Near full extension - squeeze triceps", true);
      return "near_extension";
    } else if (angle >= 140) {
      updateFormStatus("Arms fully extended! Don't lock elbows", true);
      return "full_extension";
    } else if (angle >= 110 && angle < 140) {
      updateFormStatus("Lowering weight - controlled descent", true);
      return "lowering_phase1";
    } else if (angle >= 80 && angle < 110) {
      updateFormStatus("Returning to start - maintain form", true);
      return "lowering_phase2";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to starting position after full extension
    return (previousState == "full_extension" && currentState == "starting_position") ||
        (previousState == "near_extension" && currentState == "starting_position") ||
        (previousState == "lowering_phase2" && currentState == "starting_position");
  }

  static bool isValidForm(String state) {
    return state == "starting_position" ||
        state == "extending_phase1" ||
        state == "extending_phase2" ||
        state == "near_extension" ||
        state == "full_extension" ||
        state == "lowering_phase1" ||
        state == "lowering_phase2";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}