import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'camera_workout_screen.dart'; // Import your camera screen

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

  // Track which exercises have been completed with camera
  Map<String, List<bool>> exerciseCameraCompletion = {};

  Future<void> fetchWeeklyPlan() async {
    setState(() {
      isLoading = true;
      showAnimation = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.11/repEatApi/get_weekly_challenge.php"),
        body: {
          "user_id": widget.userId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["success"] == true) {
          setState(() {
            weeklyPlan = data;
            // Initialize camera completion tracking
            _initializeCameraCompletion(data);
          });
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

  void _initializeCameraCompletion(Map<String, dynamic> data) {
    final dayNames = [
      "Monday", "Tuesday", "Wednesday", "Thursday",
      "Friday", "Saturday", "Sunday"
    ];

    for (var day in dayNames) {
      if (data["daily_exercises"] != null &&
          data["daily_exercises"][day] != null) {
        exerciseCameraCompletion[day] =
            List.filled(data["daily_exercises"][day].length, false);
      }
    }
  }

  void _navigateToCameraWorkout(int exerciseIndex, String exerciseName) {
    // Extract category from exercise name if needed
    String category = "Arms"; // Default category, you can customize this

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
            // Update completion status when returning from camera
            if (completed) {
              setState(() {
                final dayNames = [
                  "Monday", "Tuesday", "Wednesday", "Thursday",
                  "Friday", "Saturday", "Sunday"
                ];
                final currentDayName = dayNames[currentDay - 1];

                if (exerciseCameraCompletion.containsKey(currentDayName) &&
                    exerciseIndex < exerciseCameraCompletion[currentDayName]!.length) {
                  exerciseCameraCompletion[currentDayName]![exerciseIndex] = true;

                  // Check if all exercises for the day are completed
                  if (exerciseCameraCompletion[currentDayName]!.every((e) => e)) {
                    _markDayCompleted();
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
        // Reset exercise completion for the new day
        final dayNames = [
          "Monday", "Tuesday", "Wednesday", "Thursday",
          "Friday", "Saturday", "Sunday"
        ];
        final nextDayName = dayNames[currentDay - 1];

        if (exerciseCameraCompletion.containsKey(nextDayName)) {
          exerciseCameraCompletion[nextDayName] =
              List.filled(exerciseCameraCompletion[nextDayName]!.length, false);
        }
      } else if (currentWeek < 4) {
        currentWeek++;
        currentDay = 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Day $currentDay completed! Great job!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("FULL BODY CHALLENGE",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              "assets/animations/loading.json",
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 16),
            const Text(
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
                "Kick off your full-body fitness journey with energy!",
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
                        "${28 - (7 * (currentWeek - 1) + (currentDay - 1))} Days left",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${(progressValue * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.deepPurple[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white),
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

            // Week section
            Text(
              "Week $currentWeek",
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "$currentDay/7",
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // Day navigation
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

            // Exercises for the current day
            Text(
              "Today's Exercises",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Get current day name and exercises
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
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text("Sets",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        "${weeklyPlan!["reps"]}",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text("Reps",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        weeklyPlan!["goal"]
                            .toString()
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text("Goal",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            // Complete button
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
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Meal Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: 1,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  List<Widget> _buildExerciseList() {
    final dayNames = [
      "Monday", "Tuesday", "Wednesday", "Thursday",
      "Friday", "Saturday", "Sunday"
    ];
    final currentDayName = dayNames[currentDay - 1];

    // Get exercises for the current day
    List<String> exercises = [];

    if (weeklyPlan!["daily_exercises"] != null &&
        weeklyPlan!["daily_exercises"][currentDayName] != null) {
      exercises = List<String>.from(weeklyPlan!["daily_exercises"][currentDayName]);
    } else if (weeklyPlan!["plan"] != null &&
        weeklyPlan!["plan"][currentDayName] != null) {
      exercises = weeklyPlan!["plan"][currentDayName].split(", ");
    }

    return exercises.asMap().entries.map<Widget>((entry) {
      final index = entry.key;
      final exercise = entry.value;

      final isCompleted = exerciseCameraCompletion.containsKey(currentDayName) &&
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
              // Exercise number
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
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (exercise.contains('('))
                      Text(
                        exercise.substring(exercise.indexOf('(')),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
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