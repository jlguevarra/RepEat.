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
  final injuryController = TextEditingController();

  bool hasInjury = false;
  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;
  String originalGoal = '';
  String updatedGoal = '';
  String originalCurrentWeight = '';
  String originalTargetWeight = '';
  String originalInjuryDetails = '';
  bool originalHasInjury = false;

  int? userId;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Add listeners to watch for text changes
    currentWeightController.addListener(_onFieldChanged);
    targetWeightController.addListener(_onFieldChanged);
    injuryController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (isEditing) {
      setState(() {}); // Triggers re-build to check hasChanges
    }
  }

  @override
  void dispose() {
    currentWeightController.dispose();
    targetWeightController.dispose();
    injuryController.dispose();
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
        originalInjuryDetails = profile['injury_details'] ?? '';
        originalHasInjury = profile['has_injury'] == '1';
        originalGoal = profile['goal'] ?? '';
        updatedGoal = originalGoal;


        currentWeightController.text = originalCurrentWeight;
        targetWeightController.text = originalTargetWeight;
        injuryController.text = originalInjuryDetails;
        hasInjury = originalHasInjury;
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
    final target = targetWeightController.text.trim();
    final current = currentWeightController.text.trim();

    if (isEditing) {
      // Determine if goal needs to change
      double? currentW = double.tryParse(current);
      double? targetW = double.tryParse(target);
      updatedGoal = originalGoal;

      if (currentW != null && targetW != null) {
        if (originalGoal.toLowerCase() == 'muscle gain' && targetW < currentW) {
          updatedGoal = 'Weight Loss';
        } else if (originalGoal.toLowerCase() == 'weight loss' && targetW > currentW) {
          updatedGoal = 'Muscle Gain';
        }
        // endurance and general fitness remain as-is
      }
    }

    return currentWeightController.text.trim() != originalCurrentWeight ||
        targetWeightController.text.trim() != originalTargetWeight ||
        hasInjury != originalHasInjury ||
        (hasInjury && injuryController.text.trim() != originalInjuryDetails) ||
        updatedGoal != originalGoal;
  }


  Future<void> _saveData() async {
    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.78/repEatApi/update_physical_stats.php'),
        body: {
          'user_id': userId.toString(),
          'current_weight': currentWeightController.text.trim(),
          'target_weight': targetWeightController.text.trim(),
          'has_injury': hasInjury ? '1' : '0',
          'injury_details': hasInjury ? injuryController.text.trim() : '',
          'goal': updatedGoal,
        },
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_weight', currentWeightController.text.trim());
        await prefs.setString('target_weight', targetWeightController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Physical stats updated.')),
        );
        setState(() {
          originalCurrentWeight = currentWeightController.text.trim();
          originalTargetWeight = targetWeightController.text.trim();
          originalHasInjury = hasInjury;
          originalInjuryDetails = injuryController.text.trim();
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

    if (result == true) {
      setState(() {
        currentWeightController.text = originalCurrentWeight;
        targetWeightController.text = originalTargetWeight;
        injuryController.text = originalInjuryDetails;
        hasInjury = originalHasInjury;
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
            icon: Icon(isEditing ? Icons.cancel : Icons.edit),
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
            const Text(
              'Body Measurements',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            _textInput('Current Weight (lbs)', currentWeightController),
            const SizedBox(height: 12),
            _textInput('Target Weight (lbs)', targetWeightController),
            const SizedBox(height: 20),

            const Text(
              'Injury Information',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            SwitchListTile(
              title: const Text('Do you have an injury?'),
              value: hasInjury,
              activeColor: Colors.deepPurple,
              onChanged: isEditing
                  ? (val) {
                setState(() {
                  hasInjury = val;
                });
              }
                  : null,
            ),
            if (hasInjury) _textInput('Injury Details', injuryController),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: (!isEditing || !hasChanges || isSaving) ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Save', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textInput(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: !isEditing,
      onChanged: (_) {
        if (isEditing) setState(() {}); // to re-evaluate hasChanges
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isEditing ? Colors.white : Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
