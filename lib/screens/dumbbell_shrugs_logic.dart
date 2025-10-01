// workout_logic/dumbbell_shrugs_logic.dart

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DumbbellShrugsLogic {
  static String analyzePose(Pose pose, Function(String, bool) updateFormStatus) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final rightEar = pose.landmarks[PoseLandmarkType.rightEar];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Check if essential landmarks are visible
    if (leftShoulder == null || rightShoulder == null ||
        leftEar == null || rightEar == null ||
        leftHip == null || rightHip == null) {
      updateFormStatus("Ensure shoulders and head are visible", false);
      return "no_pose";
    }

    // Calculate shoulder elevation
    final leftElevation = _calculateShoulderElevation(leftShoulder, leftEar, leftHip);
    final rightElevation = _calculateShoulderElevation(rightShoulder, rightEar, rightHip);
    final avgElevation = (leftElevation + rightElevation) / 2;

    // Check if person is in standing position
    if (!_isStandingPosition(pose)) {
      updateFormStatus("Stand upright with dumbbells at your sides", false);
      return "not_standing";
    }

    // Analyze shrug movement
    return _analyzeShrugMovement(avgElevation, updateFormStatus);
  }

  static double _calculateShoulderElevation(
      PoseLandmark shoulder, PoseLandmark ear, PoseLandmark hip) {
    // Calculate vertical distance between shoulder and ear
    // Normalize by body height (hip to ear distance)
    final bodyHeight = (ear.y - hip.y).abs();
    final shoulderElevation = (ear.y - shoulder.y).abs();

    return shoulderElevation / bodyHeight;
  }

  static bool _isStandingPosition(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null ||
        leftAnkle == null || rightAnkle == null) {
      return false;
    }

    // Check if shoulders are roughly aligned with hips (standing position)
    final shoulderHipAlignment = (leftShoulder.y - leftHip.y).abs() +
        (rightShoulder.y - rightHip.y).abs();

    // Check if hips are above ankles (not sitting)
    final hipAnkleAlignment = (leftHip.y - leftAnkle.y).abs() +
        (rightHip.y - rightAnkle.y).abs();

    return shoulderHipAlignment < 0.3 && hipAnkleAlignment > 0.2;
  }

  static String _analyzeShrugMovement(double elevation, Function(String, bool) updateFormStatus) {
    // Thresholds for shrug detection
    const double restingThreshold = 0.08;
    const double shrugThreshold = 0.15;
    const double fullShrugThreshold = 0.25;

    if (elevation < restingThreshold) {
      updateFormStatus("Ready - shoulders at rest", true);
      return "resting";
    } else if (elevation >= restingThreshold && elevation < shrugThreshold) {
      updateFormStatus("Shrug shoulders upward", true);
      return "shrugging_up";
    } else if (elevation >= shrugThreshold && elevation < fullShrugThreshold) {
      updateFormStatus("Good! Hold at the top", true);
      return "top_position";
    } else if (elevation >= fullShrugThreshold) {
      updateFormStatus("Excellent shrug! Lower slowly", true);
      return "full_shrug";
    }

    return "unknown";
  }

  static bool shouldCountRep(String currentState, String previousState) {
    // Count rep when going from full shrug back to resting
    return previousState == "full_shrug" && currentState == "resting";
  }
}