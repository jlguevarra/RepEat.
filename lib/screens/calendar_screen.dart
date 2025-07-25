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
  };

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _setsController.text = '3';
    _repsController.text = '10';
    _fetchWorkouts();
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkouts() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.78/gymPlannerApi/get_workouts.php?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final Map<DateTime, List<GymExercise>> newWorkouts = {};
          for (var workout in data['data']) {
            final date = DateTime.parse(workout['date']);
            final exercise = GymExercise(
              workoutId: workout['workout_id'],
              userId: workout['user_id'],
              date: date,
              muscleGroup: workout['muscle_group'],
              exerciseName: workout['exercise_name'],
              sets: workout['sets'],
              reps: workout['reps'],
              isCompleted: workout['is_completed'] == 1,
            );

            final normalizedDate = DateTime(date.year, date.month, date.day);
            if (newWorkouts.containsKey(normalizedDate)) {
              newWorkouts[normalizedDate]!.add(exercise);
            } else {
              newWorkouts[normalizedDate] = [exercise];
            }
          }

          setState(() => _workouts = newWorkouts);
        }
      }
    } catch (e) {
      _showSnackbar('Failed to load workouts: $e', isError: true);
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
    if (_selectedDay == null ||
        _selectedMuscleGroup == null ||
        _selectedExercise == null) return;

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
        'is_completed': false,
      };

      final endpoint = _formMode == 'add'
          ? 'http://192.168.100.78/gymPlannerApi/save_workout.php'
          : 'http://192.168.100.78/gymPlannerApi/update_workout.php';

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
          _showSnackbar(data['message'], isError: true);
        }
      }
    } catch (e) {
      _showSnackbar('Error saving workout: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWorkoutCompletion(int workoutId, bool isCompleted) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.78/gymPlannerApi/toggle_workout_completion.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'workout_id': workoutId,
          'is_completed': isCompleted ? 0 : 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!data['success']) {
          _showSnackbar(data['message'], isError: true);
        }
        await _fetchWorkouts();
      }
    } catch (e) {
      _showSnackbar('Error updating workout: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWorkout(int workoutId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.78/gymPlannerApi/delete_workout.php'),
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
      default:
        return Icons.sports_gymnastics;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Workout Planner', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWorkouts,
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
              eventLoader: (day) => _workouts[DateTime(day.year, day.month, day.day)] ?? [],
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
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
            Text(
              '${_formMode == 'add' ? 'Add New' : 'Edit'} Workout',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
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

  GymExercise({
    required this.workoutId,
    required this.userId,
    required this.date,
    required this.muscleGroup,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.isCompleted,
  });
}