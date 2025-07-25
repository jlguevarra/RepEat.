import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MealPlanScreen extends StatefulWidget {
  final int userId;

  const MealPlanScreen({super.key, required this.userId});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final url = Uri.parse(
        'http://192.168.100.78/repEatApi/get_profile.php?user_id=${widget.userId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          setState(() {
            userData = jsonData['data'];
            isLoading = false;
            isLoading = false;
          });
        } else {
          showError("No data found.");
        }
      } else {
        showError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      showError("Connection failed: $e");
    }
  }

  void showError(String msg) {
    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meal Plan"),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text("No user data found"))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Diet: ${userData!['diet_preference']}"),
            Text("Goal: ${userData!['goal']}"),
            Text("Allergies: ${userData!['allergies']}"),
            Text("Injury: ${userData!['injury_details']}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Generate AI meal plan
              },
              child: const Text("Generate AI Meal Plan"),
            ),
          ],
        ),
      ),
    );
  }
}
