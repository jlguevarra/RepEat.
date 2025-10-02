// workout_logic/dumbbell_squats_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellSquatsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // Check if essential landmarks are visible
    if (leftHip == null || rightHip == null ||
        leftKnee == null || rightKnee == null ||
        leftAnkle == null || rightAnkle == null ||
        leftShoulder == null || rightShoulder == null) {
      updateFormStatus("Ensure full body is visible", false);
      return "no_pose";
    }

    // Check for proper squat form
    final formCheck = _checkSquatForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate knee angles for both legs
    final leftKneeAngle = _calculateKneeAngle(leftHip, leftKnee, leftAnkle);
    final rightKneeAngle = _calculateKneeAngle(rightHip, rightKnee, rightAnkle);
    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    // Calculate hip angles for form validation
    final leftHipAngle = _calculateHipAngle(leftShoulder, leftHip, leftKnee);
    final rightHipAngle = _calculateHipAngle(rightShoulder, rightHip, rightKnee);
    final avgHipAngle = (leftHipAngle + rightHipAngle) / 2;

    // Analyze squat movement
    return _analyzeSquatMovement(avgKneeAngle, avgHipAngle, updateFormStatus);
  }

  static FormCheckResult _checkSquatForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    // Check knee alignment (knees should track over ankles)
    final leftKneeAlignment = _checkKneeAlignment(leftKnee!, leftAnkle!);
    final rightKneeAlignment = _checkKneeAlignment(rightKnee!, rightAnkle!);

    if (!leftKneeAlignment || !rightKneeAlignment) {
      updateFormStatus("Keep knees aligned over ankles", false);
      return FormCheckResult(false, "knee_alignment");
    }

    // Check torso position (should stay upright)
    final torsoAngle = _calculateTorsoAngle(leftShoulder!, rightShoulder!, leftHip!, rightHip!);
    if (torsoAngle < 30) {
      updateFormStatus("Keep chest up - don't lean forward", false);
      return FormCheckResult(false, "leaning_forward");
    }

    // Check hip stability (hips should be level)
    final hipLevel = (leftHip.y - rightHip.y).abs();
    if (hipLevel > 0.1) {
      updateFormStatus("Keep hips level", false);
      return FormCheckResult(false, "uneven_hips");
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

    // Check foot position (feet should be shoulder-width)
    final footWidth = (leftAnkle.x - rightAnkle.x).abs();
    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();

    if (footWidth < shoulderWidth * 0.8 || footWidth > shoulderWidth * 1.5) {
      updateFormStatus("Adjust stance to shoulder width", false);
      return FormCheckResult(false, "improper_stance");
    }

    return FormCheckResult(true, "good_form");
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

  static double _calculateHipAngle(PoseLandmark shoulder, PoseLandmark hip, PoseLandmark knee) {
    final radians = math.atan2(knee.y - hip.y, knee.x - hip.x) -
        math.atan2(shoulder.y - hip.y, shoulder.x - hip.x);
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

  static bool _checkKneeAlignment(PoseLandmark knee, PoseLandmark ankle) {
    // Check if knee is properly aligned over ankle
    final horizontalAlignment = (knee.x - ankle.x).abs();
    return horizontalAlignment < 0.15;
  }

  static String _analyzeSquatMovement(double kneeAngle, double hipAngle, Function(String, bool) updateFormStatus) {
    // Check for proper hip hinge
    if (hipAngle < 60) {
      updateFormStatus("Hinge at hips more", false);
      return "insufficient_hip_hinge";
    }

    if (kneeAngle > 160) {
      updateFormStatus("Standing tall - ready to squat", true);
      return "standing_start";
    } else if (kneeAngle > 130 && kneeAngle <= 160) {
      updateFormStatus("Descending - sit back into squat", true);
      return "descending_phase1";
    } else if (kneeAngle > 100 && kneeAngle <= 130) {
      updateFormStatus("Continuing down - chest up, knees out", true);
      return "descending_phase2";
    } else if (kneeAngle > 80 && kneeAngle <= 100) {
      updateFormStatus("Parallel squat! Thighs parallel to floor", true);
      return "parallel_squat";
    } else if (kneeAngle <= 80) {
      updateFormStatus("Deep squat! Drive up through heels", true);
      return "deep_squat";
    } else if (kneeAngle > 100 && kneeAngle <= 130) {
      updateFormStatus("Ascending - push through entire foot", true);
      return "ascending_phase1";
    } else if (kneeAngle > 130 && kneeAngle <= 160) {
      updateFormStatus("Rising up - squeeze glutes at top", true);
      return "ascending_phase2";
    } else if (kneeAngle > 160) {
      updateFormStatus("Standing tall - rep completed!", true);
      return "standing_complete";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to full standing position after reaching parallel or deep squat
    return (previousState == "parallel_squat" && currentState == "standing_complete") ||
        (previousState == "deep_squat" && currentState == "standing_complete") ||
        (previousState == "ascending_phase2" && currentState == "standing_complete");
  }

  static bool isValidForm(String state) {
    return state == "standing_start" ||
        state == "descending_phase1" ||
        state == "descending_phase2" ||
        state == "parallel_squat" ||
        state == "deep_squat" ||
        state == "ascending_phase1" ||
        state == "ascending_phase2" ||
        state == "standing_complete";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}