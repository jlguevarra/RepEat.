import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'package:intl/intl.dart';

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
  late DateTime _lastRefreshDate;

  @override
  void initState() {
    super.initState();
    _lastRefreshDate = DateTime.now();
    _updateGreeting();
    _loadDailyQuote();
  }

  void _updateGreeting() {
    final currentTime = DateTime.now();
    final hour = currentTime.hour;

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

    // Use the day of year to get a consistent daily quote
    final dayOfYear = DateTime.now().day;
    _motivationalQuote = quotes[dayOfYear % quotes.length];
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Simulate network request
    await Future.delayed(const Duration(seconds: 1));

    _updateGreeting();
    // Only change quote if it's a new day
    if (!DateUtils.isSameDay(_lastRefreshDate, DateTime.now())) {
      _loadDailyQuote();
    }
    _lastRefreshDate = DateTime.now();

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _greetingCard(String greeting, String quote) {
    return SizedBox(
      height: 150, // Fixed height container
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    quote,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statCard("Workouts", "5", Icons.fitness_center),
          const SizedBox(width: 12),
          _statCard("Calories", "1,240", Icons.local_fire_department),
          const SizedBox(width: 12),
          _statCard("Streak", "7 days", Icons.whatshot),
          const SizedBox(width: 12),
          _statCard("Weight", "75 kg", Icons.monitor_weight),
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _progressBar(50, "Mon"),
                  _progressBar(80, "Tue"),
                  _progressBar(90, "Wed"),
                  _progressBar(70, "Thu"),
                  _progressBar(100, "Fri"),
                  _progressBar(60, "Sat"),
                  _progressBar(75, "Sun"),
                ],
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
                      builder: (_) => CalendarScreen(userId: widget.userId),
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
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(fontSize: 12),
        ),
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _workoutItem("Chest & Triceps", "Tomorrow, 9:00 AM"),
            _workoutItem("Leg Day", "Friday, 7:00 AM"),
            _workoutItem("Full Body", "Sunday, 10:00 AM"),
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
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}