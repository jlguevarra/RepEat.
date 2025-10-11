import 'dart:async'; // --- 1. ADD THIS IMPORT ---
import 'dart:io';   // --- 2. ADD THIS IMPORT ---
import 'package:flutter/foundation.dart';
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
  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;

  int? userId;
  double currentWeight = 0;
  double targetWeight = 0;

  String selectedDiet = 'None';
  String originalDiet = 'None';

  Set<String> selectedAllergies = {};
  Set<String> originalAllergies = {};

  final List<String> _baseDietOptions = [
    "High Protein",
    "Low Carb",
    "Low Fat",
    "Low Sodium",
    "Dairy Free",
  ];

  List<String> _filteredDietOptions = [];

  final List<String> allergyOptions = [
    "None",
    "Peanuts",
    "Tree Nuts",
    "Milk",
    "Eggs",
    "Wheat",
    "Soy",
    "Fish",
    "Shellfish",
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _showCustomSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Leave')),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  // --- 3. ADD THIS HELPER FUNCTION ---
  void _handleLoadError() {
    // Fallback to cached weights to determine diet options
    _updateFilteredDietOptions('None');
    if (mounted) {
      setState(() {
        // Set to sensible defaults
        selectedDiet = 'None';
        originalDiet = 'None';
        selectedAllergies = {};
        originalAllergies = {};
      });
    }
  }

  // --- 4. REFINED THIS ENTIRE FUNCTION ---
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    currentWeight = double.tryParse(prefs.getString('current_weight') ?? '') ?? 0;
    targetWeight = double.tryParse(prefs.getString('target_weight') ?? '') ?? 0;

    if (userId == null) {
      _showCustomSnackBar('User ID not found. Please log in again.', false);
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      final response = await http.get(Uri.parse('https://repeatapp.site/repEatApi/get_profile.php?user_id=$userId'))
          .timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (data['success'] == true) {
        final profile = data['data'];
        final String diet = profile['diet_preference'] ?? 'None';
        final String allergiesRaw = profile['allergies'] ?? '';

        final profileCurrentWeight = double.tryParse(profile['current_weight'] ?? '') ?? 0;
        final profileTargetWeight = double.tryParse(profile['target_weight'] ?? '') ?? 0;

        if (profileCurrentWeight > 0) currentWeight = profileCurrentWeight;
        if (profileTargetWeight > 0) targetWeight = profileTargetWeight;

        final Set<String> allergiesSet = allergiesRaw.isNotEmpty && allergiesRaw != "None"
            ? Set<String>.from(allergiesRaw.split(',').map((e) => e.trim()).where((e) => allergyOptions.contains(e)))
            : {};

        _updateFilteredDietOptions(diet);

        if (mounted) {
          setState(() {
            selectedDiet = _filteredDietOptions.contains(diet) ? diet : 'None';
            originalDiet = selectedDiet;
            selectedAllergies = Set.from(allergiesSet);
            originalAllergies = Set.from(allergiesSet);
          });
        }
      } else {
        _showCustomSnackBar(data['message'] ?? 'Failed to load profile.', false);
        _handleLoadError();
      }
    } on TimeoutException catch (_) {
      _showCustomSnackBar('The server took too long to respond.', false);
      _handleLoadError();
    } on SocketException catch (_) {
      _showCustomSnackBar('No Internet connection. Please check your network.', false);
      _handleLoadError();
    } catch (e) {
      _showCustomSnackBar('An unexpected error occurred.', false);
      _handleLoadError();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _updateFilteredDietOptions(String currentDiet) {
    String goal = 'General Fitness';
    if (targetWeight > currentWeight) {
      goal = 'Muscle Gain';
    } else if (targetWeight < currentWeight) {
      goal = 'Weight Loss';
    }

    if (goal == 'Weight Loss') {
      _filteredDietOptions = _baseDietOptions.where((diet) => diet != 'High Protein').toList();
    } else if (goal == 'Muscle Gain') {
      _filteredDietOptions = _baseDietOptions.where((diet) => diet != 'Low Carb').toList();
    } else {
      _filteredDietOptions = List.from(_baseDietOptions);
    }
  }

  bool _hasChanges() {
    return selectedDiet != originalDiet || !setEquals(selectedAllergies, originalAllergies);
  }

  // --- 5. REFINED THIS ENTIRE FUNCTION ---
  Future<void> _saveProfile() async {
    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('https://repeatapp.site/repEatApi/update_diet_allergies.php'),
        body: {
          'user_id': userId.toString(),
          'diet_preference': selectedDiet,
          'allergies': selectedAllergies.isEmpty ? 'None' : selectedAllergies.join(', '),
        },
      ).timeout(const Duration(seconds: 10));

      final result = json.decode(response.body);

      if (result['success'] == true) {
        if (mounted) {
          setState(() {
            isEditing = false;
            originalDiet = selectedDiet;
            originalAllergies = Set.from(selectedAllergies);
          });
        }
        _showCustomSnackBar(result['message'] ?? 'Preferences updated.', true);
      } else {
        _showCustomSnackBar(result['message'] ?? 'Failed to update preferences.', false);
      }
    } on TimeoutException catch (_) {
      _showCustomSnackBar('The server took too long to respond.', false);
    } on SocketException catch (_) {
      _showCustomSnackBar('No Internet connection. Please check your network.', false);
    } catch (e) {
      _showCustomSnackBar('An unexpected error occurred while saving.', false);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _cancelEditing() async {
    if (!_hasChanges()) {
      setState(() => isEditing = false);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Changes?'),
        content: const Text('Any unsaved changes will be lost. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.deepPurple,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              SizedBox(height: 16),
              Text('Loading Diet Preferences...', style: TextStyle(color: Colors.white70, fontSize: 16)),
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
          // --- MODIFICATION START ---
          title: const Text(
            'Diet & Allergies',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          // --- MODIFICATION END ---
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
              IconButton(icon: const Icon(Icons.cancel), tooltip: 'Cancel', onPressed: _cancelEditing)
            else
              IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => isEditing = true), tooltip: 'Edit'),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.deepPurple.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.restaurant, size: 40, color: Colors.deepPurple.shade800),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Dietary Preferences', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 8),
                const Text('Manage your dietary needs and restrictions', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 30),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.fastfood_outlined, color: Colors.deepPurple.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text('Diet Preference', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
                      ]),
                      const SizedBox(height: 12),
                      isEditing
                          ? DropdownButtonFormField<String>(
                        value: selectedDiet,
                        items: _filteredDietOptions.map((diet) {
                          return DropdownMenuItem(value: diet, child: Text(diet));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedDiet = val;

                              if (val == 'Dairy Free') {
                                if (selectedAllergies.contains('None')) selectedAllergies.remove('None');
                                selectedAllergies.add('Milk');
                              } else {
                                selectedAllergies.remove('Milk');
                              }
                            });
                          }
                        },
                        decoration: _inputDecoration(),
                      )
                          : Text(selectedDiet, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.warning_amber_outlined, color: Colors.deepPurple.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text('Allergies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
                      ]),
                      const SizedBox(height: 12),
                      if (isEditing) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: allergyOptions.map((allergy) {
                            final isSelected = selectedAllergies.contains(allergy);
                            final isDisabled = selectedDiet == 'Dairy Free' && allergy == 'Milk';

                            return FilterChip(
                              label: Text(allergy),
                              selected: isSelected,
                              onSelected: isDisabled
                                  ? null
                                  : (selected) {
                                setState(() {
                                  if (selected) {
                                    if (selectedDiet == 'Dairy Free' && allergy == 'None') {
                                      _showCustomSnackBar('Cannot select None when Dairy Free diet is chosen.', false);
                                      return;
                                    }

                                    if (allergy == 'None') {
                                      selectedAllergies.clear();
                                      selectedAllergies.add('None');
                                    } else {
                                      selectedAllergies.remove('None');
                                      selectedAllergies.add(allergy);
                                    }
                                  } else {
                                    selectedAllergies.remove(allergy);
                                  }
                                });
                              },
                              selectedColor: Colors.deepPurple.shade100,
                              checkmarkColor: Colors.deepPurple,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.deepPurple.shade800 : Colors.grey.shade700,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              backgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: isSelected ? Colors.deepPurple.shade300 : Colors.grey.shade300, width: 1),
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        Text(
                          selectedAllergies.isEmpty ||
                              (selectedAllergies.length == 1 && selectedAllergies.contains('None'))
                              ? "No allergies selected"
                              : selectedAllergies.join(', '),
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ]),
                  ),
                ),

                const SizedBox(height: 30),

                if (isEditing)
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _hasChanges() && !isSaving ? _saveProfile : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: isSaving
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.deepPurple.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2)),
    );
  }
}