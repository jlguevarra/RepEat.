// workout_logic/dumbbell_shoulder_press_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellShoulderPressLogic {
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
      updateFormStatus("Ensure shoulders, arms, and torso are visible", false);
      return "no_pose";
    }

    // Check for proper shoulder press form
    final formCheck = _checkShoulderPressForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate angles for both arms
    final leftAngle = _calculateElbowAngle(leftShoulder, leftElbow, leftWrist);
    final rightAngle = _calculateElbowAngle(rightShoulder, rightElbow, rightWrist);
    final avgAngle = (leftAngle + rightAngle) / 2;

    // Calculate shoulder stability
    final shoulderStability = _calculateShoulderStability(leftShoulder, rightShoulder, leftHip, rightHip);

    // Analyze shoulder press movement
    return _analyzePressMovement(avgAngle, shoulderStability, updateFormStatus);
  }

  static FormCheckResult _checkShoulderPressForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];

    // Check standing position with proper posture
    final shoulderAlignment = (leftShoulder!.y - rightShoulder!.y).abs();
    if (shoulderAlignment > 0.1) {
      updateFormStatus("Stand upright with level shoulders", false);
      return FormCheckResult(false, "uneven_shoulders");
    }

    // Check core stability (shoulders over hips)
    final leftShoulderHip = (leftShoulder.x - leftHip!.x).abs();
    final rightShoulderHip = (rightShoulder.x - rightHip!.x).abs();

    if (leftShoulderHip > 0.2 || rightShoulderHip > 0.2) {
      updateFormStatus("Keep core tight - don't lean back", false);
      return FormCheckResult(false, "leaning_back");
    }

    // Check elbow position at start (should be in front of body)
    final leftElbowPosition = (leftElbow!.x - leftShoulder.x).abs();
    final rightElbowPosition = (rightElbow!.x - rightShoulder.x).abs();

    if (leftElbowPosition > 0.3 || rightElbowPosition > 0.3) {
      updateFormStatus("Keep elbows in front of body", false);
      return FormCheckResult(false, "elbows_too_wide");
    }

    // Check for excessive arching in lower back
    final torsoAlignment = (leftShoulder.y - leftHip.y).abs();
    if (torsoAlignment > 0.4) {
      updateFormStatus("Engage core - don't arch lower back", false);
      return FormCheckResult(false, "arched_back");
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

  static double _calculateShoulderStability(PoseLandmark leftShoulder, PoseLandmark rightShoulder,
      PoseLandmark leftHip, PoseLandmark rightHip) {
    // Calculate how stable shoulders are during the press
    final leftStability = (leftShoulder.x - leftHip.x).abs();
    final rightStability = (rightShoulder.x - rightHip.x).abs();

    return (leftStability + rightStability) / 2;
  }

  static String _analyzePressMovement(double angle, double shoulderStability, Function(String, bool) updateFormStatus) {
    // Check shoulder stability
    if (shoulderStability > 0.25) {
      updateFormStatus("Stabilize shoulders - reduce sway", false);
      return "unstable_shoulders";
    }

    if (angle < 70) {
      updateFormStatus("Dumbbells at shoulders - ready to press", true);
      return "starting_position";
    } else if (angle >= 70 && angle < 100) {
      updateFormStatus("Pressing upward - drive through shoulders", true);
      return "ascending_phase1";
    } else if (angle >= 100 && angle < 130) {
      updateFormStatus("Continuing up - keep core engaged", true);
      return "ascending_phase2";
    } else if (angle >= 130 && angle < 160) {
      updateFormStatus("Near top - push to full extension", true);
      return "top_position";
    } else if (angle >= 160) {
      updateFormStatus("Arms fully extended! Don't lock elbows", true);
      return "full_extension";
    } else if (angle >= 130 && angle < 160) {
      updateFormStatus("Lowering down - controlled descent", true);
      return "descending_phase1";
    } else if (angle >= 100 && angle < 130) {
      updateFormStatus("Almost back to start - maintain control", true);
      return "descending_phase2";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to starting position after full extension
    return (previousState == "full_extension" && currentState == "starting_position") ||
        (previousState == "top_position" && currentState == "starting_position") ||
        (previousState == "descending_phase2" && currentState == "starting_position");
  }

  static bool isValidForm(String state) {
    return state == "starting_position" ||
        state == "ascending_phase1" ||
        state == "ascending_phase2" ||
        state == "top_position" ||
        state == "full_extension" ||
        state == "descending_phase1" ||
        state == "descending_phase2";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}