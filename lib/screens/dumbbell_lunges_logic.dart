// workout_logic/dumbbell_lunges_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellLungesLogic {
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
      updateFormStatus("Ensure full body is visible", false);
      return "no_pose";
    }

    // Check for proper lunge form
    final formCheck = _checkLungeForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate knee angles for both legs
    final leftKneeAngle = _calculateKneeAngle(leftHip, leftKnee, leftAnkle);
    final rightKneeAngle = _calculateKneeAngle(rightHip, rightKnee, rightAnkle);

    // Determine which leg is forward based on knee angles and positions
    final lungeAnalysis = _determineLungePosition(leftKneeAngle, rightKneeAngle, leftKnee, rightKnee);

    // Analyze lunge movement
    return _analyzeLungeMovement(lungeAnalysis.forwardKneeAngle, lungeAnalysis.isLeftForward, updateFormStatus);
  }

  static FormCheckResult _checkLungeForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    // Check torso alignment (should be upright)
    final leftTorsoAlignment = (leftShoulder!.y - leftHip!.y).abs();
    final rightTorsoAlignment = (rightShoulder!.y - rightHip!.y).abs();

    if (leftTorsoAlignment > 0.3 || rightTorsoAlignment > 0.3) {
      updateFormStatus("Keep torso upright - don't lean forward", false);
      return FormCheckResult(false, "leaning_forward");
    }

    // Check knee alignment (front knee shouldn't go past toes)
    final leftKneeAnkleAlignment = _checkKneeAlignment(leftKnee!, leftAnkle!);
    final rightKneeAnkleAlignment = _checkKneeAlignment(rightKnee!, rightAnkle!);

    if (!leftKneeAnkleAlignment || !rightKneeAnkleAlignment) {
      updateFormStatus("Keep front knee behind toes", false);
      return FormCheckResult(false, "knee_over_toes");
    }

    // Check hip stability (hips should be level and facing forward)
    final hipLevel = (leftHip.y - rightHip.y).abs();
    if (hipLevel > 0.15) {
      updateFormStatus("Keep hips level and square", false);
      return FormCheckResult(false, "hips_unlevel");
    }

    return FormCheckResult(true, "good_form");
  }

  static bool _checkKneeAlignment(PoseLandmark knee, PoseLandmark ankle) {
    // Check if knee is aligned properly with ankle (not too far forward)
    final horizontalAlignment = (knee.x - ankle.x).abs();
    final verticalAlignment = (knee.y - ankle.y).abs();

    // Knee should be roughly above ankle in lunge position
    return horizontalAlignment < 0.15 && verticalAlignment > 0.1;
  }

  static LungeAnalysis _determineLungePosition(double leftKneeAngle, double rightKneeAngle, PoseLandmark leftKnee, PoseLandmark rightKnee) {
    // Determine which leg is forward based on knee bend and position
    final isLeftForward = leftKneeAngle < rightKneeAngle && (leftKnee.x - rightKnee.x).abs() > 0.1;
    final isRightForward = rightKneeAngle < leftKneeAngle && (rightKnee.x - leftKnee.x).abs() > 0.1;

    if (isLeftForward) {
      return LungeAnalysis(leftKneeAngle, true);
    } else if (isRightForward) {
      return LungeAnalysis(rightKneeAngle, false);
    } else {
      // If unclear, use the more bent knee
      return leftKneeAngle < rightKneeAngle
          ? LungeAnalysis(leftKneeAngle, true)
          : LungeAnalysis(rightKneeAngle, false);
    }
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

  static String _analyzeLungeMovement(double forwardKneeAngle, bool isLeftForward, Function(String, bool) updateFormStatus) {
    final legSide = isLeftForward ? "left" : "right";

    if (forwardKneeAngle > 150) {
      updateFormStatus("Standing tall - ready to lunge", true);
      return "standing_start";
    } else if (forwardKneeAngle > 120 && forwardKneeAngle <= 150) {
      updateFormStatus("Stepping forward with $legSide leg", true);
      return "stepping_forward";
    } else if (forwardKneeAngle > 100 && forwardKneeAngle <= 120) {
      updateFormStatus("$legSide leg forward - descending", true);
      return "descending_phase";
    } else if (forwardKneeAngle > 80 && forwardKneeAngle <= 100) {
      updateFormStatus("Perfect $legSide lunge! 90° angle", true);
      return "perfect_lunge";
    } else if (forwardKneeAngle <= 80) {
      updateFormStatus("Deep $legSide lunge! Push back to start", true);
      return "deep_lunge";
    } else if (forwardKneeAngle > 100 && forwardKneeAngle <= 120) {
      updateFormStatus("Pushing back with $legSide leg", true);
      return "ascending_phase";
    } else if (forwardKneeAngle > 150) {
      updateFormStatus("Standing tall - rep completed!", true);
      return "standing_complete";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to standing position after perfect or deep lunge
    return (previousState == "perfect_lunge" && currentState == "standing_complete") ||
        (previousState == "deep_lunge" && currentState == "standing_complete") ||
        (previousState == "ascending_phase" && currentState == "standing_complete");
  }

  static bool isValidForm(String state) {
    return state == "standing_start" ||
        state == "stepping_forward" ||
        state == "descending_phase" ||
        state == "perfect_lunge" ||
        state == "deep_lunge" ||
        state == "ascending_phase" ||
        state == "standing_complete";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}

class LungeAnalysis {
  final double forwardKneeAngle;
  final bool isLeftForward;

  LungeAnalysis(this.forwardKneeAngle, this.isLeftForward);
}