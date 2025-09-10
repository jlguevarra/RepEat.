import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'camera_workout_screen1.dart'; // Updated to use the correct filename

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

  @override
  void initState() {
    super.initState();
    _checkIfUserHasPlan();
  }

  Future<void> _checkIfUserHasPlan() async {
    setState(() {
      checkingPlan = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.78/repEatApi/check_workout_plan.php"),
        body: {"user_id": widget.userId.toString()},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["success"] == true) {
          if (data["has_plan"] == true) {
            _loadWorkoutPlan();
          } else {
            setState(() {
              checkingPlan = false;
            });
          }
        } else {
          setState(() {
            checkingPlan = false;
            errorMessage = data["message"] ?? "Error checking workout plan";
          });
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
    });

    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.78/repEatApi/get_workout_plan.php"),
        body: {"user_id": widget.userId.toString()},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["success"] == true) {
          setState(() {
            workoutPlan = data;
            checkingPlan = false;
          });
        } else {
          setState(() {
            checkingPlan = false;
            errorMessage = data["message"] ?? "Error loading workout plan";
          });
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _generateWorkoutPlan() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.78/repEatApi/generate_workout.php"),
        body: {"user_id": widget.userId.toString()},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["success"] == true) {
          setState(() {
            workoutPlan = data;
          });
        } else {
          setState(() {
            errorMessage = data["message"] ?? "Unknown error occurred";
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Exception: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildWorkoutPlan() {
    if (workoutPlan == null) return Container();

    final goal = workoutPlan!["goal"];
    final isWeightLoss = goal == "weight_loss";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with goal-specific info
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isWeightLoss ? Colors.blue[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWeightLoss ? Colors.blue[100]! : Colors.orange[100]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isWeightLoss ? Icons.favorite : Icons.fitness_center,
                color: isWeightLoss ? Colors.blue[700] : Colors.orange[700],
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWeightLoss ? "Weight Loss Program" : "Muscle Gain Program",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isWeightLoss ? Colors.blue[800] : Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWeightLoss
                          ? "5 workout days, 2 rest days per week"
                          : "6 workout days, 1 rest day per week",
                      style: TextStyle(
                        color: isWeightLoss ? Colors.blue[600] : Colors.orange[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sets and Reps info
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn("Goal", workoutPlan!["goal"].toString().replaceAll("_", " ").toUpperCase()),
                _buildInfoColumn("Sets", workoutPlan!["sets"].toString()),
                _buildInfoColumn("Reps", workoutPlan!["reps"].toString()),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Weekly plan header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "4-Week Workout Plan",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Week tabs
        Expanded(
          child: DefaultTabController(
            length: 4,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.deepPurple,
                          width: 3.0,
                        ),
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 3.0,
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                    labelColor: Colors.deepPurple,
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: "Week 1"),
                      Tab(text: "Week 2"),
                      Tab(text: "Week 3"),
                      Tab(text: "Week 4"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: List.generate(4, (weekIndex) {
                      final weekKey = "Week ${weekIndex + 1}";
                      final weekData = workoutPlan!["weekly_plan"][weekKey];

                      final allDays = [
                        "Monday", "Tuesday", "Wednesday", "Thursday",
                        "Friday", "Saturday", "Sunday"
                      ];

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: allDays.map((dayName) {
                          final exercises = weekData[dayName] ?? ["Rest Day"];
                          final isRestDay = exercises[0] == "Rest Day";

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                              title: Row(
                                children: [
                                  Text(
                                    dayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isRestDay ? Icons.hotel : Icons.fitness_center,
                                    color: isRestDay ? Colors.green[600] : Colors.blue[600],
                                    size: 20,
                                  )
                                ],
                              ),
                              children: [
                                if (isRestDay)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      "Rest and Recovery Day",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                else
                                  ...exercises.map<Widget>((exercise) {
                                    return ListTile(
                                      leading: Icon(
                                        Icons.fitness_center,
                                        size: 20,
                                        color: Colors.deepPurple[400],
                                      ),
                                      title: Text(
                                        exercise,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.camera_alt,
                                          color: Colors.deepPurple[400],
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CameraWorkoutScreen(
                                                userId: widget.userId,
                                                category: workoutPlan!["goal"].toString().replaceAll("_", " ").toUpperCase(),
                                                exercise: exercise,
                                                onExerciseCompleted: (completed) {
                                                  if (completed) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('✅ $exercise completed!')),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          );
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
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (checkingPlan) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text(
            "Workout Plan",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                strokeWidth: 4,
              ),
              SizedBox(height: 16),
              Text(
                "Checking your workout plan...",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          "Workout Plan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              strokeWidth: 4,
            ),
            const SizedBox(height: 20),
            Text(
              "Creating your personalized plan...",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "This may take a few moments",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : (workoutPlan == null && errorMessage == null)
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Personalized Workout Plan",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Tailored to your fitness goals",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Benefits Section
            Row(
              children: [
                _buildFeatureCard(
                  icon: Icons.calendar_today,
                  title: "4-Week Program",
                  subtitle: "Structured progression",
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildFeatureCard(
                  icon: Icons.directions_run,
                  title: "Dumbbell Only",
                  subtitle: "Home-friendly workouts",
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _buildFeatureCard(
                  icon: Icons.timer,
                  title: "Smart Planning",
                  subtitle: "Optimal rest days",
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildFeatureCard(
                  icon: Icons.track_changes,
                  title: "Goal-Oriented",
                  subtitle: "Based on your objectives",
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Testimonial Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    color: Colors.deepPurple[300],
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Our AI-powered system creates the perfect workout plan based on your goals, fitness level, and available equipment.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "- RepEat Fitness Team",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateWorkoutPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Colors.deepPurple.withOpacity(0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Generate My Workout Plan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Note
            Text(
              "This will create a personalized 4-week plan that you can follow",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : Column(
        children: [
          if (errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (workoutPlan != null)
            Expanded(
              child: _buildWorkoutPlan(),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}