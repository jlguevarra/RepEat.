import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'calendar_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;

  const DashboardScreen({super.key, required this.userId});



  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _motivationalQuote;
  late String _greeting;

  bool _isRefreshing = false;
  bool _isLoading = true;
  late DateTime _lastRefreshDate;
  double get goalProgress {
    if (weeklyGoal == 0) return 0;
    return (workoutsThisWeek / weeklyGoal).clamp(0, 1);
  }

  int workoutsCompleted = 0;
  int caloriesBurned = 0;
  int streakDays = 0;
  double weight = 0;
  int workoutsThisWeek = 0; // from API
  int weeklyGoal = 0;       // from API

// Temporary static data for testing
  List<Map<String, dynamic>> weeklyActivity = [
    {
      "day": "Mon",
      "isRestDay": false,
      "exercises": ["Dumbbell Bench Press", "Bicep Curls"]
    },
    {
      "day": "Tue",
      "isRestDay": false,
      "exercises": ["Shoulder Press", "Tricep Extensions"]
    },
    {
      "day": "Wed",
      "isRestDay": false,
      "exercises": ["Squats", "Lunges", "Plank"]
    },
    {
      "day": "Thu",
      "isRestDay": true,
      "exercises": []
    },
    {
      "day": "Fri",
      "isRestDay": false,
      "exercises": ["Shoulder Press", "Tricep Extensions"]
    },
    {
      "day": "Sat",
      "isRestDay": false,
      "exercises": ["Deadlifts", "Pull-ups"]
    },
    {
      "day": "Sun",
      "isRestDay": true,
      "exercises": []
    },
  ];


  //List<Map<String, dynamic>> weeklyActivity = [];
  List<Map<String, dynamic>> weeklyProgress = [];
  List<Map<String, dynamic>> upcomingWorkouts = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _lastRefreshDate = DateTime.now();
    _updateGreeting();
    _loadDailyQuote();
    _loadDashboardData();

    // Auto-refresh every 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  void _loadDailyQuote() {
    final quotes = [
      "The only bad workout is the one that didn't happen",
      "Your body can stand almost anything. It's your mind you have to convince",
      "Success starts with self-discipline",
      "Don't stop when you're tired. Stop when you're done",
      "Wake up with determination. Go to bed with satisfaction"
    ];
    final dayOfYear = DateTime.now().day;
    _motivationalQuote = quotes[dayOfYear % quotes.length];
  }

  Future<void> _loadDashboardData() async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost/repEatApi/dashboard.php"),
        body: {"user_id": widget.userId.toString()},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['error'] != null) {
          debugPrint("API Error: ${data['error']}");
          return;
        }

        setState(() {
          workoutsCompleted = data['workoutsCompleted'] ?? 0;
          caloriesBurned = data['caloriesBurned'] ?? 0;
          streakDays = data['streakDays'] ?? 0;

          weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
          List<Map<String, dynamic>> weeklyActivity = [];
          weeklyProgress = List<Map<String, dynamic>>.from(data['weeklyProgress'] ?? []);
          upcomingWorkouts = List<Map<String, dynamic>>.from(data['upcomingWorkouts'] ?? []);
          _isLoading = false;
        });
      } else {
        debugPrint("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API Exception: $e");
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadDashboardData();
    _updateGreeting();
    if (!DateUtils.isSameDay(_lastRefreshDate, DateTime.now())) {
      _loadDailyQuote();
    }
    _lastRefreshDate = DateTime.now();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Dashboard"),
        backgroundColor: Colors.deepPurple,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _greetingCard(_greeting, _motivationalQuote),
              const SizedBox(height: 20),
              _weeklyGoalProgressBar(), // ✅ must be here
              const SizedBox(height: 20),

              _quickStatsRow(),
              const SizedBox(height: 20),
              _weeklyProgressSection(context),
              const SizedBox(height: 20),
              _upcomingWorkoutsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weeklyGoalProgressBar() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Weekly Goal Progress",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // ✅ Animated progress bar
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: goalProgress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 6),

            // ✅ Animated text
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: workoutsThisWeek.toDouble()),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, _) => Text(
                "${value.toStringAsFixed(0)} of $weeklyGoal workouts completed",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _greetingCard(String greeting, String quote) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(quote,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _quickStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statCard("Workouts", "$workoutsCompleted", Icons.fitness_center),
          const SizedBox(width: 12),
          _statCard("Calories", "$caloriesBurned", Icons.local_fire_department),
          const SizedBox(width: 12),
          _statCard("Streak", "$streakDays days", Icons.whatshot),
          const SizedBox(width: 12),
          _statCard("Weight", "${weight.toStringAsFixed(1)} kg", Icons.monitor_weight),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 100,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: Colors.deepPurple),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weeklyProgressSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Weekly Activity",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: weeklyActivity.map((dayData) {
                  final String day = dayData['day'] ?? '';
                  final bool isRestDay = dayData['isRestDay'] ?? true;
                  final List exercises = dayData['exercises'] ?? [];

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bar color based on rest or active
                      Container(
                        height: 60,
                        width: 12,
                        decoration: BoxDecoration(
                          color: isRestDay
                              ? Colors.grey.shade300
                              : Colors.deepPurple,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Day label
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          color: isRestDay
                              ? Colors.grey.shade500
                              : Colors.deepPurple.shade700,
                          fontWeight:
                          isRestDay ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),

                      // Rest day label
                      if (isRestDay)
                        const Text(
                          "Rest Day",
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GymPlannerScreen(userId: widget.userId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("View Full Calendar"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressBar(int percentage, String day) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 14,
          height: percentage.toDouble(),
          decoration: BoxDecoration(
            color: percentage >= 80 ? Colors.green : Colors.deepPurple,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _upcomingWorkoutsSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Upcoming Workouts",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (upcomingWorkouts.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No upcoming workouts planned",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Create a workout plan to see your schedule",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: upcomingWorkouts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final workout = entry.value;

                  // Safely handle date with null check
                  final dateString = workout['time']?.toString();
                  if (dateString == null || dateString.isEmpty) {
                    return const SizedBox.shrink(); // Skip invalid entries
                  }

                  DateTime date;
                  try {
                    date = DateTime.parse(dateString).toLocal(); // ✅ Adjust to local time
                  } catch (e) {
                    return const SizedBox.shrink(); // Skip invalid date formats
                  }

                  final isToday = DateUtils.isSameDay(date, DateTime.now());
                  final isTomorrow = DateUtils.isSameDay(
                      date,
                      DateTime.now().add(const Duration(days: 1))
                  );

                  String dayLabel;
                  if (isToday) {
                    dayLabel = "Today";
                  } else if (isTomorrow) {
                    dayLabel = "Tomorrow";
                  } else {
                    dayLabel = DateFormat('EEEE').format(date);
                  }

                  // Safely handle workout titles (array of exercises)
                  List<String> workoutExercises = [];
                  final exercisesData = workout['title'];

                  if (exercisesData is List) {
                    workoutExercises = exercisesData.whereType<String>().where((exercise) => exercise.isNotEmpty).toList();
                  } else if (exercisesData is String && exercisesData.isNotEmpty) {
                    workoutExercises = [exercisesData];
                  }

                  // Skip if no valid exercises
                  if (workoutExercises.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  dayLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMM d').format(date),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Display exercises with proper alignment
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: workoutExercises.map((exercise) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      exercise,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
  Widget _workoutItem(String title, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              // TODO: Navigate to workout details screen
              debugPrint("Tapped on $title");
            },
          ),
        ],
      ),
    );
  }
}