// workout_logic/dumbbell_side_bends_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellSideBendsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    // Check if essential landmarks are visible
    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null ||
        leftWrist == null || rightWrist == null ||
        leftKnee == null || rightKnee == null) {
      updateFormStatus("Ensure torso, arms, and legs are visible", false);
      return "no_pose";
    }

    // Check for proper side bend form
    final formCheck = _checkSideBendForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Calculate lateral bend and determine direction
    final bendAnalysis = _calculateSideBend(leftShoulder, rightShoulder, leftHip, rightHip, leftWrist, rightWrist);

    // Analyze side bend movement
    return _analyzeSideBendMovement(bendAnalysis.bendAmount, bendAnalysis.direction, updateFormStatus);
  }

  static FormCheckResult _checkSideBendForm(Pose pose, Function(String, bool) updateFormStatus) {
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

    // Check for proper upright starting position
    final shoulderAlignment = (leftShoulder!.y - rightShoulder!.y).abs();
    final hipAlignment = (leftHip.y - rightHip.y).abs();

    if (shoulderAlignment > 0.05 || hipAlignment > 0.05) {
      updateFormStatus("Start from upright position", false);
      return FormCheckResult(false, "not_upright");
    }

    // Check for twisting (shoulders should stay square)
    final shoulderHipAlignment = _checkShoulderHipAlignment(leftShoulder, rightShoulder, leftHip, rightHip);
    if (!shoulderHipAlignment) {
      updateFormStatus("Keep shoulders square - don't twist", false);
      return FormCheckResult(false, "twisting");
    }

    // Check dumbbell position (should be at sides)
    final leftWristHip = (leftWrist!.x - leftHip.x).abs();
    final rightWristHip = (rightWrist!.x - rightHip.x).abs();

    if (leftWristHip > 0.2 || rightWristHip > 0.2) {
      updateFormStatus("Keep dumbbells close to sides", false);
      return FormCheckResult(false, "dumbbells_too_far");
    }

    return FormCheckResult(true, "good_form");
  }

  static SideBendAnalysis _calculateSideBend(PoseLandmark leftShoulder, PoseLandmark rightShoulder,
      PoseLandmark leftHip, PoseLandmark rightHip, PoseLandmark leftWrist, PoseLandmark rightWrist) {

    // Calculate bend amount based on shoulder-hip difference
    final leftSideCompression = (leftShoulder.y - leftHip.y).abs();
    final rightSideCompression = (rightShoulder.y - rightHip.y).abs();
    final bendAmount = (leftSideCompression - rightSideCompression).abs();

    // Determine bend direction
    final isLeftBend = leftSideCompression > rightSideCompression;
    final direction = isLeftBend ? "left" : "right";

    return SideBendAnalysis(bendAmount, direction);
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

  static bool _checkShoulderHipAlignment(PoseLandmark leftShoulder, PoseLandmark rightShoulder,
      PoseLandmark leftHip, PoseLandmark rightHip) {
    // Check if shoulders and hips are aligned (no twisting)
    final shoulderAngle = math.atan2(rightShoulder.y - leftShoulder.y, rightShoulder.x - leftShoulder.x);
    final hipAngle = math.atan2(rightHip.y - leftHip.y, rightHip.x - leftHip.x);

    return (shoulderAngle - hipAngle).abs() < 0.3; // Allow small natural variation
  }

  static String _analyzeSideBendMovement(double bendAmount, String direction, Function(String, bool) updateFormStatus) {
    final side = direction == "left" ? "left" : "right";

    if (bendAmount < 0.03) {
      updateFormStatus("Upright position - ready to bend", true);
      return "upright_position";
    } else if (bendAmount >= 0.03 && bendAmount < 0.07) {
      updateFormStatus("Bending to $side side - feel oblique stretch", true);
      return "bending_phase1";
    } else if (bendAmount >= 0.07 && bendAmount < 0.11) {
      updateFormStatus("Good $side bend - continue stretching", true);
      return "bending_phase2";
    } else if (bendAmount >= 0.11 && bendAmount < 0.15) {
      updateFormStatus("Full $side bend! Squeeze obliques", true);
      return "full_bend";
    } else if (bendAmount >= 0.15) {
      updateFormStatus("Deep $side stretch! Return to center", true);
      return "deep_bend";
    } else if (bendAmount >= 0.07 && bendAmount < 0.11) {
      updateFormStatus("Returning to center - controlled movement", true);
      return "returning_phase1";
    } else if (bendAmount >= 0.03 && bendAmount < 0.07) {
      updateFormStatus("Almost upright - maintain core tension", true);
      return "returning_phase2";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to upright position after full bend
    return (previousState == "full_bend" && currentState == "upright_position") ||
        (previousState == "deep_bend" && currentState == "upright_position") ||
        (previousState == "returning_phase2" && currentState == "upright_position");
  }

  static bool isValidForm(String state) {
    return state == "upright_position" ||
        state == "bending_phase1" ||
        state == "bending_phase2" ||
        state == "full_bend" ||
        state == "deep_bend" ||
        state == "returning_phase1" ||
        state == "returning_phase2";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}

class SideBendAnalysis {
  final double bendAmount;
  final String direction;

  SideBendAnalysis(this.bendAmount, this.direction);
}