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
  final heightController = TextEditingController();
  bool hasInjury = false;
  String selectedInjuryCategory = 'None';
  String bmiCategory = 'Unknown';
  String updatedGoal = 'General Fitness';

  String originalCurrentWeight = '';
  String originalTargetWeight = '';
  String originalHeight = '';
  bool originalHasInjury = false;
  String originalInjuryDetails = 'None';
  String originalBodyType = 'Unknown';
  String originalGoal = 'General Fitness';

  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;
  int? userId;

  // Add this field to track injury validation
  bool _injuryValid = true;

  final List<String> injuryCategories = [
    "None",
    "Knee Pain",
    "Back Pain",
    "Shoulder Injury",
    "Ankle Sprain",
    "Wrist Pain",
    "Elbow Pain",
    "Neck Strain",
    "Hip Pain",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
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
    if (!isEditing || !hasChanges) return true;
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

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');
    if (userId == null) {
      _showCustomSnackBar('User ID not found. Please log in again.', false);
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.252/repEatApi/get_profile.php?user_id=$userId'),
      );
      final data = json.decode(response.body);

      if (data['success'] == true) {
        final profile = data['data'];
        final currentWeight = profile['current_weight'] ?? '';
        final targetWeight = profile['target_weight'] ?? '';
        final height = profile['height'] ?? '';
        final injuryStatus = profile['has_injury'] == '1';
        final injuryDetails = profile['injury_details'] ?? 'None';
        final bodyType = profile['body_type'] ?? 'Unknown';
        final goal = profile['goal'] ?? 'General Fitness';

        if (mounted) {
          setState(() {
            currentWeightController.text = currentWeight;
            targetWeightController.text = targetWeight;
            heightController.text = height;
            hasInjury = injuryStatus;
            selectedInjuryCategory = injuryStatus && injuryDetails != 'None' ? injuryDetails : 'None';
            bmiCategory = bodyType.isNotEmpty ? bodyType : 'Unknown';
            updatedGoal = goal.isNotEmpty ? goal : 'General Fitness';

            originalCurrentWeight = currentWeight;
            originalTargetWeight = targetWeight;
            originalHeight = height;
            originalHasInjury = injuryStatus;
            originalInjuryDetails = injuryStatus && injuryDetails != 'None' ? injuryDetails : 'None';
            originalBodyType = bodyType.isNotEmpty ? bodyType : 'Unknown';
            originalGoal = goal.isNotEmpty ? goal : 'General Fitness';
            isLoading = false;
          });
        }
      } else {
        _showCustomSnackBar(data['message'] ?? 'Failed to load stats.', false);
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      _showCustomSnackBar('Error loading stats: ${e.toString()}', false);
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool get hasChanges {
    return currentWeightController.text.trim() != originalCurrentWeight ||
        targetWeightController.text.trim() != originalTargetWeight ||
        heightController.text.trim() != originalHeight ||
        hasInjury != originalHasInjury ||
        (hasInjury && selectedInjuryCategory != originalInjuryDetails) ||
        updatedGoal != originalGoal ||
        (!_injuryValid && hasInjury); // Add this line
  }

  void _calculateBMI() {
    final heightText = heightController.text.trim();
    final weightText = currentWeightController.text.trim();

    if (heightText.isEmpty || weightText.isEmpty) {
      setState(() => bmiCategory = 'Unknown');
      return;
    }

    final height = double.tryParse(heightText);
    final weight = double.tryParse(weightText);

    if (height == null || weight == null || height <= 0 || weight <= 0) {
      setState(() => bmiCategory = 'Unknown');
      return;
    }

    final heightInMeters = height / 100;
    final bmi = weight / (heightInMeters * heightInMeters);

    String category;
    if (bmi < 18.5) {
      category = 'Underweight';
    } else if (bmi < 25) {
      category = 'Normal';
    } else if (bmi < 30) {
      category = 'Overweight';
    } else {
      category = 'Obese';
    }

    if (mounted) {
      setState(() => bmiCategory = category);
    }
  }

  Future<void> _saveData() async {
    // Validate all fields first
    if (currentWeightController.text.trim().isEmpty ||
        targetWeightController.text.trim().isEmpty ||
        heightController.text.trim().isEmpty) {
      _showCustomSnackBar('All fields are required.', false);
      return;
    }

    // Validate numeric inputs with realistic ranges
    final currentWeight = double.tryParse(currentWeightController.text.trim());
    final targetWeight = double.tryParse(targetWeightController.text.trim());
    final height = double.tryParse(heightController.text.trim());

    if (currentWeight == null || targetWeight == null || height == null) {
      _showCustomSnackBar('Please enter valid numbers for weight and height.', false);
      return;
    }

    // Realistic validation for weight (minimum 10kg, maximum 500kg)
    if (currentWeight < 10 || currentWeight > 500) {
      _showCustomSnackBar('Current weight must be between 10kg and 500kg.', false);
      return;
    }

    // Realistic validation for target weight (minimum 10kg, maximum 500kg)
    if (targetWeight < 10 || targetWeight > 500) {
      _showCustomSnackBar('Target weight must be between 10kg and 500kg.', false);
      return;
    }

    // Realistic validation for height (minimum 50cm, maximum 300cm)
    if (height < 50 || height > 300) {
      _showCustomSnackBar('Height must be between 50cm and 300cm.', false);
      return;
    }

    // Ensure target weight is reasonable compared to current weight
    if (targetWeight < 10) {
      _showCustomSnackBar('Target weight must be at least 10kg.', false);
      return;
    }

    // Ensure target weight is not significantly lower than current weight
    if (targetWeight < currentWeight * 0.7) {
      _showCustomSnackBar('Target weight cannot be less than 70% of current weight.', false);
      return;
    }

    // Ensure target weight is not significantly higher than current weight
    if (targetWeight > currentWeight * 1.5) {
      _showCustomSnackBar('Target weight cannot be more than 150% of current weight.', false);
      return;
    }

    // Ensure current weight is not equal to target weight (they must be different)
    if (currentWeight == targetWeight) {
      _showCustomSnackBar('Current weight and target weight must be different.', false);
      return;
    }

    // Validate injury selection if injury is present
    if (hasInjury && selectedInjuryCategory == 'None') {
      setState(() => _injuryValid = false);
      _showCustomSnackBar('Please select an injury category', false);
      return;
    } else {
      setState(() => _injuryValid = true);
    }

    // Update BMI before saving
    _calculateBMI();

    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.252repEatApi/update_physical_stats.php'),
        body: {
          'user_id': userId.toString(),
          'current_weight': currentWeightController.text.trim(),
          'target_weight': targetWeightController.text.trim(),
          'height': heightController.text.trim(),
          'has_injury': hasInjury ? '1' : '0',
          'injury_details': hasInjury ? selectedInjuryCategory : 'None',
          'goal': updatedGoal,
          'body_type': bmiCategory,
        },
      );

      final data = json.decode(response.body);
      if (data['success'] == true) {
        _showCustomSnackBar(data['message'] ?? 'Physical stats updated successfully!', true);
        if (mounted) {
          setState(() {
            originalCurrentWeight = currentWeightController.text.trim();
            originalTargetWeight = targetWeightController.text.trim();
            originalHeight = heightController.text.trim();
            originalHasInjury = hasInjury;
            originalInjuryDetails = hasInjury ? selectedInjuryCategory : 'None';
            originalBodyType = bmiCategory;
            originalGoal = updatedGoal;
            isEditing = false;
          });
        }
      } else {
        _showCustomSnackBar(data['message'] ?? 'Failed to update stats.', false);
      }
    } catch (e) {
      _showCustomSnackBar('Network error. Please try again.', false);
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _confirmCancel() async {
    if (!hasChanges) {
      setState(() => isEditing = false);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel changes?'),
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

    if (result == true && mounted) {
      setState(() {
        currentWeightController.text = originalCurrentWeight;
        targetWeightController.text = originalTargetWeight;
        heightController.text = originalHeight;
        hasInjury = originalHasInjury;
        selectedInjuryCategory = originalHasInjury ? originalInjuryDetails : 'None';
        bmiCategory = originalBodyType;
        updatedGoal = originalGoal;
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
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Loading Physical Stats...',
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
          title: const Text('Physical Stats'),
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
                onPressed: _confirmCancel,
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
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.monitor_weight_outlined,
                      size: 40,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your Physical Stats',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your weight, height, and health information',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),

                // Weight Section - Improved Design (Card)
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
                              Icons.line_weight,
                              color: Colors.deepPurple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Weight (kg)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current Weight',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: currentWeightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    readOnly: !isEditing,
                                    style: const TextStyle(color: Colors.black87),
                                    decoration: _inputDecoration().copyWith(
                                      hintText: isEditing ? 'e.g., 70' : null,
                                    ),
                                    onChanged: (value) {
                                      if (isEditing) _calculateBMI();
                                    },
                                    validator: (value) {
                                      if (isEditing && (value == null || value.isEmpty)) {
                                        return 'Required';
                                      }
                                      if (isEditing && double.tryParse(value!) == null) {
                                        return 'Enter a valid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Target Weight',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: targetWeightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    readOnly: !isEditing,
                                    style: const TextStyle(color: Colors.black87),
                                    decoration: _inputDecoration().copyWith(
                                      hintText: isEditing ? 'e.g., 75' : null,
                                    ),
                                    onChanged: (value) {
                                      if (isEditing) {
                                        _calculateBMI();
                                        // Force rebuild to update save button state
                                        if (mounted) setState(() {});
                                      }
                                    },
                                    validator: (value) {
                                      if (isEditing && (value == null || value.isEmpty)) {
                                        return 'Required';
                                      }
                                      if (isEditing && double.tryParse(value!) == null) {
                                        return 'Enter a valid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Height & BMI Section - Improved Design (Card)
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
                              Icons.height,
                              color: Colors.deepPurple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Height & BMI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Height (cm)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: heightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    readOnly: !isEditing,
                                    style: const TextStyle(color: Colors.black87),
                                    decoration: _inputDecoration().copyWith(
                                      hintText: isEditing ? 'e.g., 175' : null,
                                    ),
                                    onChanged: (value) {
                                      if (isEditing) _calculateBMI();
                                    },
                                    validator: (value) {
                                      if (isEditing && (value == null || value.isEmpty)) {
                                        return 'Required';
                                      }
                                      if (isEditing && double.tryParse(value!) == null) {
                                        return 'Enter a valid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'BMI Category',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: _getBMIColor(bmiCategory),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      bmiCategory,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Injury Section - Improved Design (Card)
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
                              hasInjury
                                  ? Icons.healing_outlined
                                  : Icons.check_circle_outline,
                              color: hasInjury
                                  ? Colors.deepPurple.shade700
                                  : Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Injury Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: Text(
                            "I have an injury",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isEditing
                                  ? Colors.deepPurple.shade800
                                  : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            isEditing
                                ? "Turn on if you have any injuries"
                                : (hasInjury
                                ? "Injury details below"
                                : "No injuries reported"),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          activeColor: Colors.deepPurple.shade700,
                          activeTrackColor: Colors.deepPurple.shade200,
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.shade300,
                          value: hasInjury,
                          onChanged: isEditing
                              ? (val) {
                            setState(() {
                              hasInjury = val;
                              if (!hasInjury) {
                                selectedInjuryCategory = 'None';
                                setState(() => _injuryValid = true); // Reset validation when injury is turned off
                              }
                            });
                          }
                              : null,
                        ),
                        if (hasInjury && isEditing) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedInjuryCategory,
                            items: injuryCategories.map((injury) {
                              return DropdownMenuItem(
                                value: injury,
                                child: Text(injury),
                              );
                            }).toList(),
                            onChanged: isEditing
                                ? (val) {
                              if (val != null) {
                                setState(() {
                                  selectedInjuryCategory = val;
                                  _injuryValid = true; // Mark as valid when selection is made
                                });
                              }
                            }
                                : null,
                            decoration: _inputDecoration(),
                            validator: (value) =>
                            hasInjury && (value == null || value.isEmpty)
                                ? 'Please select an injury'
                                : null,
                          ),
                        ] else if (hasInjury && !isEditing) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Injury Details: ${selectedInjuryCategory.isNotEmpty ? selectedInjuryCategory : 'None'}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Save Button (only visible when editing)
                if (isEditing)
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (!hasChanges || isSaving) ? null : _saveData,
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

  // Get color based on BMI category
  Color _getBMIColor(String category) {
    switch (category) {
      case 'Underweight':
        return Colors.blue.shade700;
      case 'Normal':
        return Colors.green.shade700;
      case 'Overweight':
        return Colors.orange.shade700;
      case 'Obese':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade500;
    }
  }

  // Improved Input Decoration
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
    currentWeightController.dispose();
    targetWeightController.dispose();
    heightController.dispose();
    super.dispose();
  }
}