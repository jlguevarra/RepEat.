// workout_logic/dumbbell_flyes_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellFlyesLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Check if essential landmarks are visible
    if (leftWrist == null || rightWrist == null ||
        leftShoulder == null || rightShoulder == null ||
        leftElbow == null || rightElbow == null) {
      updateFormStatus("Ensure arms and shoulders are visible", false);
      return "no_pose";
    }

    // Check for proper flyes form
    final formCheck = _checkFlyesForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate chest expansion (distance between wrists relative to shoulders)
    final chestDistance = (leftWrist.x - rightWrist.x).abs();
    final shoulderDistance = (leftShoulder.x - rightShoulder.x).abs();
    final relativeDistance = chestDistance / shoulderDistance;

    // Calculate elbow angles to ensure proper form
    final leftElbowAngle = _calculateElbowAngle(leftShoulder, leftElbow, leftWrist);
    final rightElbowAngle = _calculateElbowAngle(rightShoulder, rightElbow, rightWrist);
    final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    // Analyze flyes movement
    return _analyzeFlyesMovement(relativeDistance, avgElbowAngle, updateFormStatus);
  }

  static FormCheckResult _checkFlyesForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Check if lying on bench (hips and shoulders at similar height)
    if (leftHip != null && rightHip != null) {
      final hipShoulderAlignmentLeft = (leftHip.y - leftShoulder!.y).abs();
      final hipShoulderAlignmentRight = (rightHip.y - rightShoulder!.y).abs();

      if (hipShoulderAlignmentLeft > 0.3 || hipShoulderAlignmentRight > 0.3) {
        updateFormStatus("Lie on bench with feet flat", false);
        return FormCheckResult(false, "not_on_bench");
      }
    }

    // Check elbow angle for proper flyes form (should be slightly bent)
    final leftElbowAngle = _calculateElbowAngle(leftShoulder!, leftElbow!, leftWrist!);
    final rightElbowAngle = _calculateElbowAngle(rightShoulder!, rightElbow!, rightWrist!);

    if (leftElbowAngle < 100 || rightElbowAngle < 100) {
      updateFormStatus("Keep elbows slightly bent", false);
      return FormCheckResult(false, "elbows_too_straight");
    }

    if (leftElbowAngle > 160 || rightElbowAngle > 160) {
      updateFormStatus("Don't bend elbows too much", false);
      return FormCheckResult(false, "elbows_too_bent");
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

  static String _analyzeFlyesMovement(double relativeDistance, double elbowAngle, Function(String, bool) updateFormStatus) {
    // Check if elbows are maintaining proper angle
    if (elbowAngle < 100 || elbowAngle > 160) {
      updateFormStatus("Maintain slight elbow bend (100-160°)", false);
      return "improper_elbow_angle";
    }

    if (relativeDistance < 1.1) {
      updateFormStatus("Arms together over chest - ready to fly", true);
      return "starting_position";
    } else if (relativeDistance >= 1.1 && relativeDistance < 1.5) {
      updateFormStatus("Opening arms wide - controlled descent", true);
      return "descending_phase1";
    } else if (relativeDistance >= 1.5 && relativeDistance < 1.9) {
      updateFormStatus("Wide stretch - feel chest expansion", true);
      return "descending_phase2";
    } else if (relativeDistance >= 1.9 && relativeDistance < 2.3) {
      updateFormStatus("Full stretch! Squeeze chest to return", true);
      return "full_stretch";
    } else if (relativeDistance >= 2.3) {
      updateFormStatus("Maximum stretch! Don't overextend", true);
      return "max_stretch";
    } else if (relativeDistance >= 1.5 && relativeDistance < 1.9) {
      updateFormStatus("Bringing arms together - squeeze chest", true);
      return "ascending_phase1";
    } else if (relativeDistance >= 1.1 && relativeDistance < 1.5) {
      updateFormStatus("Almost together - continue squeezing", true);
      return "ascending_phase2";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to starting position after full stretch
    return (previousState == "full_stretch" && currentState == "starting_position") ||
        (previousState == "max_stretch" && currentState == "starting_position") ||
        (previousState == "ascending_phase2" && currentState == "starting_position");
  }

  static bool isValidForm(String state) {
    return state == "starting_position" ||
        state == "descending_phase1" ||
        state == "descending_phase2" ||
        state == "full_stretch" ||
        state == "max_stretch" ||
        state == "ascending_phase1" ||
        state == "ascending_phase2";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}