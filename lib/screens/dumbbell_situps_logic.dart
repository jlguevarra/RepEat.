// workout_logic/dumbbell_situps_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellSitupsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // Check if essential landmarks are visible
    if (nose == null || leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null || leftKnee == null || rightKnee == null) {
      updateFormStatus("Ensure upper body, hips, and knees are visible", false);
      return "no_pose";
    }

    // Check for proper situp form
    final formCheck = _checkSitupForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate torso angle (primary movement indicator)
    final torsoAngle = _calculateTorsoAngle(leftShoulder, rightShoulder, leftHip, rightHip);

    // Calculate hip flexion
    final hipFlexion = _calculateHipFlexion(leftShoulder, leftHip, leftKnee);

    // Analyze situp movement
    return _analyzeSitupMovement(torsoAngle, hipFlexion, updateFormStatus);
  }

  static FormCheckResult _checkSitupForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // Check lying position (shoulders lower than hips)
    final avgShoulderY = (leftShoulder!.y + rightShoulder!.y) / 2;
    final avgHipY = (leftHip!.y + rightHip!.y) / 2;

    if (avgShoulderY < avgHipY) {
      updateFormStatus("Lie flat on back with knees bent", false);
      return FormCheckResult(false, "not_lying_flat");
    }

    // Check knee position (should be bent around 90 degrees)
    final leftKneeAngle = _calculateKneeAngle(leftHip, leftKnee!, leftAnkle);
    final rightKneeAngle = _calculateKneeAngle(rightHip, rightKnee!, rightAnkle);

    if (leftKneeAngle < 60 || rightKneeAngle < 60 || leftKneeAngle > 120 || rightKneeAngle > 120) {
      updateFormStatus("Keep knees bent at 90° angle", false);
      return FormCheckResult(false, "improper_knee_angle");
    }

    // Check feet position (should be flat on floor)
    if (leftAnkle != null && rightAnkle != null) {
      final ankleKneeAlignment = (leftAnkle.y - leftKnee.y).abs() + (rightAnkle.y - rightKnee.y).abs();
      if (ankleKneeAlignment > 0.3) {
        updateFormStatus("Keep feet flat on floor", false);
        return FormCheckResult(false, "feet_not_flat");
      }
    }

    // Check for proper dumbbell position (should be at chest)
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftWrist != null && rightWrist != null) {
      final wristChestPosition = _checkDumbbellPosition(leftWrist, rightWrist, leftShoulder, rightShoulder);
      if (!wristChestPosition) {
        updateFormStatus("Hold dumbbell at chest", false);
        return FormCheckResult(false, "improper_dumbbell_position");
      }
    }

    // Check for neck strain (nose shouldn't lead the movement)
    final nose = pose.landmarks[PoseLandmarkType.nose];
    if (nose != null) {
      final neckAlignment = (nose.y - leftShoulder.y).abs();
      if (neckAlignment > 0.4) {
        updateFormStatus("Lead with chest, not neck", false);
        return FormCheckResult(false, "neck_strain");
      }
    }

    return FormCheckResult(true, "good_form");
  }

  static double _calculateTorsoAngle(PoseLandmark leftShoulder, PoseLandmark rightShoulder,
      PoseLandmark leftHip, PoseLandmark rightHip) {
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipMidY = (leftHip.y + rightHip.y) / 2;

    // Calculate the angle between torso and horizontal
    final verticalDiff = (shoulderMidY - hipMidY).abs();
    final horizontalDiff = 1.0; // Reference horizontal distance

    final angle = math.atan(verticalDiff / horizontalDiff) * 180 / math.pi;
    return angle;
  }

  static double _calculateHipFlexion(PoseLandmark shoulder, PoseLandmark hip, PoseLandmark knee) {
    // Calculate hip flexion angle
    final radians = math.atan2(knee.y - hip.y, knee.x - hip.x) -
        math.atan2(shoulder.y - hip.y, shoulder.x - hip.x);
    double angle = (radians * 180.0 / math.pi).abs();

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  static double _calculateKneeAngle(PoseLandmark hip, PoseLandmark knee, PoseLandmark? ankle) {
    if (ankle == null) return 90.0; // Assume proper angle if ankle not visible

    final radians = math.atan2(ankle.y - knee.y, ankle.x - knee.x) -
        math.atan2(hip.y - knee.y, hip.x - knee.x);
    double angle = (radians * 180.0 / math.pi).abs();

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  static bool _checkDumbbellPosition(PoseLandmark leftWrist, PoseLandmark rightWrist,
      PoseLandmark leftShoulder, PoseLandmark rightShoulder) {
    // Check if dumbbells are positioned properly at chest
    final leftWristShoulder = (leftWrist.y - leftShoulder.y).abs();
    final rightWristShoulder = (rightWrist.y - rightShoulder.y).abs();

    return leftWristShoulder < 0.2 && rightWristShoulder < 0.2;
  }

  static String _analyzeSitupMovement(double torsoAngle, double hipFlexion, Function(String, bool) updateFormStatus) {
    // Check for proper hip flexion (should maintain throughout)
    if (hipFlexion < 60 || hipFlexion > 120) {
      updateFormStatus("Maintain 90° knee bend", false);
      return "adjust_knee_position";
    }

    if (torsoAngle < 20) {
      updateFormStatus("Lying flat - engage core to curl up", true);
      return "lying_position";
    } else if (torsoAngle >= 20 && torsoAngle < 40) {
      updateFormStatus("Curling up - lead with chest", true);
      return "ascending_phase1";
    } else if (torsoAngle >= 40 && torsoAngle < 60) {
      updateFormStatus("Continuing up - squeeze abs", true);
      return "ascending_phase2";
    } else if (torsoAngle >= 60 && torsoAngle < 80) {
      updateFormStatus("Sitting up! Chest toward knees", true);
      return "sitting_position";
    } else if (torsoAngle >= 80) {
      updateFormStatus("Full situp! Lower with control", true);
      return "full_situp";
    } else if (torsoAngle >= 60 && torsoAngle < 80) {
      updateFormStatus("Lowering down - controlled descent", true);
      return "descending_phase1";
    } else if (torsoAngle >= 40 && torsoAngle < 60) {
      updateFormStatus("Almost down - maintain core tension", true);
      return "descending_phase2";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to lying position after full situp
    return (previousState == "full_situp" && currentState == "lying_position") ||
        (previousState == "sitting_position" && currentState == "lying_position") ||
        (previousState == "descending_phase2" && currentState == "lying_position");
  }

  static bool isValidForm(String state) {
    return state == "lying_position" ||
        state == "ascending_phase1" ||
        state == "ascending_phase2" ||
        state == "sitting_position" ||
        state == "full_situp" ||
        state == "descending_phase1" ||
        state == "descending_phase2";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}