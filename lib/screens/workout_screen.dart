import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'camera_workout_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final int userId;

  const WorkoutScreen({super.key, required this.userId});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool isLoading = false;
  bool checkingPlan = true;
  Map<String, dynamic>? workoutPlan;
  String? errorMessage;

  // State to track completion of individual exercises for the current day.
  final Set<String> _completedExercises = <String>{};

  @override
  void initState() {
    super.initState();
    _checkIfUserHasPlan();
  }

  Future<void> _checkIfUserHasPlan() async {
    setState(() {
      checkingPlan = true;
      workoutPlan = null;
    });

    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.11/repEatApi/check_workout_plan.php"),
        body: {"user_id": widget.userId.toString()},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true && data["has_plan"] == true) {
          _loadWorkoutPlan();
        } else {
          setState(() => checkingPlan = false);
        }
      } else {
        setState(() {
          checkingPlan = false;
          errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        checkingPlan = false;
        errorMessage = "Exception: $e";
      });
    }
  }

  Future<void> _loadWorkoutPlan() async {
    setState(() {
      isLoading = true;
      _completedExercises.clear(); // Clear progress when loading new state
    });

    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.11/repEatApi/get_workout_plan.php"),
        body: {"user_id": widget.userId.toString()},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true) {
          setState(() {
            workoutPlan = data;
          });
        } else {
          setState(() => errorMessage = data["message"]);
        }
      } else {
        setState(() => errorMessage = "Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => errorMessage = "Exception: $e");
    } finally {
      setState(() {
        isLoading = false;
        checkingPlan = false;
      });
    }
  }

  Future<void> _generateWorkoutPlan() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.11/repEatApi/generate_workout.php"),
        body: {"user_id": widget.userId.toString()},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true) {
          await _loadWorkoutPlan(); // Reload to get the full plan structure
        } else {
          setState(() => errorMessage = data["message"]);
        }
      } else {
        setState(() => errorMessage = "Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => errorMessage = "Exception: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProgressOnServer(int newWeekIndex, int newDayIndex) async {
    try {
      await http.post(
        Uri.parse("http://192.168.100.11/repEatApi/update_workout_progress.php"),
        body: {
          "user_id": widget.userId.toString(),
          "current_week_index": newWeekIndex.toString(),
          "current_day_index": newDayIndex.toString(),
        },
      );
      await _loadWorkoutPlan(); // Refresh the plan from the server
    } catch (e) {
      print("Error updating progress: $e");
    }
  }

  void _completeDayAndProceed() {
    if (workoutPlan == null) return;
    int currentWeekIndex = workoutPlan!["currentWeekIndex"];
    int currentDayIndex = workoutPlan!["currentDayIndex"];
    int newDayIndex = currentDayIndex + 1;
    int newWeekIndex = currentWeekIndex;
    if (newDayIndex >= 7) {
      newDayIndex = 0;
      newWeekIndex = (currentWeekIndex + 1).clamp(0, 3);
    }
    _updateProgressOnServer(newWeekIndex, newDayIndex);
  }

  void _checkIfDayIsComplete() {
    if (workoutPlan == null) return;
    int currentWeekIndex = workoutPlan!["currentWeekIndex"];
    int currentDayIndex = workoutPlan!["currentDayIndex"];
    String weekKey = "Week ${currentWeekIndex + 1}";
    String dayKey = "Day ${currentDayIndex + 1}";
    List<dynamic> allExercisesForToday = workoutPlan!["weekly_plan"][weekKey][dayKey] ?? [];

    if (allExercisesForToday.isNotEmpty && _completedExercises.containsAll(allExercisesForToday.cast<String>())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Day complete! Advancing to the next day.')),
      );
      _completeDayAndProceed();
    }
  }

  void _showWorkoutCompletedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("💪 Day Already Completed"),
        content: const Text("You've already finished the workouts for this day."),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK"))],
      ),
    );
  }

  Widget _buildWorkoutPlan() {
    if (workoutPlan == null) return Container();
    final goal = workoutPlan!["goal"];
    final isWeightLoss = goal == "weight_loss";
    final currentWeekIndex = workoutPlan!["currentWeekIndex"] ?? 0;
    final currentDayIndex = workoutPlan!["currentDayIndex"] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: isWeightLoss ? Colors.blue[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isWeightLoss ? Colors.blue[100]! : Colors.orange[100]!)),
          child: Row(children: [
            Icon(isWeightLoss ? Icons.favorite : Icons.fitness_center, color: isWeightLoss ? Colors.blue[700] : Colors.orange[700], size: 32),
            const SizedBox(width: 16),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isWeightLoss ? "Weight Loss Program" : "Muscle Gain Program", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isWeightLoss ? Colors.blue[800] : Colors.orange[800])),
                  const SizedBox(height: 4),
                  Text(isWeightLoss ? "5 workout days, 2 rest days" : "6 workout days, 1 rest day", style: TextStyle(color: isWeightLoss ? Colors.blue[600] : Colors.orange[600], fontSize: 14))
                ]))
          ]),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoColumn("Goal", workoutPlan!["goal"].toString().replaceAll("_", " ").toUpperCase()),
              _buildInfoColumn("Sets", workoutPlan!["sets"].toString()),
              _buildInfoColumn("Reps", workoutPlan!["reps"].toString())
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("4-Week Workout Plan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]))),
        const SizedBox(height: 16),
        Expanded(
          child: DefaultTabController(
            length: 4,
            initialIndex: currentWeekIndex.clamp(0, 3),
            child: Column(children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: TabBar(
                    indicator: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.deepPurple, width: 3.0))),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.deepPurple,
                    unselectedLabelColor: Colors.grey[600],
                    tabs: const [Tab(text: "Week 1"), Tab(text: "Week 2"), Tab(text: "Week 3"), Tab(text: "Week 4")]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: List.generate(4, (weekIndex) {
                    final weekKey = "Week ${weekIndex + 1}";
                    final weekData = workoutPlan!["weekly_plan"][weekKey];
                    final allDays = ["Day 1", "Day 2", "Day 3", "Day 4", "Day 5", "Day 6", "Day 7"];
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: allDays.map((dayName) {
                        final dayIndex = allDays.indexOf(dayName);
                        final dayData = weekData[dayName];
                        final isRestDay = dayData is List && dayData.isNotEmpty && dayData[0] == "Rest Day";
                        final exercises = isRestDay ? ["Rest Day"] : (dayData ?? ["Rest Day"]);
                        final isToday = weekIndex == currentWeekIndex && dayIndex == currentDayIndex;
                        final isPastDay = weekIndex < currentWeekIndex || (weekIndex == currentWeekIndex && dayIndex < currentDayIndex);
                        final isLocked = weekIndex > currentWeekIndex || (weekIndex == currentWeekIndex && dayIndex > currentDayIndex);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            title: Row(children: [
                              Text(dayName, style: TextStyle(fontWeight: FontWeight.w600, color: isLocked ? Colors.grey : Colors.grey[800])),
                              const SizedBox(width: 8),
                              Icon(isRestDay ? Icons.hotel : isLocked ? Icons.lock : Icons.fitness_center, color: isRestDay ? Colors.green[600] : isLocked ? Colors.grey : Colors.blue[600], size: 20)
                            ]),
                            children: [
                              if (isRestDay && isToday)
                                Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(children: [
                                      const Text("Rest and Recovery Day", style: TextStyle(fontStyle: FontStyle.italic)),
                                      const SizedBox(height: 16),
                                      ElevatedButton(onPressed: _completeDayAndProceed, child: const Text("Complete Rest Day"))
                                    ]))
                              else if (isRestDay)
                                const ListTile(title: Text("Rest and Recovery Day", style: TextStyle(fontStyle: FontStyle.italic)))
                              else if (isLocked || isPastDay)
                                  ListTile(
                                    title: Text(isPastDay ? "This day is already complete." : "Complete previous days to unlock.",
                                        style: TextStyle(color: isPastDay ? Colors.green : Colors.red[400], fontStyle: FontStyle.italic)),
                                    onTap: isPastDay ? _showWorkoutCompletedDialog : null,
                                  )
                                else
                                  ...exercises.map((exercise) {
                                    final bool isExerciseCompleted = _completedExercises.contains(exercise);
                                    return ListTile(
                                      leading: Icon(Icons.fitness_center, size: 20, color: Colors.deepPurple[400]),
                                      title: Text(exercise,
                                          style: TextStyle(
                                              decoration: isExerciseCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                              color: isExerciseCompleted ? Colors.grey : Colors.grey[800])),
                                      trailing: IconButton(
                                        icon: Icon(isExerciseCompleted ? Icons.check_circle : Icons.camera_alt, color: isExerciseCompleted ? Colors.green : Colors.deepPurple[400]),
                                        onPressed: () {
                                          if (isToday && !isExerciseCompleted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CameraWorkoutScreen(
                                                  userId: widget.userId,
                                                  exercise: exercise,
                                                  reps: int.parse(workoutPlan!["reps"].toString()),
                                                  sets: int.parse(workoutPlan!["sets"].toString()),
                                                  onExerciseCompleted: (completed, completedExercise) {
                                                    if (completed) {
                                                      setState(() => _completedExercises.add(completedExercise));
                                                      _checkIfDayIsComplete();
                                                    }
                                                  },
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  }).toList(),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ),
              )
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(children: [
      Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (checkingPlan) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.deepPurple, title: const Text("Workout Plan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
        body: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Checking your workout plan...")])),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text("Workout Plan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: false,
          elevation: 0),
      body: isLoading
          ? Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)),
            const SizedBox(height: 20),
            Text("Creating your personalized plan...", style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.w500))
          ]))
          : (workoutPlan == null && errorMessage == null)
          ? SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]),
                child: const Column(children: [
                  Icon(Icons.fitness_center, size: 60, color: Colors.white),
                  SizedBox(height: 15),
                  Text("Personalized Workout Plan", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                  SizedBox(height: 10),
                  Text("Tailored to your fitness goals", style: TextStyle(fontSize: 16, color: Colors.white70))
                ])),
            const SizedBox(height: 30),
            Row(children: [
              _buildFeatureCard(icon: Icons.calendar_today, title: "4-Week Program", subtitle: "Structured progression", color: Colors.blue),
              const SizedBox(width: 12),
              _buildFeatureCard(icon: Icons.directions_run, title: "Dumbbell Only", subtitle: "Home-friendly workouts", color: Colors.green)
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _buildFeatureCard(icon: Icons.timer, title: "Smart Planning", subtitle: "Optimal rest days", color: Colors.orange),
              const SizedBox(width: 12),
              _buildFeatureCard(icon: Icons.track_changes, title: "Goal-Oriented", subtitle: "Based on your objectives", color: Colors.purple)
            ]),
            const SizedBox(height: 30),
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.format_quote, color: Colors.deepPurple[300], size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("Our AI-powered system creates the perfect workout plan based on your goals, fitness level, and available equipment.", style: TextStyle(fontSize: 14, color: Colors.grey[700], fontStyle: FontStyle.italic)),
                        const SizedBox(height: 10),
                        Text("- RepEat Fitness Team", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold))
                      ]))
                ])),
            const SizedBox(height: 30),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: _generateWorkoutPlan,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        shadowColor: Colors.deepPurple.withOpacity(0.4)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.auto_awesome, size: 20),
                      SizedBox(width: 10),
                      Text("Generate My Workout Plan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                    ]))),
            const SizedBox(height: 20),
            Text("This will create a personalized 4-week plan that you can follow", style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center)
          ]))
          : Column(children: [
        if (errorMessage != null)
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[200]!)),
              child: Row(children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage!, style: TextStyle(color: Colors.red[700], fontSize: 14)))
              ])),
        if (workoutPlan != null) Expanded(child: _buildWorkoutPlan())
      ]),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))]),
        child: Column(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[600]), textAlign: TextAlign.center)
        ]),
      ),
    );
  }
}