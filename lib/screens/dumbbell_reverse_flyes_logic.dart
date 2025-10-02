// workout_logic/dumbbell_reverse_flyes_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellReverseFlyesLogic {
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
        leftElbow == null || rightElbow == null ||
        leftHip == null || rightHip == null) {
      updateFormStatus("Ensure arms and torso are visible", false);
      return "no_pose";
    }

    // Check for proper reverse flyes form
    final formCheck = _checkReverseFlyesForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate back expansion (distance between wrists relative to shoulders)
    final backDistance = (leftWrist.x - rightWrist.x).abs();
    final shoulderDistance = (leftShoulder.x - rightShoulder.x).abs();
    final relativeDistance = backDistance / shoulderDistance;

    // Calculate elbow angles to ensure proper form
    final leftElbowAngle = _calculateElbowAngle(leftShoulder, leftElbow, leftWrist);
    final rightElbowAngle = _calculateElbowAngle(rightShoulder, rightElbow, rightWrist);
    final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    // Calculate torso bend angle for proper positioning
    final torsoAngle = _calculateTorsoAngle(leftShoulder, leftHip, leftHip);

    // Analyze reverse flyes movement
    return _analyzeReverseFlyesMovement(relativeDistance, avgElbowAngle, torsoAngle, updateFormStatus);
  }

  static FormCheckResult _checkReverseFlyesForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Check for proper bent-over position (torso should be bent forward)
    final torsoAngle = _calculateTorsoAngle(leftShoulder!, leftHip!, leftHip);
    if (torsoAngle < 30) {
      updateFormStatus("Bend forward at hips - torso near parallel", false);
      return FormCheckResult(false, "too_upright");
    }

    // Check elbow angle for proper reverse flyes form (should be slightly bent)
    final leftElbowAngle = _calculateElbowAngle(leftShoulder, leftElbow!, leftWrist!);
    final rightElbowAngle = _calculateElbowAngle(rightShoulder!, rightElbow!, rightWrist!);

    if (leftElbowAngle < 150 || rightElbowAngle < 150) {
      updateFormStatus("Keep arms straighter - minimal elbow bend", false);
      return FormCheckResult(false, "elbows_too_bent");
    }

    // Check if arms are moving symmetrically
    final wristSymmetry = (leftWrist.y - rightWrist.y).abs();
    if (wristSymmetry > 0.15) {
      updateFormStatus("Keep arms at same height", false);
      return FormCheckResult(false, "asymmetric_movement");
    }

    // Check if shoulders are depressed (not shrugging)
    final shoulderHeight = (leftShoulder.y - leftHip.y).abs();
    if (shoulderHeight < 0.2) {
      updateFormStatus("Keep shoulders down - don't shrug", false);
      return FormCheckResult(false, "shoulders_shrugged");
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

  static double _calculateTorsoAngle(PoseLandmark shoulder, PoseLandmark hip, PoseLandmark reference) {
    // Calculate torso angle relative to vertical
    final verticalDiff = (shoulder.x - hip.x).abs();
    final horizontalDiff = (shoulder.y - hip.y).abs();

    if (horizontalDiff == 0) return 0;

    final angle = math.atan(verticalDiff / horizontalDiff) * 180 / math.pi;
    return angle;
  }

  static String _analyzeReverseFlyesMovement(double relativeDistance, double elbowAngle, double torsoAngle, Function(String, bool) updateFormStatus) {
    // Check torso position
    if (torsoAngle < 30) {
      updateFormStatus("Bend forward more - torso near parallel", false);
      return "adjust_torso_position";
    }

    // Check elbow position (should be relatively straight for reverse flyes)
    if (elbowAngle < 150) {
      updateFormStatus("Keep arms straighter", false);
      return "adjust_elbow_angle";
    }

    if (relativeDistance < 1.0) {
      updateFormStatus("Arms hanging down - ready to fly", true);
      return "starting_position";
    } else if (relativeDistance >= 1.0 && relativeDistance < 1.3) {
      updateFormStatus("Lifting arms out - squeeze shoulder blades", true);
      return "ascending_phase1";
    } else if (relativeDistance >= 1.3 && relativeDistance < 1.6) {
      updateFormStatus("Continuing up - feel rear delt contraction", true);
      return "ascending_phase2";
    } else if (relativeDistance >= 1.6 && relativeDistance < 1.9) {
      updateFormStatus("Full contraction! Squeeze and hold", true);
      return "full_contraction";
    } else if (relativeDistance >= 1.9) {
      updateFormStatus("Maximum squeeze! Don't overextend", true);
      return "max_contraction";
    } else if (relativeDistance >= 1.6 && relativeDistance < 1.9) {
      updateFormStatus("Lowering arms - controlled descent", true);
      return "descending_phase1";
    } else if (relativeDistance >= 1.3 && relativeDistance < 1.6) {
      updateFormStatus("Almost back to start - maintain form", true);
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