// workout_logic/dumbbell_windmills_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellWindmillsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    // Check if essential landmarks are visible
    if (leftWrist == null || rightWrist == null ||
        leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null ||
        leftElbow == null || rightElbow == null ||
        leftKnee == null || rightKnee == null) {
      updateFormStatus("Ensure arms, torso, and legs are visible", false);
      return "no_pose";
    }

    // Check for proper windmill form
    final formCheck = _checkWindmillForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate arm movement and determine phase
    final windmillAnalysis = _analyzeWindmillMovement(pose, updateFormStatus);

    return windmillAnalysis;
  }

  static FormCheckResult _checkWindmillForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // Check standing position with straight legs
    final leftLegAngle = _calculateLegAngle(leftHip!, leftKnee!, pose.landmarks[PoseLandmarkType.leftAnkle]);
    final rightLegAngle = _calculateLegAngle(rightHip!, rightKnee!, pose.landmarks[PoseLandmarkType.rightAnkle]);

    if (leftLegAngle < 160 || rightLegAngle < 160) {
      updateFormStatus("Stand with legs straight", false);
      return FormCheckResult(false, "bent_legs");
    }

    // Check shoulder stability (shoulders should be level at start)
    final shoulderLevel = (leftShoulder!.y - rightShoulder!.y).abs();
    if (shoulderLevel > 0.1) {
      updateFormStatus("Start with level shoulders", false);
      return FormCheckResult(false, "uneven_shoulders");
    }

    // Check hip stability (hips should be level at start)
    final hipLevel = (leftHip.y - rightHip.y).abs();
    if (hipLevel > 0.1) {
      updateFormStatus("Start with level hips", false);
      return FormCheckResult(false, "uneven_hips");
    }

    // Check arm symmetry at start
    final armSymmetry = (leftWrist!.y - rightWrist!.y).abs();
    if (armSymmetry > 0.15) {
      updateFormStatus("Start with arms at same height", false);
      return FormCheckResult(false, "asymmetric_start");
    }

    return FormCheckResult(true, "good_form");
  }

  static String _analyzeWindmillMovement(Pose pose, Function(String, bool) updateFormStatus) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Determine windmill direction and phase
    final isLeftArmUp = leftWrist!.y < rightWrist!.y;
    final isRightArmUp = rightWrist.y < leftWrist.y;

    final upArm = isLeftArmUp ? "left" : "right";
    final downArm = isLeftArmUp ? "right" : "left";

    final upWrist = isLeftArmUp ? leftWrist : rightWrist;
    final downWrist = isLeftArmUp ? rightWrist : leftWrist;
    final upShoulder = isLeftArmUp ? leftShoulder! : rightShoulder!;

    // Calculate arm positions
    final upArmHeight = (upWrist.y - upShoulder.y).abs();
    final downArmHeight = (downWrist.y - upShoulder.y).abs();
    final armSeparation = (upWrist.y - downWrist.y).abs();

    return _analyzeWindmillPhases(upArmHeight, downArmHeight, armSeparation, upArm, downArm, updateFormStatus);
  }

  static double _calculateLegAngle(PoseLandmark hip, PoseLandmark knee, PoseLandmark? ankle) {
    if (ankle == null) return 180.0; // Assume straight leg if ankle not visible

    final radians = math.atan2(ankle.y - knee.y, ankle.x - knee.x) -
        math.atan2(hip.y - knee.y, hip.x - knee.x);
    double angle = (radians * 180.0 / math.pi).abs();

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  static String _analyzeWindmillPhases(double upArmHeight, double downArmHeight,
      double armSeparation, String upArm, String downArm, Function(String, bool) updateFormStatus) {

    // Check for proper windmill form (one arm up, one arm down)
    if (armSeparation < 0.05) {
      updateFormStatus("Arms at sides - ready for windmill", true);
      return "starting_position";
    } else if (armSeparation >= 0.05 && armSeparation < 0.15) {
      updateFormStatus("$upArm arm rising, $downArm arm lowering", true);
      return "windmill_phase1";
    } else if (armSeparation >= 0.15 && armSeparation < 0.25) {
      updateFormStatus("$upArm arm up, $downArm arm down - good range", true);
      return "windmill_phase2";
    } else if (armSeparation >= 0.25 && armSeparation < 0.35) {
      updateFormStatus("Full windmill! $upArm arm high, $downArm arm low", true);
      return "full_windmill";
    } else if (armSeparation >= 0.35) {
      updateFormStatus("Maximum stretch! Return to center", true);
      return "max_stretch";
    } else if (armSeparation >= 0.25 && armSeparation < 0.35) {
      updateFormStatus("Returning to center - controlled movement", true);
      return "returning_phase1";
    } else if (armSeparation >= 0.15 && armSeparation < 0.25) {
      updateFormStatus("Almost centered - prepare to switch sides", true);
      return "returning_phase2";
    } else if (armSeparation >= 0.05 && armSeparation < 0.15) {
      final oppositeUpArm = upArm == "left" ? "right" : "left";
      updateFormStatus("Centered - ready for $oppositeUpArm side", true);
      return "centered_switch";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when completing full windmill on one side and returning to center
    // This allows counting each side separately
    return (previousState == "full_windmill" && currentState == "centered_switch") ||
        (previousState == "max_stretch" && currentState == "centered_switch") ||
        (previousState == "returning_phase2" && currentState == "centered_switch");
  }

  static bool isValidForm(String state) {
    return state == "starting_position" ||
        state == "windmill_phase1" ||
        state == "windmill_phase2" ||
        state == "full_windmill" ||
        state == "max_stretch" ||
        state == "returning_phase1" ||
        state == "returning_phase2" ||
        state == "centered_switch";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}