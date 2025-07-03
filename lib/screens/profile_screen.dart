import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final currentWeightController = TextEditingController();
  final targetWeightController = TextEditingController();
  final setsController = TextEditingController();
  final repsController = TextEditingController();
  final injuryController = TextEditingController();

  String selectedGoal = 'Muscle Gain';
  bool hasInjury = false;
  bool isEditing = false;
  bool isLoading = true;
  bool isSaving = false;

  final goals = ['Muscle Gain', 'Weight Loss', 'Endurance', 'General Fitness'];

  int? userId;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user ID found. Please log in again.')),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    try {
      final response = await http.get(Uri.parse(
          'http://192.168.100.79/repEatApi/get_profile.php?user_id=$userId'));
      final data = json.decode(response.body);

      if (data['success'] == true) {
        final profile = data['data'];
        nameController.text = profile['name'] ?? '';
        currentWeightController.text = profile['current_weight'] ?? '';
        targetWeightController.text = profile['target_weight'] ?? '';
        setsController.text = profile['preferred_sets'] ?? '';
        repsController.text = profile['preferred_reps'] ?? '';
        selectedGoal = profile['goal'] ?? 'Muscle Gain';
        hasInjury = profile['has_injury'] == '1';
        injuryController.text = profile['injury_details'] ?? '';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to load profile.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.79/repEatApi/update_profile.php'),
        body: {
          'user_id': userId.toString(),
          'name': nameController.text.trim(),
          'current_weight': currentWeightController.text.trim(),
          'target_weight': targetWeightController.text.trim(),
          'goal': selectedGoal,
          'sets': setsController.text.trim(),
          'reps': repsController.text.trim(),
          'has_injury': hasInjury ? '1' : '0',
          'injury_details': hasInjury ? injuryController.text.trim() : '',
        },
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        setState(() => isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Profile updated.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to update profile.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit),
            tooltip: isEditing ? 'Cancel' : 'Edit',
            onPressed: () => setState(() => isEditing = !isEditing),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Personal Information'),
            _textInput('Full Name', nameController, isEditing),
            const SizedBox(height: 20),

            _sectionTitle('Body Stats'),
            _textInput('Current Weight (lbs)', currentWeightController, isEditing),
            const SizedBox(height: 14),
            _textInput('Target Weight (lbs)', targetWeightController, isEditing),
            const SizedBox(height: 20),

            _sectionTitle('Fitness Goal'),
            AbsorbPointer(
              absorbing: !isEditing,
              child: DropdownButtonFormField<String>(
                value: selectedGoal,
                items: goals.map((goal) => DropdownMenuItem(
                  value: goal,
                  child: Text(goal),
                )).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedGoal = value);
                },
                decoration: _inputDecoration(),
              ),
            ),
            const SizedBox(height: 20),

            _sectionTitle('Workout Preferences'),
            Row(
              children: [
                Expanded(child: _textInput('Sets', setsController, isEditing)),
                const SizedBox(width: 16),
                Expanded(child: _textInput('Reps per Set', repsController, isEditing)),
              ],
            ),
            const SizedBox(height: 20),

            _sectionTitle('Declaration of Injury'),
            SwitchListTile(
              title: const Text('Do you have an injury?'),
              value: hasInjury,
              activeColor: Colors.deepPurple,
              onChanged: isEditing ? (val) => setState(() => hasInjury = val) : null,
            ),
            if (hasInjury)
              _textInput('Injury Details', injuryController, isEditing),

            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: isEditing && !isSaving ? _saveProfile : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    child: isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Save Profile'),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _textInput(String label, TextEditingController controller, bool enabled) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: _inputDecoration(label: label),
    );
  }

  InputDecoration _inputDecoration({String? label}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.deepPurple),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.deepPurple),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
    );
  }
}
