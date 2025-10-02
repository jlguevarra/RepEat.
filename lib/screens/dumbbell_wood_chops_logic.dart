// workout_logic/dumbbell_wood_chops_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellWoodChopsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];

    // Check if essential landmarks are visible
    if (leftWrist == null || rightWrist == null ||
        leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null ||
        leftKnee == null || rightKnee == null ||
        leftElbow == null || rightElbow == null) {
      updateFormStatus("Ensure arms, torso, and legs are visible", false);
      return "no_pose";
    }

    // Check for proper wood chop form
    final formCheck = _checkWoodChopForm(pose, updateFormStatus);
    if (!formCheck.isValid) {
      return formCheck.state;
    }

    // Analyze wood chop movement and direction
    final chopAnalysis = _analyzeWoodChopMovement(pose, updateFormStatus);

    return chopAnalysis;
  }

  static FormCheckResult _checkWoodChopForm(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // Check standing position with slight knee bend
    final leftKneeAngle = _calculateKneeAngle(leftHip!, leftKnee!, pose.landmarks[PoseLandmarkType.leftAnkle]);
    final rightKneeAngle = _calculateKneeAngle(rightHip!, rightKnee!, pose.landmarks[PoseLandmarkType.rightAnkle]);

    if (leftKneeAngle < 150 || rightKneeAngle < 150) {
      updateFormStatus("Keep slight bend in knees", false);
      return FormCheckResult(false, "knees_too_bent");
    }

    // Check core engagement (torso should rotate, not just arms)
    final torsoRotation = _calculateTorsoRotation(leftShoulder!, rightShoulder!, leftHip, rightHip);
    if (torsoRotation < 0.1) {
      updateFormStatus("Rotate torso with the movement", false);
      return FormCheckResult(false, "no_torso_rotation");
    }

    // Check arm position (should maintain slight bend)
    final leftElbowAngle = _calculateElbowAngle(leftShoulder, pose.landmarks[PoseLandmarkType.leftElbow]!, leftWrist!);
    final rightElbowAngle = _calculateElbowAngle(rightShoulder, pose.landmarks[PoseLandmarkType.rightElbow]!, rightWrist!);

    if (leftElbowAngle < 150 || rightElbowAngle < 150) {
      updateFormStatus("Keep arms straighter", false);
      return FormCheckResult(false, "arms_too_bent");
    }

    // Check for symmetric hand position (both hands should move together)
    final wristSeparation = (leftWrist.x - rightWrist.x).abs();
    if (wristSeparation > 0.3) {
      updateFormStatus("Keep hands close together", false);
      return FormCheckResult(false, "hands_too_far");
    }

    // Check hip stability (should pivot, not shift)
    final hipStability = (leftHip.y - rightHip.y).abs();
    if (hipStability > 0.2) {
      updateFormStatus("Stabilize hips - pivot don't shift", false);
      return FormCheckResult(false, "hip_instability");
    }

    return FormCheckResult(true, "good_form");
  }

  static String _analyzeWoodChopMovement(Pose pose, Function(String, bool) updateFormStatus) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Determine chop direction and analyze movement
    final wristMidY = (leftWrist!.y + rightWrist!.y) / 2;
    final shoulderMidY = (leftShoulder!.y + rightShoulder!.y) / 2;
    final hipMidY = (leftHip!.y + rightHip!.y) / 2;

    final verticalMovement = (wristMidY - shoulderMidY).abs();
    final horizontalPosition = (leftWrist.x + rightWrist.x) / 2;

    // Determine if it's high-to-low or low-to-high chop
    final isHighToLow = wristMidY > shoulderMidY;
    final isLeftSide = horizontalPosition < 0.5;

    final direction = isHighToLow ? "high_to_low" : "low_to_high";
    final side = isLeftSide ? "left" : "right";

    return _analyzeWoodChopPhases(verticalMovement, direction, side, updateFormStatus);
  }

  static double _calculateKneeAngle(PoseLandmark hip, PoseLandmark knee, PoseLandmark? ankle) {
    if (ankle == null) return 160.0; // Assume proper angle if ankle not visible

    final radians = math.atan2(ankle.y - knee.y, ankle.x - knee.x) -
        math.atan2(hip.y - knee.y, hip.x - knee.x);
    double angle = (radians * 180.0 / math.pi).abs();

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
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

  static double _calculateTorsoRotation(PoseLandmark leftShoulder, PoseLandmark rightShoulder,
      PoseLandmark leftHip, PoseLandmark rightHip) {
    final shoulderVectorX = rightShoulder.x - leftShoulder.x;
    final shoulderVectorY = rightShoulder.y - leftShoulder.y;

    final hipVectorX = rightHip.x - leftHip.x;
    final hipVectorY = rightHip.y - leftHip.y;

    // Calculate angle between shoulder line and hip line
    final dotProduct = shoulderVectorX * hipVectorX + shoulderVectorY * hipVectorY;
    final magnitudeShoulder = math.sqrt(shoulderVectorX * shoulderVectorX + shoulderVectorY * shoulderVectorY);
    final magnitudeHip = math.sqrt(hipVectorX * hipVectorX + hipVectorY * hipVectorY);

    if (magnitudeShoulder == 0 || magnitudeHip == 0) return 0.0;

    final cosAngle = dotProduct / (magnitudeShoulder * magnitudeHip);
    final angle = math.acos(cosAngle.clamp(-1.0, 1.0));

    return angle;
  }

  static String _analyzeWoodChopPhases(double verticalMovement, String direction, String side,
      Function(String, bool) updateFormStatus) {

    final chopType = direction == "high_to_low" ? "downward" : "upward";
    final startPosition = direction == "high_to_low" ? "high" : "low";
    final endPosition = direction == "high_to_low" ? "low" : "high"; // Fixed: removed const

    if (verticalMovement < 0.05) {
      updateFormStatus("Start position - $startPosition on $side side", true);
      return "starting_position";
    } else if (verticalMovement >= 0.05 && verticalMovement < 0.12) {
      updateFormStatus("$chopType chop - engage core and obliques", true);
      return "chopping_phase1";
    } else if (verticalMovement >= 0.12 && verticalMovement < 0.19) {
      updateFormStatus("Continuing $chopType - rotate torso", true);
      return "chopping_phase2";
    } else if (verticalMovement >= 0.19 && verticalMovement < 0.26) {
      updateFormStatus("Full $chopType chop! Feel core engagement", true);
      return "full_chop";
    } else if (verticalMovement >= 0.26) {
      updateFormStatus("Maximum extension! Control the return", true);
      return "max_extension";
    } else if (verticalMovement >= 0.19 && verticalMovement < 0.26) {
      updateFormStatus("Returning to start - controlled motion", true);
      return "returning_phase1";
    } else if (verticalMovement >= 0.12 && verticalMovement < 0.19) {
      updateFormStatus("Almost back - maintain core tension", true);
      return "returning_phase2";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to starting position after full chop
    return (previousState == "full_chop" && currentState == "starting_position") ||
        (previousState == "max_extension" && currentState == "starting_position") ||
        (previousState == "returning_phase2" && currentState == "starting_position");
  }

  static bool isValidForm(String state) {
    return state == "starting_position" ||
        state == "chopping_phase1" ||
        state == "chopping_phase2" ||
        state == "full_chop" ||
        state == "max_extension" ||
        state == "returning_phase1" ||
        state == "returning_phase2";
  }
}

class FormCheckResult {
  final bool isValid;
  final String state;

  FormCheckResult(this.isValid, this.state);
}