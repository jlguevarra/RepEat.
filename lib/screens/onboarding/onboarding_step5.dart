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
    required this.hasInjury,
    required this.injuryDetails,
  });

  @override
  State<OnboardingStep5> createState() => _OnboardingStep5State();
}

class _OnboardingStep5State extends State<OnboardingStep5> {
  final _formKey = GlobalKey<FormState>();
  String? _dietPreference;
  Set<String> _selectedAllergies = {}; // Start with an empty set to show prompt

  bool _isSubmitting = false;
  bool _allergyError = false; // Tracks if an error message should be shown
  bool _isLoading = true; // Moved to correct location

  // Updated base diet options
  final List<String> _baseDietOptions = [
    "High Protein",
    "Low Carb",
    "Low Fat",
    "Low Sodium",
    "Dairy Free",
  ];
  late List<String> _filteredDietOptions; // Will hold filtered options

  // Allergy options including "None"
  final List<String> allergyOptions = [
    "None", // Explicit "None" option
    "Peanuts",
    "Tree Nuts",
    "Milk", // This will be locked/auto-managed if Dairy Free is selected
    "Eggs",
    "Wheat",
    "Soy",
    "Fish",
    "Shellfish",
  ];

  // Flag to track if Milk was auto-added due to Dairy Free
  bool _milkAutoAdded = false;
  // Flag to track if None was auto-disabled due to Dairy Free
  bool _noneAutoDisabled = false;

  // Custom Snackbar method - Improved Design
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

  @override
  void initState() {
    super.initState();
    // Filter diet options based on goal on init
    _filterDietOptions();
    _isLoading = false; // Set loading to false after initialization
  }

  // Method to filter diet options based on the goal
  void _filterDietOptions() {
    setState(() {
      _filteredDietOptions = List.from(_baseDietOptions);

      // Apply filtering based on goal
      final String goalLC = widget.goal.toLowerCase();
      if (goalLC.contains('weight loss')) {
        _filteredDietOptions.remove('High Protein');
      } else if (goalLC.contains('muscle gain')) {
        _filteredDietOptions.remove('Low Carb');
      }

      // If the currently selected diet is no longer valid, clear it
      if (_dietPreference != null &&
          !_filteredDietOptions.contains(_dietPreference)) {
        _dietPreference = null;
        // Re-evaluate allergies if diet preference is cleared
        _evaluateAutoAllergies();
      }

      // Safety check
      if (_filteredDietOptions.isEmpty) {
        _filteredDietOptions = List.from(_baseDietOptions);
      }
    });
  }

  // Method to handle auto-allergies like Dairy Free -> Milk (Locked/Auto-Manage)
  // And handle deselection when diet changes
  // Also disable "None" when Dairy Free is selected
  void _evaluateAutoAllergies() {
    setState(() {
      if (_dietPreference == "Dairy Free") {
        // If Dairy Free is selected, ensure "Milk" is included and "None" is disabled.
        if (!_selectedAllergies.contains("Milk")) {
          // If Milk is not already selected, add it automatically.
          _selectedAllergies.remove("None"); // Remove "None" if present
          _selectedAllergies.add("Milk");
          _milkAutoAdded = true; // Mark it as auto-added
        } else if (!_milkAutoAdded) {
          // If Milk was already selected but not marked as auto-added,
          // it means the user selected it themselves. Keep the flag as false.
        }
        _noneAutoDisabled = true; // Disable "None" when Dairy Free is selected
        _allergyError = false; // Clear error state when auto-changing
      } else {
        // If diet is changed from Dairy Free to something else
        if (_milkAutoAdded && _selectedAllergies.contains("Milk")) {
          // If Milk was auto-added, remove it now.
          _selectedAllergies.remove("Milk");
          _milkAutoAdded = false; // Reset the flag
          // If this leaves the set empty, add "None" back
          if (_selectedAllergies.isEmpty) {
            _selectedAllergies.add("None");
          }
        }
        _noneAutoDisabled = false; // Enable "None" when Dairy Free is deselected
        _allergyError = false; // Clear error state
      }
    });
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    // Handle allergy validation
    bool isValidSelection = true;
    String errorMessage = "";

    if (_selectedAllergies.isEmpty) {
      isValidSelection = false;
      errorMessage =
      "Please select 'None' if you have no allergies, or select specific allergies.";
    } else if (_selectedAllergies.contains("None") &&
        _selectedAllergies.length > 1) {
      isValidSelection = false;
      errorMessage = "Cannot select 'None' with other allergies.";
    }

    if (!isValidSelection) {
      setState(() {
        _allergyError = true;
      });
      _showCustomSnackBar(errorMessage, false);
      return;
    } else {
      setState(() {
        _allergyError = false;
      });
    }

    setState(() => _isSubmitting = true);

    final url =
    Uri.parse("https://repeatapp.site/repEatApi/save_onboarding.php");

    String allergiesToSend;
    if (_selectedAllergies.isEmpty ||
        (_selectedAllergies.length == 1 && _selectedAllergies.contains("None"))) {
      allergiesToSend = "None";
    } else {
      Set<String> cleanedAllergies = Set.from(_selectedAllergies)
        ..remove("None");
      allergiesToSend = cleanedAllergies.join(",");
    }

    final data = {
      "user_id": widget.userId.toString(),
      "gender": widget.gender,
      "birthdate": widget.birthdate.toIso8601String().split('T')[0],
      "height": widget.height,
      "body_type": widget.bodyType,
      "current_weight": widget.currentWeight,
      "target_weight": widget.targetWeight,
      "goal": widget.goal,
      "has_injury": widget.hasInjury ? "1" : "0",
      "injury_details": widget.hasInjury ? widget.injuryDetails : "None",
      "diet_preference": _dietPreference ?? "None",
      "allergies": allergiesToSend,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_onboarded', true);

        _showCustomSnackBar('Setup completed successfully!', true);
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
        _showCustomSnackBar(
            result['message'] ?? 'Failed to save onboarding data', false);
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
        Set<String> tempSelection = Set.from(_selectedAllergies);
        final bool isMilkLocked = _dietPreference == "Dairy Free";
        final bool isNoneDisabled = _dietPreference == "Dairy Free";

        return StatefulBuilder(
          builder: (context, dialogStateSetter) {
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
                  builder: (context, contentStateSetter) {
                    return ListView(
                      shrinkWrap: true,
                      children: allergyOptions.map((allergy) {
                        bool isSelected = tempSelection.contains(allergy);
                        bool isDisabled = (allergy == "Milk" && isMilkLocked) ||
                            (allergy == "None" && isNoneDisabled);
                        return IgnorePointer(
                          ignoring: isDisabled,
                          child: Opacity(
                            opacity: isDisabled ? 0.6 : 1.0,
                            child: CheckboxListTile(
                              title: Row(
                                children: [
                                  Text(allergy),
                                  if (isDisabled)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.lock,
                                          size: 16, color: Colors.grey),
                                    ),
                                ],
                              ),
                              value: isSelected,
                              activeColor: Colors.deepPurple,
                              checkColor: Colors.white,
                              onChanged: (val) {
                                contentStateSetter(() {
                                  if (val == true) {
                                    if (allergy == "None") {
                                      tempSelection.clear();
                                      tempSelection.add("None");
                                      _milkAutoAdded = false;
                                      _noneAutoDisabled = false;
                                    } else {
                                      tempSelection.remove("None");
                                      tempSelection.add(allergy);
                                      if (allergy == "Milk") {
                                        _milkAutoAdded = false;
                                      }
                                    }
                                  } else {
                                    if (!isDisabled) {
                                      tempSelection.remove(allergy);
                                      if (allergy == "Milk") {
                                        _milkAutoAdded = false;
                                      }
                                    }
                                  }
                                });
                              },
                              tileColor:
                              isDisabled ? Colors.grey.shade100 : null,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.deepPurple.shade700),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedAllergies = Set.from(tempSelection);
                      _milkAutoAdded = tempSelection.contains("Milk") &&
                          _dietPreference == "Dairy Free";
                      _noneAutoDisabled = _dietPreference == "Dairy Free";

                      if (_selectedAllergies.isEmpty) {
                        _milkAutoAdded = false;
                        _noneAutoDisabled = false;
                      }
                      _allergyError = false;
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
      },
    );
  }

  String getAllergyDisplay() {
    if (_selectedAllergies.isEmpty) {
      return "Select Allergies";
    } else if (_selectedAllergies.length == 1 &&
        _selectedAllergies.contains("None")) {
      return "No Allergies";
    } else {
      return _selectedAllergies.join(", ");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                'Loading Account Settings...',
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.deepPurple.shade50,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          // ✅ FIX: Added a TextStyle to make the title bold
          title: const Text(
            "Diet & Allergies",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.restaurant,
                        size: 50,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Dietary Preferences",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Tell us about your dietary needs",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Diet Preference Dropdown (Filtered)
                  DropdownButtonFormField<String?>(
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
                        borderSide:
                        BorderSide(color: Colors.deepPurple.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.deepPurple.shade700, width: 2),
                      ),
                      prefixIcon: Icon(
                        Icons.fastfood,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                    value: _dietPreference,
                    items: _filteredDietOptions
                        .map(
                          (diet) => DropdownMenuItem(
                        value: diet,
                        child: Text(diet),
                      ),
                    )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _dietPreference = val;
                        _evaluateAutoAllergies();
                      });
                    },
                    validator: (val) =>
                    val == null ? 'Please select a diet preference' : null,
                  ),
                  const SizedBox(height: 24),

                  // Allergies Selector
                  GestureDetector(
                    onTap: _showAllergySelector,
                    child: AbsorbPointer(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Allergies",
                          labelStyle:
                          TextStyle(color: Colors.deepPurple.shade700),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.shade700, width: 2),
                          ),
                          prefixIcon: Icon(
                            Icons.warning_amber_outlined,
                            color: Colors.deepPurple.shade700,
                          ),
                          errorText: _allergyError
                              ? "Please review your allergy selection"
                              : null,
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        child: Text(
                          getAllergyDisplay(),
                          style: TextStyle(
                            color: _selectedAllergies.isEmpty ||
                                getAllergyDisplay() == "Select Allergies"
                                ? Colors.grey.shade600
                                : (getAllergyDisplay() == "No Allergies"
                                ? Colors.grey.shade600
                                : Colors.black87),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Save Button
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
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
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
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return true;
  }

  @override
  void dispose() {
    super.dispose();
  }
}