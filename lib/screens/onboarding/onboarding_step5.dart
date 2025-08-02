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

  // Custom Snackbar method
  void _showCustomSnackBar(String message, bool isSuccess) {
    if (!mounted) return; // Guard against state changes if widget is disposed
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
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
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

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAllergies.isEmpty) {
      setState(() {
        _allergyError = true;
      });
      _showCustomSnackBar("Please select your allergies", false);
      return;
    } else {
      setState(() {
        _allergyError = false;
      });
    }

    setState(() => _isSubmitting = true);

    final url = Uri.parse("http://192.168.100.78/repEatApi/save_onboarding.php");

    final data = {
      "user_id": widget.userId.toString(), // Ensure it's a string
      "gender": widget.gender,
      "birthdate": widget.birthdate.toIso8601String().split('T')[0],
      "height": widget.height,
      "body_type": widget.bodyType,
      "current_weight": widget.currentWeight,
      "target_weight": widget.targetWeight,
      "goal": widget.goal,
      "preferred_sets": widget.sets,
      "preferred_reps": widget.reps,
      "has_injury": widget.hasInjury ? "1" : "0", // Send as string
      "injury_details": widget.hasInjury ? widget.injuryDetails : "None",
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

      if (response.statusCode == 200 && result['success'] == true) { // Check for bool
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_onboarded', true);

        _showCustomSnackBar('Setup completed successfully!', true);
        // Add a small delay to show the success message
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => MainNavScreen(userId: widget.userId),
              ),
                  (_) => false,
            );
          }
        });
      } else {
        _showCustomSnackBar(result['message'] ?? 'Failed to save onboarding data', false);
      }
    } catch (e) {
      _showCustomSnackBar('Network error. Please try again.', false);
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
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade900,
          ),
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
                      activeColor: Colors.deepPurple,
                      checkColor: Colors.white,
                      onChanged: (val) {
                        setState(() {
                          if (allergy == "None" && val == true) {
                            tempSelection.clear();
                            tempSelection.add("None");
                          } else {
                            tempSelection.remove("None");
                            if (val == true) {
                              tempSelection.add(allergy);
                            } else {
                              tempSelection.remove(allergy);
                            }
                          }
                        });
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
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.deepPurple.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedAllergies = tempSelection;
                  // If "None" is selected or nothing is selected, clear the set and add "None"
                  if (tempSelection.contains("None") || tempSelection.isEmpty) {
                    _selectedAllergies = {"None"};
                  }
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String getAllergyDisplay() {
    if (_selectedAllergies.isEmpty || (_selectedAllergies.length == 1 && _selectedAllergies.contains("None"))) {
      return "Select Allergies";
    }
    return _selectedAllergies.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50, // Softer background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Diet & Allergies"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white, // Explicitly set app bar text/icon color
        elevation: 0, // Remove shadow for a flatter look
      ),
      body: SafeArea( // Wrap content in SafeArea
        child: SingleChildScrollView( // Allow scrolling if needed
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant, // Changed icon to food related
                      size: 50,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                Text(
                  "Dietary Preferences",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  "Tell us about your dietary needs",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                // Diet Preference Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Diet Preference',
                    labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.deepPurple.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
                    ),
                    prefixIcon: Icon(
                      Icons.fastfood, // Icon for diet
                      color: Colors.deepPurple.shade700,
                    ),
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

                // Allergies Selector
                GestureDetector(
                  onTap: _showAllergySelector,
                  child: AbsorbPointer( // Prevents keyboard focus
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Allergies",
                        labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.deepPurple.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
                        ),
                        prefixIcon: Icon(
                          Icons.warning_amber_outlined, // Icon for allergies
                          color: Colors.deepPurple.shade700,
                        ),
                        errorText: _allergyError ? "Please select allergies" : null,
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      child: Text(
                        getAllergyDisplay(),
                        style: TextStyle(
                          color: _selectedAllergies.isEmpty || getAllergyDisplay() == "Select Allergies"
                              ? Colors.grey.shade600
                              : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40), // Space before button

                // Complete Setup Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Complete Setup",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}