import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_workout_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final int userId;

  const WorkoutScreen({super.key, required this.userId});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Map<String, dynamic>? weeklyPlan;
  bool isLoading = false;
  bool showAnimation = false;
  int currentWeek = 1;
  int currentDay = 1;
  int daysCompleted = 0;
  double progressValue = 0.0;
  List<bool> exerciseCompletion = List.filled(5, false);
  List<bool> dayCompletion = List.filled(28, false); // Changed from 7 to 28
  Map<String, List<bool>> exerciseCameraCompletion = {};
  bool hasPlan = false;

  @override
  void initState() {
    super.initState();
    _loadPlanFromStorage().then((_) {
      if (weeklyPlan == null) {
        checkSavedPlan();
      }
    });
    _loadProgressFromStorage();
  }

  /// ✅ Load saved plan if available
  Future<void> _loadPlanFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlan = prefs.getString('weeklyPlan_${widget.userId}');
    if (savedPlan != null) {
      setState(() {
        weeklyPlan = json.decode(savedPlan);
        _initializeCameraCompletion(weeklyPlan!);
      });
    }
  }

  /// ✅ Save plan locally
  Future<void> _savePlanToStorage(Map<String, dynamic> plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weeklyPlan_${widget.userId}', json.encode(plan));
    setState(() {
      hasPlan = true;
    });
  }

  Future<void> fetchWeeklyPlan() async {
    setState(() {
      isLoading = true;
      showAnimation = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.78/repEatApi/get_weekly_challenge.php"),
        body: {"user_id": widget.userId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["success"] == true) {
          setState(() {
            weeklyPlan = data;
            hasPlan = true;
            _initializeCameraCompletion(data);
          });

          await _savePlanToStorage(data);
          await saveGeneratedPlan(data);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${data["message"]}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server error")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exception: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
        showAnimation = false;
      });
    }
  }

  Future<void> checkSavedPlan() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.78/repEatApi/get_weekly_challenge.php"),
        body: {"user_id": widget.userId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["success"] == true) {
          setState(() {
            weeklyPlan = data;
            hasPlan = true;

            if (data["from_saved"] == true) {
              debugPrint("✅ Loaded saved plan from database");
              _loadProgressFromStorage();
            } else {
              debugPrint("🔄 Generated new plan (already saved by PHP)");
              _saveProgressToStorage();
            }
            _initializeCameraCompletion(data);
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking saved plan: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveGeneratedPlan(Map<String, dynamic> plan) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.78/repEatApi/save_weekly_plan.php"),
        body: {
          "user_id": widget.userId.toString(),
          "week": "Week $currentWeek",
          "goal": plan["goal"].toString(),
          "sets": plan["sets"].toString(),
          "reps": plan["reps"].toString(),
          "plan_json": jsonEncode(plan["daily_exercises"]),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true) {
          _saveProgressToStorage();
        }
      }
    } catch (e) {
      debugPrint("❌ Error saving plan: $e");
    }
  }

  Future<void> _saveProgressToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressData = {
        "currentWeek": currentWeek,
        "currentDay": currentDay,
        "daysCompleted": daysCompleted,
        "progressValue": progressValue,
        "dayCompletion": dayCompletion,
        "exerciseCameraCompletion": exerciseCameraCompletion,
      };

      await prefs.setString(
          'workout_progress_${widget.userId}', jsonEncode(progressData));
    } catch (e) {
      debugPrint("❌ Error saving progress to storage: $e");
    }
  }

  Future<void> _loadProgressFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressDataString =
      prefs.getString('workout_progress_${widget.userId}');

      if (progressDataString != null) {
        final progressData = json.decode(progressDataString);
        setState(() {
          currentWeek = progressData["currentWeek"] ?? 1;
          currentDay = progressData["currentDay"] ?? 1;
          daysCompleted = progressData["daysCompleted"] ?? 0;
          progressValue = (progressData["progressValue"] ?? 0.0).toDouble();

          // Handle both old (7 days) and new (28 days) format
          final savedDayCompletion = progressData["dayCompletion"];
          if (savedDayCompletion != null) {
            if (savedDayCompletion.length == 7) {
              // Convert from 7 days to 28 days format
              dayCompletion = List<bool>.from(savedDayCompletion + List.filled(21, false));
            } else {
              dayCompletion = List<bool>.from(savedDayCompletion);
            }
          } else {
            dayCompletion = List.filled(28, false);
          }

          if (progressData["exerciseCameraCompletion"] != null) {
            exerciseCameraCompletion = Map<String, List<bool>>.from(
                progressData["exerciseCameraCompletion"].map((key, value) =>
                    MapEntry(key, List<bool>.from(value))));
          }
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading progress from storage: $e");
    }
  }

  void _initializeCameraCompletion(Map<String, dynamic> data) {
    final dayNames = [
      "Monday", "Tuesday", "Wednesday", "Thursday",
      "Friday", "Saturday", "Sunday"
    ];

    for (var day in dayNames) {
      if (data["daily_exercises"] != null && data["daily_exercises"][day] != null) {
        if (!exerciseCameraCompletion.containsKey(day)) {
          exerciseCameraCompletion[day] =
              List.filled(data["daily_exercises"][day].length, false);
        }
      }
    }
  }

  void _navigateToCameraWorkout(int exerciseIndex, String exerciseName) {
    String category = "Arms";

    if (exerciseName.toLowerCase().contains("chest")) {
      category = "Chest";
    } else if (exerciseName.toLowerCase().contains("leg") ||
        exerciseName.toLowerCase().contains("squat")) {
      category = "Legs";
    } else if (exerciseName.toLowerCase().contains("back")) {
      category = "Back";
    } else if (exerciseName.toLowerCase().contains("shoulder")) {
      category = "Shoulders";
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraWorkoutScreen(
          userId: widget.userId,
          category: category,
          exercise: exerciseName,
          onExerciseCompleted: (bool completed) {
            if (completed) {
              setState(() {
                final dayNames = [
                  "Monday", "Tuesday", "Wednesday", "Thursday",
                  "Friday", "Saturday", "Sunday"
                ];

                // Calculate which day of the week we're on (0-6)
                final weekDayIndex = (currentDay - 1) % 7;

                // Safety check
                if (weekDayIndex >= 0 && weekDayIndex < dayNames.length) {
                  final currentDayName = dayNames[weekDayIndex];

                  if (exerciseCameraCompletion.containsKey(currentDayName) &&
                      exerciseIndex < exerciseCameraCompletion[currentDayName]!.length) {
                    exerciseCameraCompletion[currentDayName]![exerciseIndex] = true;

                    // Check if all exercises for the day are completed
                    if (exerciseCameraCompletion[currentDayName]!.every((e) => e)) {
                      _markDayCompleted();
                    } else {
                      _saveProgressToStorage();
                    }
                  }
                }
              });
            }
          },
        ),
      ),
    );
  }

  void _markDayCompleted() {
    setState(() {
      daysCompleted++;
      progressValue = daysCompleted / 28; // Changed from 7 to 28
      dayCompletion[currentDay - 1] = true;

      _saveProgressToStorage();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Day $currentDay completed! Great job!")),
    );
  }
  // Check if a day is unlocked (previous day is completed)
  bool _isDayUnlocked(int dayNumber) {
    if (dayNumber == 1) return true; // Day 1 is always unlocked
    if (dayNumber < 1 || dayNumber > 28) return false;
    return _isDayCompleted(dayNumber - 1); // Previous day must be completed
  }

  // Check if a day is completed
  bool _isDayCompleted(int dayNumber) {
    if (dayNumber < 1 || dayNumber > 28) return false;
    return dayCompletion[dayNumber - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("30-Day Challenge",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: false,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              strokeWidth: 4,
            ),
            SizedBox(height: 16),
            Text(
              "Creating your plan...",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      )
          : weeklyPlan == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/workout.png",
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              "30-Day Fitness Challenge",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                "Start your transformation journey today! Complete each day to unlock the next.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: fetchWeeklyPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Start Challenge",
                  style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with progress
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${28 - daysCompleted} Days left", // Changed from calculation to simple subtraction
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${(progressValue * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.deepPurple[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Day $currentDay/28 - ${((currentDay - 1) ~/ 7) + 1}/4 Weeks", // Added week info
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Week section
            Text(
              "Week ${((currentDay - 1) ~/ 7) + 1} of 4",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Day $currentDay/28",
              style: TextStyle(
                  fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // Day navigation - 4 weeks of 7 days
            Column(
              children: [
                // Week 1
                _buildWeekRow(1, 7),
                const SizedBox(height: 10),
                // Week 2
                _buildWeekRow(8, 14),
                const SizedBox(height: 10),
                // Week 3
                _buildWeekRow(15, 21),
                const SizedBox(height: 10),
                // Week 4
                _buildWeekRow(22, 28),
              ],
            ),
            const SizedBox(height: 20),

            // Only show exercises if current day is unlocked
            if (_isDayUnlocked(currentDay)) ...[
              Text(
                "Day $currentDay Exercises",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._buildExerciseList(),
              const SizedBox(height: 20),

              // Sets and reps info
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          "${weeklyPlan!["sets"]}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text("Sets", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          "${weeklyPlan!["reps"]}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text("Reps", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          weeklyPlan!["goal"].toString().toUpperCase(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text("Goal", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              // Complete button only if day is unlocked but not completed
              if (!_isDayCompleted(currentDay))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _markDayCompleted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("COMPLETE DAY",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
            ] else ...[
              // Show locked message if day is not unlocked
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock, size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      "Day $currentDay is locked",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Complete the previous day to unlock this workout",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekRow(int startDay, int endDay) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(endDay - startDay + 1, (index) {
        final dayNumber = startDay + index;

        // Safety check to ensure dayNumber is within valid range
        if (dayNumber < 1 || dayNumber > 28) {
          return Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
          );
        }

        final isUnlocked = _isDayUnlocked(dayNumber);
        final isCompleted = _isDayCompleted(dayNumber);
        final isCurrent = currentDay == dayNumber;

        return GestureDetector(
          onTap: isUnlocked
              ? () {
            setState(() {
              currentDay = dayNumber;
              _saveProgressToStorage();
            });
          }
              : null,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrent
                  ? Colors.deepPurple
                  : isCompleted
                  ? Colors.green
                  : isUnlocked
                  ? Colors.blue[300]
                  : Colors.grey[300],
              shape: BoxShape.circle,
              border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Center(
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _buildExerciseList() {
    final dayNames = [
      "Monday", "Tuesday", "Wednesday", "Thursday",
      "Friday", "Saturday", "Sunday"
    ];

    // Calculate which day of the week we're on (0-6)
    final weekDayIndex = (currentDay - 1) % 7;

    // Safety check to ensure index is within bounds
    if (weekDayIndex < 0 || weekDayIndex >= dayNames.length) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            "No exercises scheduled for today",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
      ];
    }

    final currentDayName = dayNames[weekDayIndex];

    List<String> exercises = [];

    if (weeklyPlan!["daily_exercises"] != null &&
        weeklyPlan!["daily_exercises"][currentDayName] != null) {
      exercises = List<String>.from(weeklyPlan!["daily_exercises"][currentDayName]);
    } else if (weeklyPlan!["plan"] != null &&
        weeklyPlan!["plan"][currentDayName] != null) {
      exercises = weeklyPlan!["plan"][currentDayName].split(", ");
    }

    // If no exercises found, return a placeholder
    if (exercises.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            "Rest day! No exercises scheduled.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
      ];
    }

    return exercises.asMap().entries.map<Widget>((entry) {
      final index = entry.key;
      final exercise = entry.value;

      final isCompleted = exerciseCameraCompletion.containsKey(currentDayName) &&
          index < exerciseCameraCompletion[currentDayName]!.length &&
          exerciseCameraCompletion[currentDayName]![index];

      return GestureDetector(
        onTap: () => _isDayUnlocked(currentDay) ? _navigateToCameraWorkout(index, exercise) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green[50] : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCompleted ? Colors.green : Colors.grey[300]!,
              width: isCompleted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  exercise,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
              ),
              Icon(
                isCompleted ? Icons.check_circle : Icons.camera_alt,
                color: isCompleted ? Colors.green : Colors.deepPurple,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }}