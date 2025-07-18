import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../main_nav_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStep5 extends StatefulWidget {
  final int userId;
  final String gender;
  final DateTime birthdate;
  final String height;
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
    required this.height,
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
  Set<String> _selectedAllergies = {};

  bool _isSubmitting = false;
  bool _allergyError = false;

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

    if (_selectedAllergies.isEmpty) {
      setState(() {
        _allergyError = true;
      });
      return;
    } else {
      setState(() {
        _allergyError = false;
      });
    }

    setState(() => _isSubmitting = true);

    final url = Uri.parse("http://192.168.100.78/repEatApi/save_onboarding.php");

    final data = {
      "user_id": widget.userId,
      "gender": widget.gender,
      "birthdate": widget.birthdate.toIso8601String().split('T')[0],
      "height": widget.height,
      "body_type": widget.bodyType,
      "current_weight": widget.currentWeight,
      "target_weight": widget.targetWeight,
      "goal": widget.goal,
      "preferred_sets": widget.sets,
      "preferred_reps": widget.reps,
      "has_injury": widget.hasInjury ? 1 : 0,
      "injury_details": widget.hasInjury ? widget.injuryDetails : "None", // ✅ force "None" if no injury
      "diet_preference": _dietPreference ?? "",
      "allergies": _selectedAllergies.isEmpty ? "None" : _selectedAllergies.join(","),
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

  void _showAllergySelector() {
    showDialog(
      context: context,
      builder: (context) {
        Set<String> tempSelection = {..._selectedAllergies};

        return AlertDialog(
          title: const Text("Select Allergies"),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setState) {
                return ListView(
                  shrinkWrap: true,
                  children: allergyOptions.map((allergy) {
                    bool selected = tempSelection.contains(allergy);
                    return CheckboxListTile(
                      title: Text(allergy),
                      value: selected,
                      onChanged: (val) {
                        if (allergy == "None" && val == true) {
                          setState(() {
                            tempSelection.clear();
                            tempSelection.add("None");
                          });
                        } else {
                          setState(() {
                            tempSelection.remove("None");
                            if (val == true) {
                              tempSelection.add(allergy);
                            } else {
                              tempSelection.remove(allergy);
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedAllergies = tempSelection;
                });
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String getAllergyDisplay() {
    if (_selectedAllergies.isEmpty) return "Select Allergies";
    return _selectedAllergies.join(", ");
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

              GestureDetector(
                onTap: _showAllergySelector,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Allergies",
                    border: const OutlineInputBorder(),
                    errorText: _allergyError ? "Please select allergies" : null,
                  ),
                  child: Text(
                    getAllergyDisplay(),
                    style: TextStyle(
                      color: _selectedAllergies.isEmpty
                          ? Colors.grey.shade600
                          : Colors.black,
                    ),
                  ),
                ),
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
