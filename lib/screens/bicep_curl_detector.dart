import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class BicepCurlDetector {
  bool _isCurlingDown = false;

  int detectReps(List<Pose> poses, int currentReps, Function(String) feedbackCallback) {
    if (poses.isEmpty) return currentReps;
    final pose = poses.first;

    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (rightShoulder == null || rightElbow == null || rightWrist == null) return currentReps;

    final wristY = rightWrist.y;
    final elbowY = rightElbow.y;
    final shoulderY = rightShoulder.y;

    final wristToElbow = (wristY - elbowY).abs();
    final elbowToShoulder = (elbowY - shoulderY).abs();

    // ✅ Detect "holding dumbbell" by stable wrist distance
    final holdingDumbbell = wristToElbow < 80; // change threshold as needed

    if (!holdingDumbbell) {
      feedbackCallback("❌ Please hold dumbbells to count reps.");
      return currentReps;
    }

    // ✅ Curl logic
    if (wristY > elbowY + 40 && !_isCurlingDown) {
      _isCurlingDown = true;
    }

    if (_isCurlingDown && wristY < shoulderY + 40) {
      currentReps++;
      _isCurlingDown = false;
      feedbackCallback("✅ Good form!");
    }

    return currentReps;
  }
}
