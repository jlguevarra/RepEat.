// dumbbell_shrugs_logic.dart

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellShrugsLogic {
  static int _holdCounter = 0;
  static const int _requiredHoldFrames = 3;
  static double _previousElevation = 0.0;
  static bool _hasCompletedFullMovement = false;

  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final rightEar = pose.landmarks[PoseLandmarkType.rightEar];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Check if all required landmarks are visible
    if (leftShoulder == null || rightShoulder == null ||
        leftEar == null || rightEar == null ||
        leftHip == null || rightHip == null) {
      updateFormStatus("Ensure shoulders and head are visible", false);
      return "no_pose";
    }

    // Check if person is standing upright
    if (!_isStandingPosition(pose)) {
      updateFormStatus("Stand upright with dumbbells at your sides", false);
      return "not_standing";
    }

    // Calculate shoulder elevation
    final leftElevation = _calculateShoulderElevation(leftShoulder, leftEar, leftHip);
    final rightElevation = _calculateShoulderElevation(rightShoulder, rightEar, rightHip);
    final avgElevation = (leftElevation + rightElevation) / 2;

    // Analyze the movement
    final String currentState = _analyzeShrugMovement(avgElevation, updateFormStatus);
    _previousElevation = avgElevation;

    return currentState;
  }

  static double _calculateShoulderElevation(PoseLandmark shoulder, PoseLandmark ear, PoseLandmark hip) {
    // Calculate normalized elevation (0-1 scale)
    final bodyHeight = (ear.y - hip.y).abs();
    final shoulderElevation = (ear.y - shoulder.y).abs();
    return (shoulderElevation / bodyHeight).clamp(0.0, 1.0);
  }

  static bool _isStandingPosition(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null) {
      return false;
    }

    // Check if shoulders and hips are aligned (person is standing)
    final shoulderAlignment = (leftShoulder.y - rightShoulder.y).abs();
    final hipAlignment = (leftHip.y - rightHip.y).abs();

    return shoulderAlignment < 0.2 && hipAlignment < 0.2;
  }

  static String _analyzeShrugMovement(double elevation, Function(String, bool) updateFormStatus) {
    const double restingThreshold = 0.08;
    const double shrugThreshold = 0.15;
    const double fullShrugThreshold = 0.25;
    const double holdThreshold = 0.22;

    if (elevation < restingThreshold) {
      _holdCounter = 0;
      final String state = _hasCompletedFullMovement ? "completed_rep" : "resting";

      if (_hasCompletedFullMovement) {
        _hasCompletedFullMovement = false;
        updateFormStatus("Perfect! Return to start position", true);
      } else {
        updateFormStatus("Ready - shoulders relaxed", true);
      }
      return state;

    } else if (elevation >= fullShrugThreshold) {
      _holdCounter++;
      if (_holdCounter >= _requiredHoldFrames) {
        _hasCompletedFullMovement = true;
        updateFormStatus("Excellent shrug! Hold and lower slowly", true);
        return "full_shrug_hold";
      } else {
        updateFormStatus("Hold the shrug position...", true);
        return "holding_top";
      }

    } else if (elevation >= shrugThreshold) {
      _holdCounter = 0;
      updateFormStatus("Good elevation! Continue upward", true);
      return "shrugging_up";

    } else if (elevation >= restingThreshold) {
      _holdCounter = 0;
      updateFormStatus("Shrug shoulders upward toward ears", true);
      return "starting_shrug";
    }

    _holdCounter = 0;
    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when returning to resting after a full shrug hold
    bool shouldCount = (previousState == "full_shrug_hold" && currentState == "completed_rep") ||
        (previousState == "full_shrug_hold" && currentState == "resting");

    if (shouldCount) {
      _hasCompletedFullMovement = false;
    }

    return shouldCount;
  }

  static bool isValidForm(String state) {
    return state == "shrugging_up" ||
        state == "full_shrug_hold" ||
        state == "holding_top" ||
        state == "completed_rep" ||
        state == "starting_shrug";
  }
}