// workout_logic/dumbbell_bicep_curls_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellBicepCurlsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // Check if essential landmarks are visible
    if (leftShoulder == null || rightShoulder == null ||
        leftElbow == null || rightElbow == null ||
        leftWrist == null || rightWrist == null) {
      updateFormStatus("Ensure both arms and shoulders are visible", false);
      return "no_pose";
    }

    // Calculate angles for both arms
    final leftAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    final rightAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);

    // Use the average angle for analysis
    final avgAngle = (leftAngle + rightAngle) / 2;

    // Check for proper form
    if (!_isProperForm(pose)) {
      updateFormStatus("Keep elbows close to body, don't swing", false);
      return "improper_form";
    }

    // Analyze curl movement
    return _analyzeCurlMovement(avgAngle, updateFormStatus);
  }

  static double _calculateAngle(PoseLandmark shoulder, PoseLandmark elbow, PoseLandmark wrist) {
    final radians = math.atan2(wrist.y - elbow.y, wrist.x - elbow.x) -
        math.atan2(shoulder.y - elbow.y, shoulder.x - elbow.x);
    double angle = (radians * 180.0 / math.pi).abs();

    // Normalize angle to be between 0 and 180
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  static bool _isProperForm(Pose pose) {
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftElbow == null || rightElbow == null ||
        leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null) {
      return false;
    }

    // Check if elbows are staying relatively close to the body
    final leftElbowToBody = (leftElbow.x - leftHip.x).abs();
    final rightElbowToBody = (rightElbow.x - rightHip.x).abs();

    // Check if shoulders are stable (not swinging forward)
    final leftShoulderStability = (leftShoulder.x - leftHip.x).abs();
    final rightShoulderStability = (rightShoulder.x - rightHip.x).abs();

    return leftElbowToBody < 0.3 &&
        rightElbowToBody < 0.3 &&
        leftShoulderStability < 0.2 &&
        rightShoulderStability < 0.2;
  }

  static String _analyzeCurlMovement(double angle, Function(String, bool) updateFormStatus) {
    if (angle > 160) {
      updateFormStatus("Arms fully extended - start curling", true);
      return "starting_position";
    } else if (angle > 120) {
      updateFormStatus("Curling up - keep elbows stationary", true);
      return "curling_up_phase1";
    } else if (angle > 90) {
      updateFormStatus("Halfway up - continue squeezing", true);
      return "curling_up_phase2";
    } else if (angle > 60) {
      updateFormStatus("Near top - squeeze biceps!", true);
      return "top_position";
    } else if (angle <= 60) {
      updateFormStatus("Full contraction! Lower with control", true);
      return "full_contraction";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to starting position after full contraction
    // This ensures complete range of motion
    return (previousState == "full_contraction" && currentState == "starting_position") ||
        (previousState == "top_position" && currentState == "starting_position");
  }

  static bool isValidForm(String state) {
    return state == "starting_position" ||
        state == "curling_up_phase1" ||
        state == "curling_up_phase2" ||
        state == "top_position" ||
        state == "full_contraction";
  }
}