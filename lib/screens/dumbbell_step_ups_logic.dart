// workout_logic/dumbbell_step_ups_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellStepUpsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    // Check if essential landmarks are visible
    if (leftHip == null || rightHip == null ||
        leftKnee == null || rightKnee == null ||
        leftAnkle == null || rightAnkle == null ||
        leftShoulder == null || rightShoulder == null) {
      updateFormStatus("Ensure legs and torso are visible", false);
      return "no_pose";
    }

    // Check for proper step-up form
    final formCheck = _checkStepUpForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Determine which leg is stepping and analyze movement
    final stepAnalysis = _analyzeStepUpMovement(pose, updateFormStatus);

    return stepAnalysis;
  }

  static FormCheckResult _checkStepUpForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    // Check torso position (should stay upright)
    final torsoAngle = _calculateTorsoAngle(leftShoulder!, rightShoulder!, leftHip!, rightHip!);
    if (torsoAngle < 60) {
      updateFormStatus("Keep chest up - don't lean forward", false);
      return FormCheckResult(false, "leaning_forward");
    }

    // Check hip stability (hips should be relatively level)
    final hipLevel = (leftHip.y - rightHip.y).abs();
    if (hipLevel > 0.2) {
      updateFormStatus("Keep hips stable - avoid excessive tilt", false);
      return FormCheckResult(false, "hip_instability");
    }

    // Check shoulder position (should be level)
    final shoulderLevel = (leftShoulder.y - rightShoulder.y).abs();
    if (shoulderLevel > 0.15) {
      updateFormStatus("Keep shoulders level", false);
      return FormCheckResult(false, "uneven_shoulders");
    }

    // Check dumbbell position (should be at sides)
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftWrist != null && rightWrist != null) {
      final leftWristHip = (leftWrist.x - leftHip.x).abs();
      final rightWristHip = (rightWrist.x - rightHip.x).abs();

      if (leftWristHip > 0.3 || rightWristHip > 0.3) {
        updateFormStatus("Keep dumbbells close to body", false);
        return FormCheckResult(false, "dumbbells_too_far");
      }
    }

    return FormCheckResult(true, "good_form");
  }

  static String _analyzeStepUpMovement(Pose pose, Function(String, bool) updateFormStatus) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // Determine which leg is stepping (higher knee indicates stepping leg)
    final isLeftStepping = leftKnee!.y < rightKnee!.y;
    final steppingLeg = isLeftStepping ? "left" : "right";

    final steppingKnee = isLeftStepping ? leftKnee : rightKnee;
    final standingKnee = isLeftStepping ? rightKnee : leftKnee;
    final steppingAnkle = isLeftStepping ? leftAnkle! : rightAnkle!;
    final standingAnkle = isLeftStepping ? rightAnkle! : leftAnkle!;

    // Calculate key metrics
    final heightDifference = (standingKnee.y - steppingKnee.y).abs();
    final steppingKneeAngle = _calculateKneeAngle(
        isLeftStepping ? leftHip! : rightHip!,
        steppingKnee,
        steppingAnkle
    );
    final standingKneeAngle = _calculateKneeAngle(
        isLeftStepping ? rightHip! : leftHip!,
        standingKnee,
        standingAnkle
    );

    return _analyzeStepUpPhases(heightDifference, steppingKneeAngle, standingKneeAngle, steppingLeg, updateFormStatus);
  }

  static double _calculateKneeAngle(PoseLandmark hip, PoseLandmark knee, PoseLandmark ankle) {
    final radians = math.atan2(ankle.y - knee.y, ankle.x - knee.x) -
        math.atan2(hip.y - knee.y, hip.x - knee.x);
    double angle = (radians * 180.0 / math.pi).abs();

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
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

  static String _analyzeStepUpPhases(double heightDifference, double steppingKneeAngle,
      double standingKneeAngle, String steppingLeg, Function(String, bool) updateFormStatus) {

    // Check if standing leg is properly supporting (should be relatively straight)
    if (standingKneeAngle < 150 && heightDifference > 0.05) {
      updateFormStatus("Push through standing leg", false);
      return "standing_leg_bent";
    }

    if (heightDifference < 0.03) {
      updateFormStatus("Both feet on ground - ready to step", true);
      return "starting_position";
    } else if (heightDifference >= 0.03 && heightDifference < 0.07) {
      updateFormStatus("Lifting $steppingLeg leg - place foot on step", true);
      return "leg_lift_phase";
    } else if (heightDifference >= 0.07 && heightDifference < 0.12) {
      updateFormStatus("Stepping up with $steppingLeg leg - drive through heel", true);
      return "stepping_up_phase";
    } else if (heightDifference >= 0.12 && heightDifference < 0.18) {
      updateFormStatus("Top position! Stand tall on step", true);
      return "top_position";
    } else if (heightDifference >= 0.18) {
      updateFormStatus("High step! Full extension", true);
      return "full_extension";
    } else if (heightDifference >= 0.12 && heightDifference < 0.18) {
      updateFormStatus("Stepping down with opposite leg", true);
      return "stepping_down_phase1";
    } else if (heightDifference >= 0.07 && heightDifference < 0.12) {
      updateFormStatus("Lowering down - controlled movement", true);
      return "stepping_down_phase2";
    } else if (heightDifference >= 0.03 && heightDifference < 0.07) {
      updateFormStatus("Almost down - prepare for next rep", true);
      return "stepping_down_phase3";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to starting position after full step-up
    return (previousState == "full_extension" && currentState == "starting_position") ||
        (previousState == "top_position" && currentState == "starting_position") ||
        (previousState == "stepping_down_phase3" && currentState == "starting_position");
  }

  static bool isValidForm(String state) {
    return state == "starting_position" ||
        state == "leg_lift_phase" ||
        state == "stepping_up_phase" ||
        state == "top_position" ||
        state == "full_extension" ||
        state == "stepping_down_phase1" ||
        state == "stepping_down_phase2" ||
        state == "stepping_down_phase3";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}