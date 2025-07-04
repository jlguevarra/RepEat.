import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DietPreferenceScreen extends StatefulWidget {
  const DietPreferenceScreen({super.key});

  @override
  State<DietPreferenceScreen> createState() => _DietPreferenceScreenState();
}

class _DietPreferenceScreenState extends State<DietPreferenceScreen> {
  final dietController = TextEditingController();

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
        dietController.text = profile['diet_preference'] ?? '';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to load diet preference.')),
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
          'diet_preference': dietController.text.trim(),
        },
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Diet preference updated.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to update diet preference.')),
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
        title: const Text('Diet Preference'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diet Preference',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: dietController,
              decoration: _inputDecoration(hintText: 'e.g., Vegan, Low Carb, Mediterranean'),
            ),
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

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
