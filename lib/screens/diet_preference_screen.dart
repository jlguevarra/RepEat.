import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:collection/collection.dart'; // Required for SetEquality

class DietPreferenceScreen extends StatefulWidget {
  const DietPreferenceScreen({super.key});

  @override
  State<DietPreferenceScreen> createState() => _DietPreferenceScreenState();
}

class _DietPreferenceScreenState extends State<DietPreferenceScreen> {
  String selectedDiet = 'None';
  String originalDiet = 'None';
  Set<String> selectedAllergies = {};
  Set<String> originalAllergies = {};
  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;
  int? userId;

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

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

  Future<bool> _onWillPop() async {
    if (!isEditing || !_hasChanges()) return true;
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');
    if (userId == null) {
      _showCustomSnackBar('User ID not found. Please log in again.', false); // Updated SnackBar
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.78/repEatApi/get_profile.php?user_id=$userId'),
      );
      final data = json.decode(response.body);

      if (data['success'] == true) {
        final profile = data['data'];
        final String diet = profile['diet_preference'] ?? 'None';
        final String allergiesRaw = profile['allergies'] ?? '';
        final Set<String> allergiesSet = allergiesRaw.isNotEmpty && allergiesRaw != "None"
            ? Set<String>.from(
            allergiesRaw.split(',').map((e) => e.trim()).where((e) => allergyOptions.contains(e)))
            : {};

        if (mounted) { // Check if mounted before setState
          setState(() {
            selectedDiet = dietOptions.contains(diet) ? diet : 'None';
            originalDiet = selectedDiet;
            selectedAllergies = Set.from(allergiesSet);
            originalAllergies = Set.from(allergiesSet);
            isLoading = false;
          });
        }
      } else {
        _showCustomSnackBar(data['message'] ?? 'Failed to load profile.', false); // Updated SnackBar
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      _showCustomSnackBar('Error loading profile: $e', false); // Updated SnackBar
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _hasChanges() {
    // Use SetEquality for proper set comparison
    return selectedDiet != originalDiet || !const SetEquality().equals(selectedAllergies, originalAllergies);
  }

  Future<void> _saveProfile() async {
    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.78/repEatApi/update_diet_allergies.php'),
        body: {
          'user_id': userId.toString(),
          'diet_preference': selectedDiet,
          'allergies': selectedAllergies.isEmpty ? 'None' : selectedAllergies.join(', '),
        },
      );

      final result = json.decode(response.body);
      if (result['success'] == true) {
        if (mounted) { // Check if mounted before setState
          setState(() {
            isEditing = false;
            originalDiet = selectedDiet;
            originalAllergies = Set.from(selectedAllergies); // Update original after save
          });
        }
        _showCustomSnackBar(result['message'] ?? 'Preferences updated.', true); // Updated SnackBar
      } else {
        _showCustomSnackBar(result['message'] ?? 'Failed to update preferences.', false); // Updated SnackBar
      }
    } catch (e) {
      _showCustomSnackBar('Network error. Please try again.', false); // Updated SnackBar
    } finally {
      if (mounted) { // Check if mounted before setState
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _cancelEditing() async {
    if (!_hasChanges()) {
      setState(() {
        isEditing = false;
      });
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Changes?'),
        content: const Text('Any unsaved changes will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        selectedDiet = originalDiet;
        selectedAllergies = Set.from(originalAllergies);
        isEditing = false;
      });
    }
  }

  // FIXED: Save button activation logic for allergies
  void _showAllergySelector() {
    if (!isEditing) return; // Only allow selection in edit mode

    // Create a copy of the current selection to use inside the dialog
    Set<String> tempSelection = {...selectedAllergies};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text("Select Allergies"),
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade900,
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: allergyOptions.map((allergy) {
                    bool selected = tempSelection.contains(allergy);
                    return CheckboxListTile(
                      title: Text(allergy),
                      value: selected,
                      activeColor: Colors.deepPurple,
                      checkColor: Colors.white,
                      onChanged: isEditing
                          ? (val) {
                        dialogSetState(() {
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
                        // KEY FIX: Update the main state immediately and trigger rebuild
                        // This ensures _hasChanges() works correctly for the save button
                        if (mounted) {
                          setState(() {
                            selectedAllergies = Set.from(tempSelection);
                          });
                        }
                      }
                          : null, // Disable if not editing
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // If cancelled, restore the original selection
                    if (mounted) {
                      setState(() {
                        selectedAllergies = Set.from(originalAllergies);
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.deepPurple.shade700),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update the main state with the final selection (already mostly done on change)
                    // Just close the dialog
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

  String _getAllergyDisplay() {
    if (selectedAllergies.isEmpty ||
        (selectedAllergies.length == 1 && selectedAllergies.contains("None"))) {
      return "No allergies selected";
    }
    return selectedAllergies.join(", ");
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
                'Loading Diet Preferences...',
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
          title: const Text('Diet & Allergies'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: _cancelEditing,
                tooltip: 'Cancel',
              )
            else
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    isEditing = true;
                  });
                },
                tooltip: 'Edit',
              ),
          ],
        ),
        body: SafeArea( // Improved Design
          child: SingleChildScrollView( // Improved Design
            padding: const EdgeInsets.all(16), // Improved Design
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Improved Design
              children: [
                // Header Section - Improved Design
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: 40,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dietary Preferences',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your dietary needs and restrictions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),

                // Diet Preference Section - Improved Design (Card)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fastfood_outlined,
                              color: Colors.deepPurple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Diet Preference',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        isEditing
                            ? DropdownButtonFormField<String>(
                          value: selectedDiet,
                          items: dietOptions.map((diet) {
                            return DropdownMenuItem(
                              value: diet,
                              child: Text(diet),
                            );
                          }).toList(),
                          onChanged: isEditing
                              ? (val) {
                            if (val != null) setState(() => selectedDiet = val);
                          }
                              : null, // Disable if not editing
                          decoration: _inputDecoration(), // Improved Design
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Please select a diet' : null,
                        )
                            : Text(
                          selectedDiet,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Allergies Section - Improved Design (Card)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_outlined,
                              color: Colors.deepPurple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Allergies',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: isEditing ? _showAllergySelector : null,
                          child: AbsorbPointer( // Prevents keyboard focus - Improved Design
                            child: InputDecorator(
                              decoration: _inputDecoration().copyWith( // Improved Design
                                hintText: isEditing ? 'Select allergies' : null,
                                enabled: isEditing,
                              ),
                              child: Text(
                                _getAllergyDisplay(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: selectedAllergies.isEmpty ||
                                      _getAllergyDisplay() == "No allergies selected"
                                      ? (isEditing ? Colors.grey.shade600 : Colors.grey.shade500)
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Save Button (only visible when editing) - Improved Design
                if (isEditing)
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (!_hasChanges() || isSaving) ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isSaving
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

  // Improved Input Decoration - Better Design Consistency
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
}