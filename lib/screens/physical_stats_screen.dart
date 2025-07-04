import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PhysicalStatsScreen extends StatefulWidget {
  const PhysicalStatsScreen({super.key});

  @override
  State<PhysicalStatsScreen> createState() => _PhysicalStatsScreenState();
}

class _PhysicalStatsScreenState extends State<PhysicalStatsScreen> {
  final currentWeightController = TextEditingController();
  final targetWeightController = TextEditingController();
  final setsController = TextEditingController();
  final repsController = TextEditingController();
  final injuryController = TextEditingController();

  bool hasInjury = false;
  bool isLoading = true;
  bool isSaving = false;

  int? userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found. Please log in again.')),
      );
      Navigator.pop(context);
      return;
    }

    try {
      final response = await http.get(Uri.parse(
        'http://192.168.100.79/repEatApi/get_profile.php?user_id=$userId',
      ));
      final data = json.decode(response.body);

      if (data['success'] == true) {
        final profile = data['data'];
        currentWeightController.text = profile['current_weight'] ?? '';
        targetWeightController.text = profile['target_weight'] ?? '';
        setsController.text = profile['preferred_sets'] ?? '';
        repsController.text = profile['preferred_reps'] ?? '';
        hasInjury = profile['has_injury'] == '1';
        injuryController.text = profile['injury_details'] ?? '';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to load stats.')),
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

  Future<void> _saveData() async {
    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.79/repEatApi/update_profile.php'),
        body: {
          'user_id': userId.toString(),
          'current_weight': currentWeightController.text.trim(),
          'target_weight': targetWeightController.text.trim(),
          'sets': setsController.text.trim(),
          'reps': repsController.text.trim(),
          'has_injury': hasInjury ? '1' : '0',
          'injury_details': hasInjury ? injuryController.text.trim() : '',
        },
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Physical stats updated.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to update stats.')),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Physical Stats'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Body Measurements',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            _textInput('Current Weight (lbs)', currentWeightController),
            const SizedBox(height: 12),
            _textInput('Target Weight (lbs)', targetWeightController),
            const SizedBox(height: 20),

            const Text(
              'Workout Preferences',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _textInput('Sets', setsController)),
                const SizedBox(width: 12),
                Expanded(child: _textInput('Reps per Set', repsController)),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Injury Information',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            SwitchListTile(
              title: const Text('Do you have an injury?'),
              value: hasInjury,
              activeColor: Colors.deepPurple,
              onChanged: (val) => setState(() => hasInjury = val),
            ),
            if (hasInjury) _textInput('Injury Details', injuryController),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Save', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textInput(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
