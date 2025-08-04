
class ExerciseGuide {
  final String name;
  final String imageAsset;
  final String description;

  ExerciseGuide({
    required this.name,
    required this.imageAsset,
    required this.description,
  });
}

final Map<String, ExerciseGuide> exerciseGuides = {
  'Hammer Curls': ExerciseGuide(
    name: 'Hammer Curls',
    imageAsset: 'assets/exercises/hammer_curls.png',
    description: 'Hold dumbbells with neutral grip.\n'
        'Curl both arms up while keeping elbows tucked.\n'
        'Lower slowly and repeat.',
  ),
  'Concentration Curls': ExerciseGuide(
    name: 'Concentration Curls',
    imageAsset: 'assets/exercises/concentration_curls.png',
    description: 'Sit with elbow on knee.\n'
        'Curl the dumbbell toward your chest.\n'
        'Pause, then lower slowly.',
  ),
  'Dumbbell Curls': ExerciseGuide(
    name: 'Dumbbell Curls',
    imageAsset: 'assets/exercises/dumbbell_curls.png',
    description: 'Stand with dumbbells at sides.\n'
        'Curl weights up while keeping elbows close.\n'
        'Slowly lower back down.',
  ),
};