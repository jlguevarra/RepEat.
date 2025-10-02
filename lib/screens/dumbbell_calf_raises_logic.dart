// workout_logic/dumbbell_calf_raises_logic.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellCalfRaisesLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftHeel = pose.landmarks[PoseLandmarkType.leftHeel];
    final rightHeel = pose.landmarks[PoseLandmarkType.rightHeel];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Check if essential landmarks are visible
    if (leftAnkle == null || rightAnkle == null ||
        leftKnee == null || rightKnee == null ||
        leftHip == null || rightHip == null) {
      updateFormStatus("Ensure legs and hips are visible", false);
      return "no_pose";
    }

    // Check for proper standing form
    if (!_isProperStandingForm(pose)) {
      updateFormStatus("Stand upright with dumbbells at sides", false);
      return "improper_form";
    }

    // Calculate heel lift using ankle-knee distance (more reliable)
    final leftLift = _calculateHeelLift(leftAnkle, leftKnee, leftHeel);
    final rightLift = _calculateHeelLift(rightAnkle, rightKnee, rightHeel);
    final avgLift = (leftLift + rightLift) / 2;

    // Analyze calf raise movement
    return _analyzeCalfRaiseMovement(avgLift, updateFormStatus);
  }

  static double _calculateHeelLift(PoseLandmark ankle, PoseLandmark knee, PoseLandmark? heel) {
    // Calculate the vertical distance between ankle and knee
    // When heels are down, ankle is lower than knee
    // When heels are up, ankle moves closer to knee vertically
    final verticalDistance = (ankle.y - knee.y).abs();

    // Normalize based on leg length (hip to ankle distance)
    return verticalDistance.clamp(0.0, 1.0);
  }

  static bool _isProperStandingForm(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || rightHip == null ||
        leftKnee == null || rightKnee == null ||
        leftAnkle == null || rightAnkle == null) {
      return false;
    }

    // Check if legs are straight (knees not significantly bent)
    final leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    final rightKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);

    // Knees should be relatively straight (> 160 degrees) for calf raises
    final kneesStraight = leftKneeAngle > 160 && rightKneeAngle > 160;

    // Check if hips are level (good posture)
    final hipAlignment = (leftHip.y - rightHip.y).abs();
    final hipsLevel = hipAlignment < 0.1;

    return kneesStraight && hipsLevel;
  }

  static double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x);
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  static String _analyzeCalfRaiseMovement(double lift, Function(String, bool) updateFormStatus) {
    // Adjusted thresholds based on normalized lift values
    if (lift < 0.15) {
      updateFormStatus("Heels down - rise onto toes", true);
      return "starting_position";
    } else if (lift >= 0.15 && lift < 0.25) {
      updateFormStatus("Rising up - push through balls of feet", true);
      return "rising_phase1";
    } else if (lift >= 0.25 && lift < 0.35) {
      updateFormStatus("Halfway up - continue pushing", true);
      return "rising_phase2";
    } else if (lift >= 0.35 && lift < 0.45) {
      updateFormStatus("Near top - squeeze calves!", true);
      return "top_position";
    } else if (lift >= 0.45) {
      updateFormStatus("Full extension! Hold and lower slowly", true);
      return "full_extension";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to starting position after full extension
    // This ensures complete range of motion
    return (previousState == "full_extension" && currentState == "starting_position") ||
        (previousState == "top_position" && currentState == "starting_position");
  }

  static bool isValidForm(String state) {
    return state == "starting_position" ||
        state == "rising_phase1" ||
        state == "rising_phase2" ||
        state == "top_position" ||
        state == "full_extension";
  }
}