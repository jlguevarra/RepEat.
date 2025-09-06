import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GymPlannerScreen extends StatefulWidget {
  final int userId;

  const GymPlannerScreen({super.key, required this.userId});

  @override
  State<GymPlannerScreen> createState() => _GymPlannerScreenState();
}

class _GymPlannerScreenState extends State<GymPlannerScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<GymExercise>> _workouts = {};
  bool _isLoading = false;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  bool _showExerciseForm = false;
  int? _editingWorkoutId;
  String _formMode = 'add';
  String? _selectedMuscleGroup;
  String? _selectedExercise;
  int _selectedSets = 3;
  int _selectedReps = 10;

  // Add recommendation system variables
  List<Map<String, dynamic>> _recommendedExercises = [];
  UserProfile? _userProfile;
  String _workoutFocus = '';

  final Map<String, List<Map<String, String>>> _exercises = {
    'Biceps': [
      {'name': 'Dumbbell Curls'},
      {'name': 'Hammer Curls'},
      {'name': 'Concentration Curls'},
    ],
    'Triceps': [
      {'name': 'Tricep Kickbacks'},
      {'name': 'Overhead Extensions'},
    ],
    'Shoulders': [
      {'name': 'Shoulder Press'},
      {'name': 'Lateral Raise'},
      {'name': 'Front Raise'},
    ],
    'Chest': [
      {'name': 'Dumbbell Bench Press'},
      {'name': 'Dumbbell Fly'},
    ],
    'Back': [
      {'name': 'Dumbbell Rows'},
      {'name': 'Reverse Fly'},
    ],
    'Legs': [
      {'name': 'Goblet Squats'},
      {'name': 'Dumbbell Lunges'},
      {'name': 'Dumbbell Deadlifts'},
    ],
    'Core': [
      {'name': 'Plank'},
      {'name': 'Sit-ups'},
      {'name': 'Russian Twists'},
    ],
    'Cardio': [
      {'name': 'Jumping Jacks'},
      {'name': 'Running'},
      {'name': 'Cycling'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _setsController.text = '3';
    _repsController.text = '10';
    _fetchWorkouts();
    _loadRecommendations(); // Load recommendations
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  // Add recommendation loading method
  Future<void> _loadRecommendations() async {
    final response = await http.get(
        Uri.parse('http://llocalhost/repEatApi/get_onboarding_data.php?user_id=${widget.userId}')
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] && data['data'] != null) {
        setState(() {
          _userProfile = UserProfile.fromJson(data['data']);
          _recommendedExercises = ExerciseRecommender.recommendExercises(_userProfile!);
          _workoutFocus = ExerciseRecommender.getWorkoutFocus(_userProfile!);
        });
      }
    }
  }

  Future<void> _fetchWorkouts() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://localhost/repEatApi/get_workouts.php?user_id=${widget.userId}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;

        if (decoded['success'] == true) {
          final Map<DateTime, List<GymExercise>> newWorkouts = {};

          for (var workout in decoded['data'] ?? []) {
            try {
              final exercise = GymExercise.fromJson(workout);
              final normalizedDate = DateTime(exercise.date.year, exercise.date.month, exercise.date.day);
              newWorkouts[normalizedDate] = [...newWorkouts[normalizedDate] ?? [], exercise];
            } catch (e) {
              debugPrint('Error parsing workout: $e');
            }
          }

          setState(() => _workouts = newWorkouts);
        } else {
          throw Exception(decoded['message'] ?? 'Failed to load workouts');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Failed to load workouts: ${e.toString()}', isError: true);
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleExerciseForm({GymExercise? workout}) {
    setState(() {
      _showExerciseForm = !_showExerciseForm;
      _editingWorkoutId = workout?.workoutId;
      _formMode = workout == null ? 'add' : 'edit';

      if (workout != null) {
        _selectedMuscleGroup = workout.muscleGroup;
        _selectedExercise = workout.exerciseName;
        _setsController.text = workout.sets.toString();
        _repsController.text = workout.reps.toString();
      } else {
        _selectedMuscleGroup = null;
        _selectedExercise = null;
        _setsController.text = '3';
        _repsController.text = '10';
      }
    });
  }

  Future<void> _saveWorkout() async {
    if (_selectedDay == null || _selectedMuscleGroup == null || _selectedExercise == null) return;

    setState(() => _isLoading = true);
    try {
      final workoutData = {
        if (_editingWorkoutId != null) 'workout_id': _editingWorkoutId,
        'user_id': widget.userId,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDay!),
        'muscle_group': _selectedMuscleGroup,
        'exercise_name': _selectedExercise,
        'sets': int.parse(_setsController.text),
        'reps': int.parse(_repsController.text),
        'note': '',
      };

      final endpoint = _formMode == 'add'
          ? 'http://localhost/repEatApi/save_workout.php'
          : 'http://localhost/repEatApi/update_workout.php';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(workoutData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await _fetchWorkouts();
          _showSnackbar('Workout ${_formMode == 'add' ? 'added' : 'updated'} successfully!');
          _toggleExerciseForm();
        } else {
          _showSnackbar(data['message'] ?? 'Operation failed', isError: true);
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Error saving workout: ${e.toString()}', isError: true);
      debugPrint('Error saving workout: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWorkoutCompletion(int workoutId, bool isCompleted) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost/repEatApi/toggle_workout_completion.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'workout_id': workoutId,
          'status': isCompleted ? 'planned' : 'completed',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          _showSnackbar(data['message'] ?? 'Failed to update status', isError: true);
        }
        await _fetchWorkouts();
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Error updating workout: ${e.toString()}', isError: true);
      debugPrint('Error toggling completion: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWorkout(int workoutId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost/repEatApi/delete_workout.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'workout_id': workoutId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await _fetchWorkouts();
          _showSnackbar('Workout deleted successfully!');
        } else {
          _showSnackbar(data['message'], isError: true);
        }
      }
    } catch (e) {
      _showSnackbar('Error deleting workout: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getMuscleGroupColor(String muscleGroup) {
    switch (muscleGroup) {
      case 'Biceps':
        return Colors.blue.shade100;
      case 'Triceps':
        return Colors.green.shade100;
      case 'Shoulders':
        return Colors.purple.shade100;
      case 'Chest':
        return Colors.orange.shade100;
      case 'Back':
        return Colors.yellow.shade100;
      case 'Legs':
        return Colors.red.shade100;
      case 'Core':
        return Colors.teal.shade100;
      case 'Cardio':
        return Colors.indigo.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _getMuscleGroupIcon(String muscleGroup) {
    switch (muscleGroup) {
      case 'Biceps':
        return Icons.fitness_center;
      case 'Triceps':
        return Icons.accessibility;
      case 'Shoulders':
        return Icons.arrow_upward;
      case 'Chest':
        return Icons.people;
      case 'Back':
        return Icons.arrow_back;
      case 'Legs':
        return Icons.directions_walk;
      case 'Core':
        return Icons.self_improvement;
      case 'Cardio':
        return Icons.directions_run;
      default:
        return Icons.sports_gymnastics;
    }
  }

  // Helper method to find muscle group for an exercise
  String _findMuscleGroup(String exerciseName) {
    for (var entry in _exercises.entries) {
      if (entry.value.any((ex) => ex['name'] == exerciseName)) {
        return entry.key;
      }
    }
    return 'Biceps'; // Default fallback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Workout Planner', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchWorkouts();
              _loadRecommendations();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _toggleExerciseForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8),
            elevation: 2,
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _showExerciseForm = false;
                });
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              eventLoader: (day) =>
              _workouts[DateTime(day.year, day.month, day.day)] ?? [],
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) =>
                  setState(() => _calendarFormat = format),
              calendarStyle: CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),
          if (_showExerciseForm) _buildExerciseForm(),
          Expanded(
            child: _buildWorkoutList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseForm() {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_workoutFocus.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _userProfile!.isBulking
                      ? Colors.blue.shade100
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Workout Focus: $_workoutFocus',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              '${_formMode == 'add' ? 'Add New' : 'Edit'} Workout',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),

            if (_recommendedExercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Recommended Exercises:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommendedExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _recommendedExercises[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(exercise['name']),
                        selected: _selectedExercise == exercise['name'],
                        onSelected: (selected) {
                          setState(() {
                            _selectedExercise = exercise['name'];
                            _selectedMuscleGroup = _findMuscleGroup(exercise['name']);
                            _setsController.text = exercise['sets'].toString();
                            _repsController.text = exercise['reps'].toString();
                          });
                        },
                        backgroundColor: _userProfile!.isBulking
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 20),
            ],

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMuscleGroup,
              items: _exercises.keys.map((muscleGroup) {
                return DropdownMenuItem<String>(
                  value: muscleGroup,
                  child: Text(muscleGroup),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMuscleGroup = value;
                  _selectedExercise = null;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Muscle Group',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedExercise,
              items: _selectedMuscleGroup != null
                  ? _exercises[_selectedMuscleGroup]!.map((exercise) {
                return DropdownMenuItem<String>(
                  value: exercise['name'],
                  child: Text(exercise['name']!),
                );
              }).toList()
                  : null,
              onChanged: (value) => setState(() => _selectedExercise = value),
              decoration: const InputDecoration(
                labelText: 'Exercise',
                border: OutlineInputBorder(),
              ),
              disabledHint: const Text('Select muscle group first'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    decoration: const InputDecoration(
                      labelText: 'Sets',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _toggleExerciseForm,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveWorkout,
                    child: Text(_formMode == 'add' ? 'Add' : 'Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutList() {
    if (_selectedDay == null) {
      return const Center(child: Text('Select a date to view workouts'));
    }

    final normalizedDate = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final dayWorkouts = _workouts[normalizedDate] ?? [];

    if (dayWorkouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No workouts for this day',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _toggleExerciseForm(),
              child: const Text('Add Workout'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: dayWorkouts.length,
      itemBuilder: (context, index) {
        final workout = dayWorkouts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: _getMuscleGroupColor(workout.muscleGroup),
          child: ListTile(
            leading: Icon(_getMuscleGroupIcon(workout.muscleGroup)),
            title: Text(
              workout.exerciseName,
              style: TextStyle(
                decoration: workout.isCompleted ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text('${workout.sets} sets × ${workout.reps} reps'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    workout.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                    color: workout.isCompleted ? Colors.green : null,
                  ),
                  onPressed: () => _toggleWorkoutCompletion(workout.workoutId, workout.isCompleted),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _toggleExerciseForm(workout: workout),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteWorkout(workout.workoutId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GymExercise {
  final int workoutId;
  final int userId;
  final DateTime date;
  final String muscleGroup;
  final String exerciseName;
  final int sets;
  final int reps;
  final bool isCompleted;
  final String note;
  final String createdAt;

  GymExercise({
    required this.workoutId,
    required this.userId,
    required this.date,
    required this.muscleGroup,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.isCompleted,
    required this.note,
    required this.createdAt,
  });

  factory GymExercise.fromJson(Map<String, dynamic> json) {
    return GymExercise(
      workoutId: json['workout_id'] as int,
      userId: json['user_id'] as int,
      date: DateTime.parse(json['date']),
      muscleGroup: json['muscle_group'] as String,
      exerciseName: json['exercise_name'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      isCompleted: (json['status'] as String).toLowerCase() == 'completed',
      note: json['note'] as String? ?? '',
      createdAt: json['created_at'] as String,
    );
  }
}

// Add UserProfile and ExerciseRecommender classes here
class UserProfile {
  final int userId;
  final String goal;
  final bool hasInjury;
  final String? injuryDetails;
  final String dietPreference;
  final String? allergies;
  final DateTime? birthdate;
  final String bodyType;
  final double currentWeight;
  final double targetWeight;
  final double height;
  final String gender;

  UserProfile({
    required this.userId,
    required this.goal,
    required this.hasInjury,
    this.injuryDetails,
    required this.dietPreference,
    this.allergies,
    this.birthdate,
    required this.bodyType,
    required this.currentWeight,
    required this.targetWeight,
    required this.height,
    required this.gender,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as int,
      goal: json['goal'] as String,
      hasInjury: (json['has_injury'] as int) == 1,
      injuryDetails: json['injury_details'],
      dietPreference: json['diet_preference'] as String,
      allergies: json['allergies'],
      birthdate: json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
      bodyType: json['body_type'] as String,
      currentWeight: double.tryParse(json['current_weight']?.toString() ?? '0') ?? 0,
      targetWeight: double.tryParse(json['target_weight']?.toString() ?? '0') ?? 0,
      height: double.tryParse(json['height']?.toString() ?? '0') ?? 0,
      gender: json['gender'] as String,
    );
  }

  bool get isBulking => goal.toLowerCase() == 'bulk' || goal.toLowerCase().contains('muscle');
  bool get isCutting => goal.toLowerCase() == 'cut' || goal.toLowerCase().contains('weight') || goal.toLowerCase().contains('loss');

  int get age {
    if (birthdate == null) return 30;
    return DateTime.now().difference(birthdate!).inDays ~/ 365;
  }

  int get recommendedSets => isBulking ? 4 : 3;
  int get recommendedReps => isBulking ? 8 : 12;

  List<String> get targetMuscles {
    if (isBulking) {
      return ['chest', 'back', 'shoulders', 'biceps', 'triceps', 'legs'];
    } else {
      return ['core', 'legs', 'back'];
    }
  }
}

class ExerciseRecommender {
  static final Map<String, Map<String, dynamic>> _exerciseDatabase = {
    'Dumbbell Curls': {
      'equipment': ['dumbbells'],
      'muscles': ['biceps'],
      'bulk': {'sets': 4, 'reps': 8},
      'cut': {'sets': 3, 'reps': 15},
      'injury_safe': true,
      'injury_restrictions': [],
    },
    'Hammer Curls': {
      'equipment': ['dumbbells'],
      'muscles': ['biceps', 'forearms'],
      'bulk': {'sets': 4, 'reps': 8},
      'cut': {'sets': 3, 'reps': 15},
      'injury_safe': true,
      'injury_restrictions': [],
    },
    'Shoulder Press': {
      'equipment': ['dumbbells'],
      'muscles': ['shoulders', 'triceps'],
      'bulk': {'sets': 4, 'reps': 8},
      'cut': {'sets': 3, 'reps': 12},
      'injury_safe': false,
      'injury_restrictions': ['shoulder', 'neck'],
    },
    'Dumbbell Bench Press': {
      'equipment': ['dumbbells', 'bench'],
      'muscles': ['chest', 'triceps', 'shoulders'],
      'bulk': {'sets': 4, 'reps': 8},
      'cut': {'sets': 3, 'reps': 12},
      'injury_safe': false,
      'injury_restrictions': ['shoulder', 'chest'],
    },
    'Dumbbell Rows': {
      'equipment': ['dumbbells', 'bench'],
      'muscles': ['back', 'biceps'],
      'bulk': {'sets': 4, 'reps': 8},
      'cut': {'sets': 3, 'reps': 12},
      'injury_safe': true,
      'injury_restrictions': ['lower back'],
    },
    'Goblet Squats': {
      'equipment': ['dumbbell'],
      'muscles': ['legs', 'core'],
      'bulk': {'sets': 4, 'reps': 8},
      'cut': {'sets': 3, 'reps': 15},
      'injury_safe': false,
      'injury_restrictions': ['knee', 'back'],
    },
    'Plank': {
      'equipment': [],
      'muscles': ['core'],
      'bulk': {'sets': 3, 'reps': 30},
      'cut': {'sets': 4, 'reps': 45},
      'injury_safe': true,
      'injury_restrictions': [],
    },
    'Jumping Jacks': {
      'equipment': [],
      'muscles': ['cardio', 'legs'],
      'bulk': {'sets': 3, 'reps': 30},
      'cut': {'sets': 4, 'reps': 45},
      'injury_safe': false,
      'injury_restrictions': ['knee', 'ankle'],
    },
  };

  static List<Map<String, dynamic>> recommendExercises(UserProfile profile) {
    return _exerciseDatabase.entries.where((exercise) {
      final exData = exercise.value;

      if (profile.hasInjury) {
        final injuryDetails = profile.injuryDetails?.toLowerCase() ?? '';
        final hasMatchingRestriction = exData['injury_restrictions'].any((restriction) =>
            injuryDetails.contains(restriction.toLowerCase()));

        if (hasMatchingRestriction || !exData['injury_safe']) {
          return false;
        }
      }

      return exData['muscles'].any((muscle) =>
          profile.targetMuscles.contains(muscle));
    }).map((exercise) {
      final exName = exercise.key;
      final exData = exercise.value;

      var recommendation = {
        'sets': profile.recommendedSets,
        'reps': profile.recommendedReps,
      };

      return {
        'name': exName,
        ...recommendation,
        'muscles_targeted': exData['muscles'],
        'goal_specific': profile.isBulking ? 'Muscle Gain' : 'Fat Loss',
      };
    }).toList();
  }

  static String getWorkoutFocus(UserProfile profile) {
    if (profile.isBulking) {
      return 'Strength & Muscle Building';
    } else {
      return 'Fat Loss & Endurance';
    }
  }
}