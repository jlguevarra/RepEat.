import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'notes_calendar_screen.dart'; // MODIFIED: Import the new calendar screen

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
  int workoutsThisWeek = 0;
  int weeklyGoal = 0;

  List<Map<String, dynamic>> weeklyActivity = [];
  List<Map<String, dynamic>> upcomingWorkouts = [];

  Timer? _refreshTimer;

  // Colors for theming
  final Color _primaryColor = Colors.deepPurple;
  final Color _secondaryColor = const Color(0xFF6C63FF);
  final Color _accentColor = const Color(0xFF00BFA6);
  final Color _backgroundColor = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _lastRefreshDate = DateTime.now();
    _updateGreeting();
    _loadDailyQuote();
    _loadDashboardData();

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
        Uri.parse("http://192.168.100.79/repEatApi/dashboard.php"),
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
          workoutsThisWeek = data['workoutsThisWeek'] ?? 0;
          weeklyGoal = data['weeklyGoal'] ?? 5;
          weeklyActivity = List<Map<String, dynamic>>.from(data['weeklyActivity'] ?? []);
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
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _primaryColor),
              const SizedBox(height: 20),
              Text('Loading your fitness journey...',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: false,
        actions: const [],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: _primaryColor,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _greetingCard(),
              const SizedBox(height: 20),
              _weeklyGoalProgressCard(),
              const SizedBox(height: 20),
              _quickStatsGrid(),
              const SizedBox(height: 20),
              _weeklyActivitySection(),
              const SizedBox(height: 20),
              _upcomingWorkoutsSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _greetingCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _greeting,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.waving_hand, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _motivationalQuote,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyGoalProgressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: _primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Weekly Goal Progress",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Text(
                  "$workoutsThisWeek/$weeklyGoal",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: goalProgress),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOut,
                  builder: (context, value, _) => Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width * value * 0.7,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_secondaryColor, _accentColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              goalProgress >= 1
                  ? "🎉 Goal achieved! Keep it up!"
                  : "${((goalProgress) * 100).toStringAsFixed(0)}% complete",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickStatsGrid() {
    final stats = [
      {
        'title': 'Workouts',
        'value': workoutsCompleted.toString(),
        'icon': Icons.fitness_center,
        'color': _primaryColor,
        'subtitle': 'Completed'
      },
      {
        'title': 'Calories',
        'value': caloriesBurned.toString(),
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
        'subtitle': 'Burned'
      },
      {
        'title': 'Streak',
        'value': streakDays.toString(),
        'icon': Icons.whatshot,
        'color': Colors.red,
        'subtitle': 'Days'
      },
      {
        'title': 'Weight',
        'value': weight.toStringAsFixed(1),
        'icon': Icons.monitor_weight,
        'color': Colors.blue,
        'subtitle': 'kg'
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: stat['color'] as Color? ?? _primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(stat['icon'] as IconData?,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: stat['title'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: ' • ${stat['subtitle']}',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _weeklyActivitySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: _primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Weekly Activity",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Text(
                  "This Week",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: weeklyActivity.asMap().entries.map((entry) {
                  final dayData = entry.value;
                  final String day = dayData['day'] ?? '';
                  final bool isRestDay = dayData['isRestDay'] ?? true;
                  final List exercises = dayData['exercises'] ?? [];
                  final bool isActive = dayData['isActive'] ?? false;

                  return Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: exercises.isEmpty ? 20 : (20 + exercises.length * 15).toDouble(),
                          width: 12,
                          decoration: BoxDecoration(
                            gradient: isRestDay
                                ? null
                                : LinearGradient(
                              colors: isActive
                                  ? [_secondaryColor, _primaryColor]
                                  : [Colors.deepPurple.shade300, Colors.deepPurple.shade200],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            color: isRestDay ? Colors.grey.shade200 : null,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: isRestDay
                              ? Center(
                            child: Text(
                              "R",
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? _primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 10,
                              color: isActive ? Colors.white : Colors.grey.shade600,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // MODIFIED: Navigate to the new NotesCalendarScreen
                      builder: (_) => NotesCalendarScreen(userId: widget.userId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.calendar_month, size: 20),
                label: const Text("View Full Calendar"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _upcomingWorkoutsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upcoming, color: _primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Upcoming Workouts",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (upcomingWorkouts.isEmpty)
              _emptyStateWidget(
                icon: Icons.fitness_center,
                title: "No upcoming workouts",
                subtitle: "Schedule your next workout to see it here",
              )
            else
              Column(
                children: upcomingWorkouts.map((workout) {
                  final exercises = workout['title'] is List
                      ? List<String>.from(workout['title'])
                      : [];

                  if (exercises.isEmpty) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _accentColor),
                                ),
                                child: Text(
                                  "Today",
                                  style: TextStyle(
                                    color: _accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                "45 min",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...exercises.map((exercise) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    exercise,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                          const SizedBox(height: 8),
                          Divider(color: Colors.grey.shade200),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: const Text("Start Workout"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                              ),
                            ],
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

  Widget _emptyStateWidget({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // MODIFIED: Navigate to the new NotesCalendarScreen
                  builder: (_) => NotesCalendarScreen(userId: widget.userId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Plan Workout"),
          ),
        ],
      ),
    );
  }
}