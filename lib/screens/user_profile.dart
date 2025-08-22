class UserProfile {
  final int userId;
  final String fitnessLevel; // beginner, intermediate, advanced
  final String primaryGoal; // strength, endurance, hypertrophy, general_fitness
  final int preferredReps;
  final int preferredSets;
  final List<String> availableEquipment; // dumbbells, barbell, resistance_bands, etc.
  final List<String> targetMuscles; // biceps, triceps, chest, etc.

  UserProfile({
    required this.userId,
    required this.fitnessLevel,
    required this.primaryGoal,
    required this.preferredReps,
    required this.preferredSets,
    required this.availableEquipment,
    required this.targetMuscles,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'],
      fitnessLevel: json['fitness_level'],
      primaryGoal: json['primary_goal'],
      preferredReps: json['preferred_reps'],
      preferredSets: json['preferred_sets'],
      availableEquipment: List<String>.from(json['available_equipment']),
      targetMuscles: List<String>.from(json['target_muscles']),
    );
  }
}