import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Sample workout data (can be replaced with backend data)
  final Map<DateTime, List<Map<String, dynamic>>> workoutData = {
    DateTime.utc(2024, 5, 20): [
      {'exercise': 'Push-ups', 'sets': 3, 'reps': 12},
      {'exercise': 'Squats', 'sets': 3, 'reps': 15},
    ],
    DateTime.utc(2024, 5, 22): [
      {'exercise': 'Pull-ups', 'sets': 3, 'reps': 10},
    ],
    DateTime.utc(2024, 5, 24): [
      {'exercise': 'Lunges', 'sets': 3, 'reps': 12},
      {'exercise': 'Plank', 'sets': 3, 'reps': 1}, // Plank in minutes
    ],
  };

  List<Map<String, dynamic>> _getWorkoutsForDay(DateTime day) {
    return workoutData[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final workouts = _getWorkoutsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Calendar'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple.shade300,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) {
              return _getWorkoutsForDay(day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),

          const SizedBox(height: 16),

          // Workout details for selected day
          Expanded(
            child: workouts.isEmpty
                ? const Center(
              child: Text("No workout on this day."),
            )
                : ListView.builder(
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(workout['exercise']),
                    subtitle: Text(
                        'Sets: ${workout['sets']}  |  Reps: ${workout['reps']}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
