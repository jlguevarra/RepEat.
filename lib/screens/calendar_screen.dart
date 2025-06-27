import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // ✅ Remove final to allow updating the map
  Map<DateTime, List<Map<String, dynamic>>> workoutData = {};

  @override
  void initState() {
    super.initState();
    fetchWorkoutHistory(1).then((data) {
      setState(() {
        workoutData = data;
      });
    });
  }

  Future<Map<DateTime, List<Map<String, dynamic>>>> fetchWorkoutHistory(int userId) async {
    final response = await http.get(
      Uri.parse('http://192.168.100.79/repEatApi/get_workout_history.php?user_id=$userId'),
      // 🔥 Use 10.0.2.2 for emulator or your local IP address for real device
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        Map<DateTime, List<Map<String, dynamic>>> history = {};

        for (var item in data['data']) {
          DateTime date = DateTime.parse(item['date']);
          date = DateTime.utc(date.year, date.month, date.day);

          history.putIfAbsent(date, () => []).add({
            'exercise': item['exercise_name'],
            'sets': item['sets'],
            'reps': item['reps'],
          });
        }

        return history;
      } else {
        throw Exception("Failed to load data.");
      }
    } else {
      throw Exception("Error connecting to server.");
    }
  }

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
      body: workoutData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
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
