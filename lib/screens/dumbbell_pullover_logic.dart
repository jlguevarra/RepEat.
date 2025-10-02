// workout_logic/dumbbell_pullover_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellPulloverLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];

    // Check if essential landmarks are visible
    if (leftWrist == null || rightWrist == null ||
        leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null ||
        leftElbow == null || rightElbow == null) {
      updateFormStatus("Ensure arms and torso are visible", false);
      return "no_pose";
    }

    // Check for proper pullover form
    final formCheck = _checkPulloverForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate arm extension (distance from shoulders to wrists)
    final leftArmExtension = _calculateArmExtension(leftShoulder, leftWrist);
    final rightArmExtension = _calculateArmExtension(rightShoulder, rightWrist);
    final avgArmExtension = (leftArmExtension + rightArmExtension) / 2;

    // Calculate elbow angles to ensure proper form
    final leftElbowAngle = _calculateElbowAngle(leftShoulder, leftElbow, leftWrist);
    final rightElbowAngle = _calculateElbowAngle(rightShoulder, rightElbow, rightWrist);
    final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    // Analyze pullover movement
    return _analyzePulloverMovement(avgArmExtension, avgElbowAngle, updateFormStatus);
  }

  static FormCheckResult _checkPulloverForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];

    // Check if lying on bench (hips lower than shoulders)
    final avgHipY = (leftHip!.y + rightHip!.y) / 2;
    final avgShoulderY = (leftShoulder!.y + rightShoulder!.y) / 2;
    final isLyingPosition = avgHipY > avgShoulderY;

    if (!isLyingPosition) {
      updateFormStatus("Lie on bench with feet flat", false);
      return FormCheckResult(false, "not_lying");
    }

    // Check elbow angle for proper pullover form (should be slightly bent)
    final leftElbowAngle = _calculateElbowAngle(leftShoulder, leftElbow!, leftWrist!);
    final rightElbowAngle = _calculateElbowAngle(rightShoulder, rightElbow!, rightWrist!);

    if (leftElbowAngle < 100 || rightElbowAngle < 100) {
      updateFormStatus("Keep elbows slightly bent", false);
      return FormCheckResult(false, "elbows_too_straight");
    }

    if (leftElbowAngle > 160 || rightElbowAngle > 160) {
      updateFormStatus("Don't bend elbows too much", false);
      return FormCheckResult(false, "elbows_too_bent");
    }

    // Check if arms are moving together (symmetric movement)
    final wristSymmetry = (leftWrist.y - rightWrist.y).abs();
    if (wristSymmetry > 0.2) {
      updateFormStatus("Keep arms moving together", false);
      return FormCheckResult(false, "asymmetric_movement");
    }

    return FormCheckResult(true, "good_form");
  }

  static double _calculateArmExtension(PoseLandmark shoulder, PoseLandmark wrist) {
    // Calculate the vertical distance from shoulder to wrist
    return (wrist.y - shoulder.y).abs();
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

  static String _analyzePulloverMovement(double armExtension, double elbowAngle, Function(String, bool) updateFormStatus) {
    // Check if elbows are maintaining proper angle
    if (elbowAngle < 100 || elbowAngle > 160) {
      updateFormStatus("Maintain slight elbow bend (100-160°)", false);
      return "improper_elbow_angle";
    }

    if (armExtension < 0.05) {
      updateFormStatus("Dumbbell over chest - ready to pullover", true);
      return "starting_position";
    } else if (armExtension >= 0.05 && armExtension < 0.12) {
      updateFormStatus("Lowering behind head - controlled descent", true);
      return "descending_phase1";
    } else if (armExtension >= 0.12 && armExtension < 0.19) {
      updateFormStatus("Feeling lat stretch - continue lowering", true);
      return "descending_phase2";
    } else if (armExtension >= 0.19 && armExtension < 0.26) {
      updateFormStatus("Full stretch! Arms parallel to floor", true);
      return "full_stretch";
    } else if (armExtension >= 0.26) {
      updateFormStatus("Maximum extension! Pull back to chest", true);
      return "max_extension";
    } else if (armExtension >= 0.19 && armExtension < 0.26) {
      updateFormStatus("Pulling back to chest - squeeze lats", true);
      return "ascending_phase1";
    } else if (armExtension >= 0.12 && armExtension < 0.19) {
      updateFormStatus("Almost back to chest - continue squeezing", true);
      return "ascending_phase2";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to starting position after full extension
    return (previousState == "full_stretch" && currentState == "starting_position") ||
        (previousState == "max_extension" && currentState == "starting_position") ||
        (previousState == "ascending_phase2" && currentState == "starting_position");
  }

  static bool isValidForm(String state) {
    return state == "starting_position" ||
        state == "descending_phase1" ||
        state == "descending_phase2" ||
        state == "full_stretch" ||
        state == "max_extension" ||
        state == "ascending_phase1" ||
        state == "ascending_phase2";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}