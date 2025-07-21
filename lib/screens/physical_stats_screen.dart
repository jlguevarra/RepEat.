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
  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;

  String originalGoal = '';
  String updatedGoal = '';
  String originalCurrentWeight = '';
  String originalTargetWeight = '';
  String originalHeight = '';
  String originalInjuryDetails = '';
  String originalBodyType = '';
  bool originalHasInjury = false;

  String selectedInjuryCategory = 'None';
  final List<String> injuryCategories = [
    "Knee Pain",
    "Back Pain",
    "Shoulder Injury",
    "Ankle Sprain",
    "Wrist Pain",
    "Elbow Pain",
    "Neck Strain",
    "Hip Pain"
  ];

  int? userId;

  String bmiCategory = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadData();
    currentWeightController.addListener(_onFieldChanged);
    targetWeightController.addListener(_onFieldChanged);
    heightController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (isEditing) {
      _updateBMI();
      setState(() {});
    }
  }

  void _updateBMI() {
    final weightKg = double.tryParse(currentWeightController.text.trim());
    final heightCm = double.tryParse(heightController.text.trim());
    if (weightKg != null && heightCm != null && heightCm > 0) {
      final heightM = heightCm / 100;
      final bmi = weightKg / (heightM * heightM);
      if (bmi < 18.5) {
        bmiCategory = 'Underweight';
      } else if (bmi < 24.9) {
        bmiCategory = 'Normal';
      } else if (bmi < 29.9) {
        bmiCategory = 'Overweight';
      } else {
        bmiCategory = 'Obese';
      }
    } else {
      bmiCategory = 'Unknown';
    }
  }

  @override
  void dispose() {
    currentWeightController.dispose();
    targetWeightController.dispose();
    heightController.dispose();
    super.dispose();
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
        'http://192.168.100.78/repEatApi/get_profile.php?user_id=$userId',
      ));
      final data = json.decode(response.body);

      if (data['success'] == true) {
        final profile = data['data'];
        originalCurrentWeight = profile['current_weight'] ?? '';
        originalTargetWeight = profile['target_weight'] ?? '';
        originalHeight = profile['height'] ?? '';
        originalInjuryDetails = profile['injury_details'] ?? 'None';
        originalHasInjury = profile['has_injury'].toString() == '1';
        originalGoal = profile['goal'] ?? '';
        updatedGoal = originalGoal;
        originalBodyType = profile['body_type'] ?? '';

        currentWeightController.text = originalCurrentWeight;
        targetWeightController.text = originalTargetWeight;
        heightController.text = originalHeight;
        hasInjury = originalHasInjury;

        if (hasInjury && originalInjuryDetails != 'None') {
          if (injuryCategories.contains(originalInjuryDetails)) {
            selectedInjuryCategory = originalInjuryDetails;
          } else {
            selectedInjuryCategory = injuryCategories.first;
          }
        } else {
          selectedInjuryCategory = 'None';
        }

        bmiCategory = originalBodyType.isNotEmpty ? originalBodyType : 'Unknown';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to load stats.')),
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

  bool get hasChanges {
    return currentWeightController.text.trim() != originalCurrentWeight ||
        targetWeightController.text.trim() != originalTargetWeight ||
        heightController.text.trim() != originalHeight ||
        hasInjury != originalHasInjury ||
        (hasInjury && selectedInjuryCategory != originalInjuryDetails) ||
        updatedGoal != originalGoal;
  }

  Future<void> _saveData() async {
    setState(() => isSaving = true);

    _updateBMI();

    final currentWeight = double.tryParse(currentWeightController.text.trim()) ?? 0;
    final targetWeight = double.tryParse(targetWeightController.text.trim()) ?? 0;

    final goalLower = updatedGoal.toLowerCase();
    if (goalLower == 'muscle gain' || goalLower == 'weight loss') {
      if (currentWeight > targetWeight) {
        updatedGoal = 'Weight Loss';
      } else if (currentWeight < targetWeight) {
        updatedGoal = 'Muscle Gain';
      }
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.78/repEatApi/update_physical_stats.php'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Physical stats updated.')),
        );
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to update stats.')),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (result == true) {
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Physical Stats'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _confirmCancel();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Body Measurements', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 8),
            _textInput('Current Weight (kg)', currentWeightController),
            const SizedBox(height: 12),
            _textInput('Target Weight (kg)', targetWeightController),
            const SizedBox(height: 12),
            _textInput('Height (cm)', heightController),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.deepPurple.withOpacity(0.1),
                border: Border.all(color: Colors.deepPurple),
              ),
              child: Text('BMI Category: $bmiCategory', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            const Text('Injury Information', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            SwitchListTile(
              title: const Text('Do you have an injury?'),
              value: hasInjury,
              activeColor: Colors.deepPurple,
              onChanged: isEditing
                  ? (val) {
                setState(() {
                  hasInjury = val;
                  selectedInjuryCategory = val ? injuryCategories.first : 'None';
                });
              }
                  : null,
            ),
            if (hasInjury && isEditing)
              DropdownButtonFormField<String>(
                value: selectedInjuryCategory != 'None' ? selectedInjuryCategory : injuryCategories.first,
                items: injuryCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedInjuryCategory = val;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Injury Category', border: OutlineInputBorder()),
              ),
            if (!isEditing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Injury Details: ${hasInjury ? (originalInjuryDetails.isNotEmpty ? originalInjuryDetails : 'None') : 'None'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            const SizedBox(height: 30),

            // Only show save button when in edit mode
            if (isEditing) ...[
              Center(
                child: ElevatedButton(
                  onPressed: (!hasChanges || isSaving) ? null : _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  ),
                  child: isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _textInput(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: !isEditing,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isEditing ? Colors.white : Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}