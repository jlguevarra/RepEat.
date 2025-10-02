// workout_logic/dumbbell_rows_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellRowsLogic {
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
      updateFormStatus("Ensure back and arms are visible", false);
      return "no_pose";
    }

    // Check for proper row form
    final formCheck = _checkRowForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate elbow angles for both arms
    final leftElbowAngle = _calculateElbowAngle(leftShoulder, leftElbow, leftWrist);
    final rightElbowAngle = _calculateElbowAngle(rightShoulder, rightElbow, rightWrist);
    final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    // Calculate elbow position relative to torso
    final leftElbowPosition = _calculateElbowPosition(leftElbow, leftShoulder, leftHip);
    final rightElbowPosition = _calculateElbowPosition(rightElbow, rightShoulder, rightHip);
    final avgElbowPosition = (leftElbowPosition + rightElbowPosition) / 2;

    // Analyze row movement
    return _analyzeRowMovement(avgElbowPosition, avgElbowAngle, updateFormStatus);
  }

  static FormCheckResult _checkRowForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];

    // Check bent-over position with flat back
    final torsoAngle = _calculateTorsoAngle(leftShoulder!, leftHip!, rightHip!);
    if (torsoAngle < 30) {
      updateFormStatus("Bend forward more - torso near parallel", false);
      return FormCheckResult(false, "too_upright");
    }

    // Check back straightness (shoulders and hips alignment)
    final shoulderHipAlignmentLeft = (leftShoulder.y - leftHip.y).abs();
    final shoulderHipAlignmentRight = (rightShoulder!.y - rightHip.y).abs();

    if (shoulderHipAlignmentLeft > 0.3 || shoulderHipAlignmentRight > 0.3) {
      updateFormStatus("Keep back straight - don't round spine", false);
      return FormCheckResult(false, "rounded_back");
    }

    // Check if shoulders are level
    final shoulderLevel = (leftShoulder.y - rightShoulder.y).abs();
    if (shoulderLevel > 0.1) {
      updateFormStatus("Keep shoulders level", false);
      return FormCheckResult(false, "uneven_shoulders");
    }

    // Check dumbbell path (should be straight up and down)
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftWrist != null && rightWrist != null) {
      final wristSymmetry = (leftWrist.y - rightWrist.y).abs();
      if (wristSymmetry > 0.15) {
        updateFormStatus("Pull dumbbells evenly", false);
        return FormCheckResult(false, "asymmetric_pull");
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

  static double _calculateElbowPosition(PoseLandmark elbow, PoseLandmark shoulder, PoseLandmark hip) {
    // Calculate how far back the elbow is relative to shoulder and hip
    final horizontalPosition = (elbow.x - shoulder.x).abs();
    final verticalPosition = (elbow.y - hip.y).abs();

    // Combine both measurements for comprehensive position tracking
    return (horizontalPosition + verticalPosition) / 2;
  }

  static double _calculateTorsoAngle(PoseLandmark shoulder, PoseLandmark hip, PoseLandmark otherHip) {
    // Calculate torso angle relative to horizontal
    final verticalDiff = (shoulder.y - hip.y).abs();
    final horizontalDiff = (shoulder.x - hip.x).abs();

    if (horizontalDiff == 0) return 0;

    final angle = math.atan(verticalDiff / horizontalDiff) * 180 / math.pi;
    return angle;
  }

  static String _analyzeRowMovement(double elbowPosition, double elbowAngle, Function(String, bool) updateFormStatus) {
    // Check elbow angle for proper row form
    if (elbowAngle < 60) {
      updateFormStatus("Don't tuck elbows too close", false);
      return "elbows_too_close";
    }

    if (elbowAngle > 120) {
      updateFormStatus("Bend elbows more during pull", false);
      return "elbows_too_straight";
    }

    if (elbowPosition < 0.08) {
      updateFormStatus("Arms extended - ready to row", true);
      return "starting_position";
    } else if (elbowPosition >= 0.08 && elbowPosition < 0.12) {
      updateFormStatus("Pulling back - drive elbows up", true);
      return "ascending_phase1";
    } else if (elbowPosition >= 0.12 && elbowPosition < 0.16) {
      updateFormStatus("Continuing up - squeeze back muscles", true);
      return "ascending_phase2";
    } else if (elbowPosition >= 0.16 && elbowPosition < 0.20) {
      updateFormStatus("Full contraction! Squeeze shoulder blades", true);
      return "full_contraction";
    } else if (elbowPosition >= 0.20) {
      updateFormStatus("Maximum contraction! Lower with control", true);
      return "max_contraction";
    } else if (elbowPosition >= 0.16 && elbowPosition < 0.20) {
      updateFormStatus("Lowering weights - controlled descent", true);
      return "descending_phase1";
    } else if (elbowPosition >= 0.12 && elbowPosition < 0.16) {
      updateFormStatus("Almost extended - maintain tension", true);
      return "descending_phase2";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to starting position after full contraction
    return (previousState == "full_contraction" && currentState == "starting_position") ||
        (previousState == "max_contraction" && currentState == "starting_position") ||
        (previousState == "descending_phase2" && currentState == "starting_position");
  }

  static bool isValidForm(String state) {
    return state == "starting_position" ||
        state == "ascending_phase1" ||
        state == "ascending_phase2" ||
        state == "full_contraction" ||
        state == "max_contraction" ||
        state == "descending_phase1" ||
        state == "descending_phase2";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}