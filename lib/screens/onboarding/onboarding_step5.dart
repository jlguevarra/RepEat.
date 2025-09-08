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
      if (goalLC == 'weight loss') {
        _filteredDietOptions.remove('High Protein');
      } else if (goalLC == 'muscle gain') {
        _filteredDietOptions.remove('Low Carb');
      }

      // If the currently selected diet is no longer valid, clear it
      if (_dietPreference != null && !_filteredDietOptions.contains(_dietPreference)) {
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
          // (This case is handled by the logic in _showAllergySelector/_evaluateAutoAllergies when selecting)
        }
        // If Milk is already selected (alone or with others), do nothing special.
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
        // If Milk was selected by the user (not auto-added), leave it.
        // If "None" is selected, leave it.
        // If other items are selected, leave them.
        _noneAutoDisabled = false; // Enable "None" when Dairy Free is deselected
        _allergyError = false; // Clear error state
      }
    });
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    // Handle allergy validation:
    // Scenario 1: User explicitly selected "None" -> Valid (shows "No Allergies")
    // Scenario 2: User selected specific allergies -> Valid
    // Scenario 3: User selected "None" AND other allergies -> Invalid
    // Scenario 4: User selected nothing (initial state {}) -> Invalid (Prompt to select)

    bool isValidSelection = true;
    String errorMessage = "";

    // Check if user made any selections
    if (_selectedAllergies.isEmpty) {
      // Scenario 4: Nothing selected (initial prompt state)
      isValidSelection = false;
      errorMessage = "Please select 'None' if you have no allergies, or select specific allergies.";
    } else if (_selectedAllergies.contains("None")) {
      if (_selectedAllergies.length > 1) {
        // Scenario 3: "None" mixed with others
        isValidSelection = false;
        errorMessage = "Cannot select 'None' with other allergies.";
      } else {
        // Scenario 1: Only "None" selected -> Valid (do nothing)
        // Display will be "No Allergies"
      }
    } else {
      if (_selectedAllergies.isEmpty) {
        // Edge case: somehow got to empty set without "None"
        isValidSelection = false;
        errorMessage = "Please select 'None' if you have no allergies, or select specific allergies.";
      } else {
        // Scenario 2: Specific allergies selected -> Valid (do nothing)
        // Display will be the list of allergies
      }
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

    final url = Uri.parse("http://192.168.100.78/repEatApi/save_onboarding.php"); // Ensure IP is correct

    // Prepare data, handling "None" case correctly for submission
    String allergiesToSend;
    // Check if it's effectively "None" (empty or contains only "None")
    if (_selectedAllergies.isEmpty || (_selectedAllergies.length == 1 && _selectedAllergies.contains("None"))) {
      allergiesToSend = "None";
    } else {
      // Remove "None" from the set before joining, just in case it's mixed (though validation should prevent this)
      Set<String> cleanedAllergies = Set.from(_selectedAllergies)..remove("None");
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
      "diet_preference": _dietPreference ?? "None", // Send "None" if nothing selected
      "allergies": allergiesToSend, // Send processed allergies
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
        // Use a temporary set for selections within the dialog
        // Initialize with the current main state selections
        Set<String> tempSelection = Set.from(_selectedAllergies);
        // Determine if "Milk" should be locked and if "None" should be disabled
        final bool isMilkLocked = _dietPreference == "Dairy Free";
        final bool isNoneDisabled = _dietPreference == "Dairy Free"; // Disable "None" when Dairy Free is selected

        return StatefulBuilder(
          builder: (context, dialogStateSetter) { // State setter for the dialog
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
                  // Nested StatefulBuilder for dialog content state
                  builder: (context, contentStateSetter) {
                    return ListView(
                      shrinkWrap: true,
                      children: allergyOptions.map((allergy) {
                        bool isSelected = tempSelection.contains(allergy);
                        bool isDisabled = (allergy == "Milk" && isMilkLocked) ||
                            (allergy == "None" && isNoneDisabled);
                        return IgnorePointer(
                          ignoring: isDisabled, // Disable interaction if locked or disabled
                          child: Opacity(
                            opacity: isDisabled ? 0.6 : 1.0, // Visually indicate it's locked/disabled
                            child: CheckboxListTile(
                              title: Row(
                                children: [
                                  Text(allergy),
                                  if (isDisabled) // Visually indicate it's locked/disabled
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.lock, size: 16, color: Colors.grey),
                                    ),
                                ],
                              ),
                              value: isSelected,
                              activeColor: Colors.deepPurple,
                              checkColor: Colors.white,
                              onChanged: (val) {
                                contentStateSetter(() { // Update state within dialog content
                                  if (val == true) {
                                    if (allergy == "None") {
                                      // Selecting "None" clears all other selections
                                      tempSelection.clear();
                                      tempSelection.add("None");
                                      // If user explicitly selects "None", it wasn't auto-added
                                      _milkAutoAdded = false; // Reset milk flag
                                      _noneAutoDisabled = false; // Reset none disabled flag
                                    } else {
                                      // Selecting a specific allergy
                                      tempSelection.remove("None"); // Remove "None"
                                      tempSelection.add(allergy);   // Add the allergy
                                      // If user explicitly selects Milk, update flag
                                      if (allergy == "Milk") {
                                        _milkAutoAdded = false; // User selected it
                                      }
                                    }
                                  } else {
                                    // Deselecting an item (only if not locked/disabled)
                                    if (!isDisabled) {
                                      tempSelection.remove(allergy);
                                      // Do not automatically add "None" here.
                                      // Let the final "OK" logic or validation handle empty states if needed.
                                      // If user explicitly deselects Milk, update flag
                                      if (allergy == "Milk") {
                                        _milkAutoAdded = false; // User deselected it
                                      }
                                    }
                                  }
                                });
                              },
                              // Make the tile visually distinct when locked/disabled
                              tileColor: isDisabled ? Colors.grey.shade100 : null,
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
                    // When OK is pressed, commit the temp selection to main state
                    setState(() {
                      _selectedAllergies = Set.from(tempSelection);
                      _milkAutoAdded = tempSelection.contains("Milk") && _dietPreference == "Dairy Free"; // Update flag correctly
                      _noneAutoDisabled = _dietPreference == "Dairy Free"; // Update flag correctly

                      // Finalize selection logic upon closing dialog:
                      // If absolutely nothing is selected, leave it empty {}
                      // This preserves the initial prompt state if user cancels all selections.
                      // DO NOT set to {"None"} here.
                      // The validation on submit will handle the empty state.
                      if (_selectedAllergies.isEmpty) {
                        // Keep it empty {}
                        // Also reset the auto-added flags as there are no selections
                        _milkAutoAdded = false; // Reset flag
                        _noneAutoDisabled = false; // Reset flag
                      }
                      // If "None" is explicitly in the selection (and passed validation in dialog),
                      // or other items are selected, keep them as is.
                      // Clear the error state as selections are committed (validation happens on submit)
                      _allergyError = false;
                    });
                    Navigator.pop(context); // Close the dialog
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

  /// Formats the display text for the allergies input field.
  String getAllergyDisplay() {
    // Check for initial prompt state (empty set)
    if (_selectedAllergies.isEmpty) {
      return "Select Allergies"; // Prompt text
    }
    // Check for "None" selection
    else if (_selectedAllergies.length == 1 && _selectedAllergies.contains("None")) {
      return "No Allergies"; // Confirmed "None" selection
    }
    // Join multiple selections
    else {
      return _selectedAllergies.join(", ");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) { // Use the correct variable
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
        backgroundColor: Colors.deepPurple.shade50, // Softer background - Improved Design
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
                crossAxisAlignment: CrossAxisAlignment.start, // Improved Design
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
                        Icons.restaurant,
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

                  // Goal Display (Informational)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.goal.toLowerCase() == 'muscle gain'
                              ? Icons.fitness_center
                              : (widget.goal.toLowerCase() == 'weight loss'
                              ? Icons.monitor_weight_outlined
                              : Icons.restaurant_menu),
                          color: Colors.deepPurple.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Goal: ${widget.goal}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.filter_alt_outlined,
                          color: Colors.deepPurple.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(filtered)',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

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
                        borderSide: BorderSide(color: Colors.deepPurple.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
                      ),
                      prefixIcon: Icon(
                        Icons.fastfood,
                        color: Colors.deepPurple.shade700,
                      ),
                      suffixIcon: Icon(
                        Icons.info_outline,
                        color: Colors.deepPurple.shade700,
                        size: 18,
                      ),
                    ),
                    value: _dietPreference,
                    items: _filteredDietOptions.map(
                          (diet) => DropdownMenuItem(
                        value: diet,
                        child: Text(diet),
                      ),
                    ).toList(),
                    onChanged: (val) {
                      setState(() {
                        _dietPreference = val;
                        // 1, 2 & 3. Trigger auto-allergy evaluation when diet changes
                        _evaluateAutoAllergies();
                      });
                    },
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
                            Icons.warning_amber_outlined,
                            color: Colors.deepPurple.shade700,
                          ),
                          // Conditionally show error text
                          errorText: _allergyError ? "Please review your allergy selection" : null,
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
                          getAllergyDisplay(), // Use the formatted display text
                          style: TextStyle(
                            color: _selectedAllergies.isEmpty ||
                                getAllergyDisplay() == "Select Allergies"
                                ? Colors.grey.shade600 // Grey for placeholder/prompt
                                : (getAllergyDisplay() == "No Allergies"
                                ? Colors.grey.shade600 // Grey for "No Allergies"
                                : Colors.black87),      // Black for selections
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Save Button (only visible when editing)
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
    // Handle unsaved changes logic here if needed
    // For now, just allow popping
    return true;
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
    );
  }

  @override
  void dispose() {
    // Remove listeners and dispose controllers if needed
    super.dispose();
  }
}