import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/profile_screen.dart';

class MainNavScreen extends StatefulWidget {
  final int userId;

  const MainNavScreen({super.key, required this.userId});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(userId: widget.userId),
      WorkoutScreen(userId: widget.userId),
      MealPlanScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTap,
          selectedItemColor: Colors.deepPurple.shade700,
          unselectedItemColor: Colors.grey.shade600,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedIndex == 0
                      ? Colors.deepPurple.shade50
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.home_outlined,
                  color: _selectedIndex == 0
                      ? Colors.deepPurple.shade700
                      : Colors.grey.shade600,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple.shade50,
                ),
                child: Icon(
                  Icons.home,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedIndex == 1
                      ? Colors.deepPurple.shade50
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.fitness_center_outlined,
                  color: _selectedIndex == 1
                      ? Colors.deepPurple.shade700
                      : Colors.grey.shade600,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple.shade50,
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              label: 'Workout',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedIndex == 2
                      ? Colors.deepPurple.shade50
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.restaurant_menu_outlined,
                  color: _selectedIndex == 2
                      ? Colors.deepPurple.shade700
                      : Colors.grey.shade600,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple.shade50,
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              label: 'Meal Plan',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedIndex == 3
                      ? Colors.deepPurple.shade50
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: _selectedIndex == 3
                      ? Colors.deepPurple.shade700
                      : Colors.grey.shade600,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple.shade50,
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}