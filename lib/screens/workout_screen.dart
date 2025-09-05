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
  List<bool> dayCompletion = List.filled(7, false);
  Map<String, List<bool>> exerciseCameraCompletion = {};

  @override
  void initState() {
    super.initState();
    _loadPlanFromStorage();
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
  }

  Future<void> fetchWeeklyPlan() async {
    setState(() {
      isLoading = true;
      showAnimation = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://localhost/repEatApi/get_weekly_challenge.php"),
        body: {"user_id": widget.userId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["success"] == true) {
          setState(() {
            weeklyPlan = data;
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
        Uri.parse("http://192.168.100.11/repEatApi/get_weekly_challenge.php"),
        body: {"user_id": widget.userId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["success"] == true) {
          setState(() {
            weeklyPlan = data;

            // Check if this is a saved plan or a new one
            if (data["from_saved"] == true) {
              debugPrint("✅ Loaded saved plan from database");
              // Load any saved progress if available
              _loadProgressFromStorage();
            } else {
              debugPrint("🔄 Generated new plan (already saved by PHP)");
              // No need to call saveGeneratedPlan anymore - it's done in PHP
              // Just save progress to local storage
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

  // Future<void> fetchWeeklyPlan() async {
  //   setState(() {
  //     isLoading = true;
  //     showAnimation = true;
  //   });
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse("http://192.168.100.11/repEatApi/get_weekly_challenge.php"),
  //       body: {"user_id": widget.userId.toString()},
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //
  //       if (data["success"] == true) {
  //         setState(() {
  //           weeklyPlan = data;
  //           _initializeCameraCompletion(data);
  //         });
  //
  //         // No need to call saveGeneratedPlan anymore since it's done in PHP
  //         // The plan is automatically saved when generated
  //
  //         // Save progress to local storage
  //         _saveProgressToStorage();
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text("Error: ${data["message"]}")),
  //         );
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Server error")),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Exception: $e")),
  //     );
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //       showAnimation = false;
  //     });
  //   }
  // }

// You can remove the saveGeneratedPlan method entirely since it's not needed anymore
  Future<void> saveGeneratedPlan(Map<String, dynamic> plan) async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost/repEatApi/save_weekly_plan.php"),
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
          dayCompletion = List<bool>.from(
              progressData["dayCompletion"] ?? List.filled(7, false));

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
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ];

    for (var day in dayNames) {
      if (data["daily_exercises"] != null &&
          data["daily_exercises"][day] != null) {
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
                  "Monday",
                  "Tuesday",
                  "Wednesday",
                  "Thursday",
                  "Friday",
                  "Saturday",
                  "Sunday"
                ];
                final currentDayName = dayNames[currentDay - 1];

                if (exerciseCameraCompletion.containsKey(currentDayName) &&
                    exerciseIndex <
                        exerciseCameraCompletion[currentDayName]!.length) {
                  exerciseCameraCompletion[currentDayName]![exerciseIndex] =
                  true;

                  if (exerciseCameraCompletion[currentDayName]!
                      .every((e) => e)) {
                    _markDayCompleted();
                  } else {
                    _saveProgressToStorage();
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
      progressValue = daysCompleted / 7;
      dayCompletion[currentDay - 1] = true;

      if (currentDay < 7) {
        currentDay++;
        final dayNames = [
          "Monday",
          "Tuesday",
          "Wednesday",
          "Thursday",
          "Friday",
          "Saturday",
          "Sunday"
        ];
        final nextDayName = dayNames[currentDay - 1];

        if (exerciseCameraCompletion.containsKey(nextDayName)) {
          exerciseCameraCompletion[nextDayName] =
              List.filled(exerciseCameraCompletion[nextDayName]!.length, false);
        }
      } else if (currentWeek < 4) {
        currentWeek++;
        currentDay = 1;
        daysCompleted = 0;
        progressValue = 0.0;
        dayCompletion = List.filled(7, false);
      }

      _saveProgressToStorage();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Day ${currentDay - 1} completed! Great job!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Workout",
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
              valueColor:
              AlwaysStoppedAnimation<Color>(Colors.deepPurple),
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
              "Start Your Fitness Journey",
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                "Tap below to generate your first weekly workout plan.",
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
              child: const Text("Generate Workout Plan",
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
            // same UI you had (progress bar, days, exercises, stats, complete button)
            _buildPlanContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header card
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
                    "${28 - (7 * (currentWeek - 1) + (currentDay - 1))} Days left",
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
              const Text(
                "Kick off your full-body fitness journey with energy!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          "Week $currentWeek",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          "$currentDay/7",
          style: TextStyle(
              fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    currentDay = index + 1;
                    _saveProgressToStorage();
                  });
                },
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: currentDay == index + 1
                        ? Colors.deepPurple
                        : dayCompletion[index]
                        ? Colors.green
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: currentDay == index + 1
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        Text(
          "Today's Exercises",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        ..._buildExerciseList(),

        const SizedBox(height: 20),
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
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text("Sets", style: TextStyle(color: Colors.grey)),
                ],
              ),
              Column(
                children: [
                  Text(
                    "${weeklyPlan!["reps"]}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text("Reps", style: TextStyle(color: Colors.grey)),
                ],
              ),
              Column(
                children: [
                  Text(
                    weeklyPlan!["goal"].toString().toUpperCase(),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text("Goal", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
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
      ],
    );
  }

  List<Widget> _buildExerciseList() {
    final dayNames = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ];
    final currentDayName = dayNames[currentDay - 1];

    List<String> exercises = [];

    if (weeklyPlan!["daily_exercises"] != null &&
        weeklyPlan!["daily_exercises"][currentDayName] != null) {
      exercises =
      List<String>.from(weeklyPlan!["daily_exercises"][currentDayName]);
    } else if (weeklyPlan!["plan"] != null &&
        weeklyPlan!["plan"][currentDayName] != null) {
      exercises = weeklyPlan!["plan"][currentDayName].split(", ");
    }

    return exercises.asMap().entries.map<Widget>((entry) {
      final index = entry.key;
      final exercise = entry.value;

      final isCompleted =
          exerciseCameraCompletion.containsKey(currentDayName) &&
              index < exerciseCameraCompletion[currentDayName]!.length &&
              exerciseCameraCompletion[currentDayName]![index];

      return GestureDetector(
        onTap: () => _navigateToCameraWorkout(index, exercise),
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
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
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
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
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
  }
}
