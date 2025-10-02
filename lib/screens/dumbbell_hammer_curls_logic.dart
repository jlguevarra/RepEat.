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
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Check if essential landmarks are visible
    if (leftShoulder == null || rightShoulder == null ||
        leftElbow == null || rightElbow == null ||
        leftWrist == null || rightWrist == null) {
      updateFormStatus("Ensure both arms and shoulders are visible", false);
      return "no_pose";
    }

    // Check for proper hammer curl form
    final formCheck = _checkHammerCurlForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate angles for both arms
    final leftAngle = _calculateElbowAngle(leftShoulder, leftElbow, leftWrist);
    final rightAngle = _calculateElbowAngle(rightShoulder, rightElbow, rightWrist);

    // Use the average angle for analysis
    final avgAngle = (leftAngle + rightAngle) / 2;

    // Analyze hammer curl movement
    return _analyzeHammerCurlMovement(avgAngle, updateFormStatus);
  }

  static FormCheckResult _checkHammerCurlForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Check if elbows are staying close to body (no swinging)
    final leftElbowToBody = (leftElbow!.x - leftHip!.x).abs();
    final rightElbowToBody = (rightElbow!.x - rightHip!.x).abs();

    if (leftElbowToBody > 0.3 || rightElbowToBody > 0.3) {
      updateFormStatus("Keep elbows close to body - don't swing", false);
      return FormCheckResult(false, "swinging_arms");
    }

    // Check if shoulders are stable (not shrugging or moving forward)
    final leftShoulderStability = (leftShoulder!.y - leftHip.y).abs();
    final rightShoulderStability = (rightShoulder!.y - rightHip.y).abs();

    if (leftShoulderStability > 0.2 || rightShoulderStability > 0.2) {
      updateFormStatus("Keep shoulders down and stable", false);
      return FormCheckResult(false, "shoulder_movement");
    }

    // Check wrist alignment for hammer grip (wrists should be neutral)
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftWrist != null && rightWrist != null) {
      final leftWristElbowDiff = (leftWrist.y - leftElbow.y).abs();
      final rightWristElbowDiff = (rightWrist.y - rightElbow.y).abs();

      // In proper hammer curl, wrists should maintain neutral position
      if (leftWristElbowDiff > 0.4 || rightWristElbowDiff > 0.4) {
        updateFormStatus("Keep wrists straight - neutral grip", false);
        return FormCheckResult(false, "wrist_flexion");
      }
    }

    return FormCheckResult(true, "good_form");
  }

  static double _calculateElbowAngle(PoseLandmark shoulder, PoseLandmark elbow, PoseLandmark wrist) {
    final radians = math.atan2(wrist.y - elbow.y, wrist.x - elbow.x) -
        math.atan2(shoulder.y - elbow.y, shoulder.x - elbow.x);
    double angle = (radians * 180.0 / math.pi).abs();

    // Normalize angle to be between 0 and 180
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  static String _analyzeHammerCurlMovement(double angle, Function(String, bool) updateFormStatus) {
    if (angle > 160) {
      updateFormStatus("Arms fully extended - start curling", true);
      return "starting_position";
    } else if (angle > 120) {
      updateFormStatus("Hammer curling up - neutral grip", true);
      return "curling_up_phase1";
    } else if (angle > 90) {
      updateFormStatus("Halfway up - keep elbows stationary", true);
      return "curling_up_phase2";
    } else if (angle > 70) {
      updateFormStatus("Near top - squeeze brachialis", true);
      return "top_position";
    } else if (angle <= 70) {
      updateFormStatus("Full contraction! Lower with control", true);
      return "full_contraction";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to starting position after full contraction
    // This ensures complete range of motion
    return (previousState == "full_contraction" && currentState == "starting_position") ||
        (previousState == "top_position" && currentState == "starting_position");
  }

  static bool isValidForm(String state) {
    return state == "starting_position" ||
        state == "curling_up_phase1" ||
        state == "curling_up_phase2" ||
        state == "top_position" ||
        state == "full_contraction";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}