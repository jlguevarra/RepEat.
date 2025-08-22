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

  // Custom Snackbar method - Improved Design
  void _showCustomSnackBar(String message, bool isSuccess) {
    if (!mounted) return; // Guard against state changes if widget is disposed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error, // Icon based on result
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
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.red.shade700, // Color based on result
        behavior: SnackBarBehavior.floating, // Modern floating style
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        margin: const EdgeInsets.all(20), // Margin from screen edges
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Internal padding
        duration: const Duration(seconds: 3), // Display duration
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      // First try to get from API
      final response = await http.get(
        Uri.parse('http://192.168.100.78/repEatApi/get_profile.php?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final name = data['data']['name'] ?? 'User';

          // Update local cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', name);

          if (mounted) { // Check if mounted before setState
            setState(() {
              fullName = name;
              isLoading = false;
              isRefreshing = false;
              errorMessage = null;
            });
          }
          return;
        } else {
          // If API returns but with success=false
          final prefs = await SharedPreferences.getInstance();
          final cachedName = prefs.getString('user_name') ?? 'User';
          if (mounted) {
            setState(() {
              fullName = cachedName;
              isLoading = false;
              isRefreshing = false;
              errorMessage = 'Using cached data - ${data['message'] ?? 'API returned error'}';
            });
          }
          // Show snackbar for error using the new method
          _showCustomSnackBar(errorMessage!, false);
          return;
        }
      }

      // If API fails completely (network error or status code != 200)
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
      // Show snackbar for error using the new method
      _showCustomSnackBar(errorMessage!, false);

    } catch (e) {
      // Fall back to local cache if both API and cache fail
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
      // Show snackbar for error using the new method
      _showCustomSnackBar(errorMessage!, false);
    }
  }

  Future<void> _refreshData() async {
    if (mounted) { // Check if mounted before setState
      setState(() {
        isRefreshing = true;
        errorMessage = null;
      });
    }
    await _loadUserData();
    // REMOVED: The line that showed "Profile refreshed successfully!" snackbar
    // The refresh functionality itself (calling _loadUserData) is kept.
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
              foregroundColor: Colors.white, // Explicit text color
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
      // Show logout success snackbar using the new method
      _showCustomSnackBar('You have been logged out.', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.deepPurple, // Match app bar color
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
      backgroundColor: Colors.deepPurple.shade50, // Softer background - Improved Design
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white, // Explicit text/icon color
        elevation: 0, // Remove shadow for a flatter look - Improved Design
        actions: [
          if (errorMessage != null)
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.amber),
              onPressed: () {
                // Use the new snackbar method
                _showCustomSnackBar(errorMessage!, false);
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        backgroundColor: Colors.deepPurple, // Custom refresh indicator color - Improved Design
        color: Colors.white, // Custom refresh indicator color - Improved Design
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // Profile Header Card - Improved Design
            Card(
              elevation: 2, // Subtle shadow
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Rounded corners
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
                              color: Colors.deepPurple, // Consistent color
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

            // Profile Options Section Header - Improved Design
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

            // Profile Options - Improved Design using _buildProfileOption
            _buildProfileOption(
              context,
              icon: Icons.fitness_center,
              title: 'Fitness Goals',
              subtitle: 'Set and track your fitness objectives', // Added subtitle
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FitnessGoalsScreen()),
              ),
            ),
            _buildProfileOption(
              context,
              icon: Icons.restaurant_menu,
              title: 'Diet Preference',
              subtitle: 'Manage your dietary needs and restrictions', // Added subtitle
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DietPreferenceScreen()),
              ),
            ),
            _buildProfileOption(
              context,
              icon: Icons.straighten,
              title: 'Physical Stats',
              subtitle: 'Update your height, weight, and measurements', // Added subtitle
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhysicalStatsScreen()),
              ),
            ),
            _buildProfileOption(
              context,
              icon: Icons.settings,
              title: 'Account Settings',
              subtitle: 'Change password and full name', // Added subtitle
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                );
                await _refreshData(); // Refresh after account settings change
              },
            ),

            const SizedBox(height: 24),

            // Logout Button - Improved Design
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple),
                  padding: const EdgeInsets.symmetric(vertical: 16), // Increased padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16, // Larger text
                    fontWeight: FontWeight.w600, // Bolder text
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

  // Improved Profile Option Builder - Better Design Consistency
  Widget _buildProfileOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle, // Added optional subtitle
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 0, // Flat card
      margin: const EdgeInsets.symmetric(vertical: 6), // Vertical spacing
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Internal padding
        leading: Container( // Icon container for better visual
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50, // Background for icon
            shape: BoxShape.circle, // Circular background
          ),
          child: Icon(icon, color: Colors.deepPurple),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600, // Slightly bolder title
            fontSize: 16, // Larger title
          ),
        ),
        subtitle: subtitle != null // Show subtitle if provided
            ? Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13, // Smaller subtitle
          ),
        )
            : null,
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey, // Softer trailing icon color
        ),
        onTap: onTap,
      ),
    );
  }
}