// workout_logic/dumbbell_deadlifts_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellDeadliftsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // Check if essential landmarks are visible
    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null ||
        leftKnee == null || rightKnee == null ||
        leftAnkle == null || rightAnkle == null) {
      updateFormStatus("Ensure full body is visible", false);
      return "no_pose";
    }

    // Check for proper deadlift form
    final formCheck = _checkDeadliftForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate hip hinge angle (primary movement indicator)
    final leftHipAngle = _calculateHipAngle(leftShoulder, leftHip, leftKnee);
    final rightHipAngle = _calculateHipAngle(rightShoulder, rightHip, rightKnee);
    final avgHipAngle = (leftHipAngle + rightHipAngle) / 2;

    // Calculate knee bend angle
    final leftKneeAngle = _calculateKneeAngle(leftHip, leftKnee, leftAnkle);
    final rightKneeAngle = _calculateKneeAngle(rightHip, rightKnee, rightAnkle);
    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    // Analyze deadlift movement
    return _analyzeDeadliftMovement(avgHipAngle, avgKneeAngle, updateFormStatus);
  }

  static FormCheckResult _checkDeadliftForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    // Check back straightness (shoulders and hips alignment)
    final shoulderHipAlignmentLeft = (leftShoulder!.y - leftHip!.y).abs();
    final shoulderHipAlignmentRight = (rightShoulder!.y - rightHip!.y).abs();

    if (shoulderHipAlignmentLeft > 0.3 || shoulderHipAlignmentRight > 0.3) {
      updateFormStatus("Keep back straight - don't round spine", false);
      return FormCheckResult(false, "rounded_back");
    }

    // Check dumbbell position (wrists should be near shins)
    if (leftWrist != null && rightWrist != null && leftKnee != null && rightKnee != null) {
      final leftWristToKnee = (leftWrist.y - leftKnee.y).abs();
      final rightWristToKnee = (rightWrist.y - rightKnee.y).abs();

      if (leftWristToKnee > 0.4 || rightWristToKnee > 0.4) {
        updateFormStatus("Keep dumbbells close to body", false);
        return FormCheckResult(false, "dumbbells_too_far");
      }
    }

    // Check if knees are tracking properly over ankles
    final leftKneeAnkle = _checkKneeAlignment(leftKnee, pose.landmarks[PoseLandmarkType.leftAnkle]);
    final rightKneeAnkle = _checkKneeAlignment(rightKnee, pose.landmarks[PoseLandmarkType.rightAnkle]);

    if (!leftKneeAnkle || !rightKneeAnkle) {
      updateFormStatus("Keep knees aligned over ankles", false);
      return FormCheckResult(false, "knee_alignment");
    }

    return FormCheckResult(true, "good_form");
  }

  static bool _checkKneeAlignment(PoseLandmark? knee, PoseLandmark? ankle) {
    if (knee == null || ankle == null) return true; // Skip check if landmarks missing

    final horizontalAlignment = (knee.x - ankle.x).abs();
    return horizontalAlignment < 0.2; // Knees should be roughly above ankles
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

  static double _calculateKneeAngle(PoseLandmark hip, PoseLandmark knee, PoseLandmark ankle) {
    final radians = math.atan2(ankle.y - knee.y, ankle.x - knee.x) -
        math.atan2(hip.y - knee.y, hip.x - knee.x);
    double angle = (radians * 180.0 / math.pi).abs();

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  static String _analyzeDeadliftMovement(double hipAngle, double kneeAngle, Function(String, bool) updateFormStatus) {
    // Deadlift has two key angles: hip hinge and knee bend

    if (hipAngle > 150 && kneeAngle > 160) {
      updateFormStatus("Standing tall - ready to descend", true);
      return "standing_start";
    } else if (hipAngle > 120 && hipAngle <= 150 && kneeAngle > 100) {
      updateFormStatus("Hinging hips back - keep chest up", true);
      return "descending_phase1";
    } else if (hipAngle > 90 && hipAngle <= 120 && kneeAngle > 80) {
      updateFormStatus("Lowering down - back straight, knees bent", true);
      return "descending_phase2";
    } else if (hipAngle <= 90 && kneeAngle <= 80) {
      updateFormStatus("Bottom position - drive through heels to stand", true);
      return "bottom_position";
    } else if (hipAngle > 90 && hipAngle <= 120 && kneeAngle > 100) {
      updateFormStatus("Ascending - drive hips forward", true);
      return "ascending_phase1";
    } else if (hipAngle > 120 && hipAngle <= 150 && kneeAngle > 140) {
      updateFormStatus("Rising up - squeeze glutes at top", true);
      return "ascending_phase2";
    } else if (hipAngle > 150 && kneeAngle > 160) {
      updateFormStatus("Standing tall - rep completed!", true);
      return "standing_complete";
    }

    updateFormStatus("Adjust form - hinge at hips, bend knees", false);
    return "adjust_form";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to full standing position after reaching bottom
    return (previousState == "bottom_position" && currentState == "standing_complete") ||
        (previousState == "ascending_phase2" && currentState == "standing_complete");
  }

  static bool isValidForm(String state) {
    return state == "standing_start" ||
        state == "descending_phase1" ||
        state == "descending_phase2" ||
        state == "bottom_position" ||
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