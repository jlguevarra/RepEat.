import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../main_nav_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStep5 extends StatefulWidget {
  final int userId;
  final String gender;
  final DateTime birthdate;
  final String height; // ✅ added
  final String bodyType;
  final String currentWeight;
  final String targetWeight;
  final String goal;
  final String sets;
  final String reps;
  final bool hasInjury;
  final String injuryDetails;

  const OnboardingStep5({
    super.key,
    required this.userId,
    required this.gender,
    required this.birthdate,
    required this.height, // ✅ added
    required this.bodyType,
    required this.currentWeight,
    required this.targetWeight,
    required this.goal,
    required this.sets,
    required this.reps,
    required this.hasInjury,
    required this.injuryDetails,
  });

  @override
  State<OnboardingStep5> createState() => _OnboardingStep5State();
}

class _OnboardingStep5State extends State<OnboardingStep5> {
  final _formKey = GlobalKey<FormState>();
  String? _dietPreference;
  String? _allergy;

  bool _isSubmitting = false;

  final List<String> dietOptions = [
    "None",
    "Vegetarian",
    "Vegan",
    "Keto",
    "Paleo",
    "Mediterranean",
    "Low-Carb",
    "High-Protein",
  ];

  final List<String> allergyOptions = [
    "None",
    "Peanuts",
    "Tree Nuts",
    "Shellfish",
    "Fish",
    "Milk",
    "Eggs",
    "Wheat",
    "Soy",
    "Gluten",
  ];

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final url = Uri.parse("http://192.168.100.79/repEatApi/save_onboarding.php");

    final data = {
      "user_id": widget.userId,
      "gender": widget.gender,
      "birthdate": widget.birthdate.toIso8601String().split('T')[0],
      "height": widget.height, // ✅ added
      "body_type": widget.bodyType,
      "current_weight": widget.currentWeight,
      "target_weight": widget.targetWeight,
      "goal": widget.goal,
      "preferred_sets": widget.sets,
      "preferred_reps": widget.reps,
      "has_injury": widget.hasInjury ? 1 : 0,
      "injury_details": widget.injuryDetails,
      "diet_preference": _dietPreference ?? "",
      "allergies": _allergy ?? "",
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_onboarded', true);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavScreen(userId: widget.userId),
          ),
              (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to save onboarding data')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Diet & Allergies"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Diet Preference',
                  border: OutlineInputBorder(),
                ),
                value: _dietPreference,
                items: dietOptions.map(
                      (diet) => DropdownMenuItem(
                    value: diet,
                    child: Text(diet),
                  ),
                ).toList(),
                onChanged: (val) => setState(() => _dietPreference = val),
                validator: (val) => val == null ? 'Please select a diet preference' : null,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  border: OutlineInputBorder(),
                ),
                value: _allergy,
                items: allergyOptions.map(
                      (allergy) => DropdownMenuItem(
                    value: allergy,
                    child: Text(allergy),
                  ),
                ).toList(),
                onChanged: (val) => setState(() => _allergy = val),
                validator: (val) => val == null ? 'Please select an allergy (or None)' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Complete Setup"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
