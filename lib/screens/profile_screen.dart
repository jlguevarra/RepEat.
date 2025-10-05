import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'fitness_goals_screen.dart';
import 'diet_preference_screen.dart';
import 'physical_stats_screen.dart';
import 'account_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String fullName = 'User';
  bool isLoading = true;
  bool isRefreshing = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _showCustomSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
        isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://repeatapp.site/repEatApi/get_profile.php?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final name = data['data']['name'] ?? 'User';

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', name);

          if (mounted) {
            setState(() {
              fullName = name;
              isLoading = false;
              isRefreshing = false;
              errorMessage = null;
            });
          }
          return;
        } else {
          final prefs = await SharedPreferences.getInstance();
          final cachedName = prefs.getString('user_name') ?? 'User';
          if (mounted) {
            setState(() {
              fullName = cachedName;
              isLoading = false;
              isRefreshing = false;
              errorMessage =
              'Using cached data - ${data['message'] ?? 'API returned error'}';
            });
          }
          _showCustomSnackBar(errorMessage!, false);
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('user_name') ?? 'User';
      if (mounted) {
        setState(() {
          fullName = cachedName;
          isLoading = false;
          isRefreshing = false;
          errorMessage = 'Using cached data - Network error';
        });
      }
      _showCustomSnackBar(errorMessage!, false);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('user_name') ?? 'User';
      if (mounted) {
        setState(() {
          fullName = cachedName;
          isLoading = false;
          isRefreshing = false;
          errorMessage = 'Using cached data - ${e.toString()}';
        });
      }
      _showCustomSnackBar(errorMessage!, false);
    }
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        isRefreshing = true;
        errorMessage = null;
      });
    }
    await _loadUserData();
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
      _showCustomSnackBar('You have been logged out.', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.deepPurple,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Loading Profile...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
              );
              await _refreshData();
            },
            tooltip: 'Settings',
          ),
          if (errorMessage != null)
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.amber),
              onPressed: () {
                _showCustomSnackBar(errorMessage!, false);
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        backgroundColor: Colors.deepPurple,
        color: Colors.white,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage your account and preferences',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'ACCOUNT SETTINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildProfileOption(
              context,
              icon: Icons.fitness_center,
              title: 'Fitness Goals',
              subtitle: 'Set and track your fitness objectives',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FitnessGoalsScreen()),
              ),
            ),
            _buildProfileOption(
              context,
              icon: Icons.restaurant_menu,
              title: 'Diet Preference',
              subtitle: 'Manage your dietary needs and restrictions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DietPreferenceScreen()),
              ),
            ),
            _buildProfileOption(
              context,
              icon: Icons.straighten,
              title: 'Physical Stats',
              subtitle: 'Update your height, weight, and measurements',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhysicalStatsScreen()),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.deepPurple),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
          ),
        )
            : null,
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
