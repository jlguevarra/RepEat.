import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendarScreen extends StatefulWidget {
  final int userId;

  const CalendarScreen({super.key, required this.userId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<WorkoutNote>> _workouts = {};
  bool _isLoading = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final TextEditingController _noteController = TextEditingController();
  bool _showNoteInput = false;
  int? _editingWorkoutId;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _fetchWorkouts();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkouts() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.11/repEatApi/get_workout_history.php?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final Map<DateTime, List<WorkoutNote>> newWorkouts = {};
          for (var workout in data['data']) {
            final date = DateTime.parse(workout['date']);
            final note = WorkoutNote(
              workoutId: workout['workout_id'],
              userId: workout['user_id'],
              date: date,
              category: workout['category'],
              exerciseName: workout['exercise_name'],
              sets: workout['sets'],
              reps: workout['reps'],
              note: workout['note'],
            );

            final normalizedDate = DateTime(date.year, date.month, date.day);
            if (newWorkouts.containsKey(normalizedDate)) {
              newWorkouts[normalizedDate]!.add(note);
            } else {
              newWorkouts[normalizedDate] = [note];
            }
          }

          setState(() => _workouts = newWorkouts);
        }
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load workouts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleNoteInput({WorkoutNote? workout}) {
    setState(() {
      _showNoteInput = !_showNoteInput;
      _editingWorkoutId = workout?.workoutId;
      _noteController.text = workout?.note ?? '';
    });
  }

  Future<void> _saveNote() async {
    if (_selectedDay == null || _noteController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final normalizedDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );

      if (_editingWorkoutId != null) {
        // Update existing note
        final response = await http.post(
          Uri.parse('http://192.168.0.11/repEatApi/update_note.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'workout_id': _editingWorkoutId,
            'note': _noteController.text,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success']) {
            await _fetchWorkouts();
            _showSuccessSnackbar('Note updated successfully!');
            _toggleNoteInput();
          }
        }
      } else {
        // Create new note
        final response = await http.post(
          Uri.parse('http://192.168.0.11repEatApi/save_note.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': widget.userId,
            'date': DateFormat('yyyy-MM-dd').format(_selectedDay!),
            'category': 'General',
            'exercise_name': 'Workout Note',
            'sets': 0,
            'reps': 0,
            'note': _noteController.text,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success']) {
            await _fetchWorkouts();
            _showSuccessSnackbar('Note saved successfully!');
            _toggleNoteInput();
          }
        }
      }
    } catch (e) {
      _showErrorSnackbar('Error saving note: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _editingWorkoutId = null;
      });
    }
  }

  Future<void> _deleteWorkout(int workoutId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.0.11/repEatApi/delete_workout.php?workout_id=$workoutId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await _fetchWorkouts();
          _showSuccessSnackbar('Workout deleted successfully!');
        }
      }
    } catch (e) {
      _showErrorSnackbar('Error deleting workout: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWorkouts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _showNoteInput = false;
                  _editingWorkoutId = null;
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
                markersAlignment: Alignment.bottomRight,
                markerSize: 8,
                markerMargin: const EdgeInsets.only(bottom: 4, right: 4),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
              ),
            ),

            if (_selectedDay != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.note_add),
                        label: const Text('Add Note'),
                        onPressed: () => _toggleNoteInput(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  DateFormat.yMMMMd().format(_selectedDay!),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            if (_showNoteInput && _selectedDay != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _editingWorkoutId != null ? 'Edit Note' : 'Add Note',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Write your workout notes here...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _toggleNoteInput,
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _saveNote,
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Workouts:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            // ✅ Constrain workout list height
            SizedBox(
              height: 400, // Adjust height as needed
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildWorkoutList(),
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

    final workouts = _workouts[normalizedDate] ?? [];

    if (workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No workouts for ${DateFormat.yMMMMd().format(_selectedDay!)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return Dismissible(
          key: Key(workout.workoutId.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Workout'),
                content: const Text('Are you sure you want to delete this workout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) => _deleteWorkout(workout.workoutId),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () => _toggleNoteInput(workout: workout),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          workout.exerciseName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          workout.category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${workout.sets} sets × ${workout.reps} reps',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (workout.note != null && workout.note!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          workout.note!,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WorkoutNote {
  final int workoutId;
  final int userId;
  final DateTime date;
  final String category;
  final String exerciseName;
  final int sets;
  final int reps;
  final String? note;

  WorkoutNote({
    required this.workoutId,
    required this.userId,
    required this.date,
    required this.category,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.note,
  });
}