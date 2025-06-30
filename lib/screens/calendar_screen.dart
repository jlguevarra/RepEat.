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

  Map<DateTime, List<Map<String, dynamic>>> workoutData = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loadWorkoutHistory();
  }

  Future<void> loadWorkoutHistory() async {
    try {
      final data = await fetchWorkoutHistory(1); // 🔥 Replace with dynamic user_id if needed
      setState(() {
        workoutData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Map<DateTime, List<Map<String, dynamic>>>> fetchWorkoutHistory(
      int userId) async {
    final url = Uri.parse(
        'http://192.168.0.11/repEatApi/get_workout_history.php?user_id=$userId');

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        Map<DateTime, List<Map<String, dynamic>>> history = {};

        for (var item in data['data']) {
          try {
            DateTime date = DateTime.parse(item['date']);
            date = DateTime.utc(date.year, date.month, date.day);

            history.putIfAbsent(date, () => []).add({
              'exercise': item['exercise_name'],
              'sets': item['sets'].toString(),
              'reps': item['reps'].toString(),
            });
          } catch (e) {
            debugPrint('Date parsing error: $e');
          }
        }

        return history;
      } else {
        throw Exception("No data found or API failed.");
      }
    } else {
      throw Exception("Failed to connect to server. Status: ${response.statusCode}");
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                loadWorkoutHistory();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      )
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
