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
  String selectedDiet = 'None';
  Set<String> selectedAllergies = {};

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

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    if (userId == null) {
      if (!mounted) return;
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
        final String diet = profile['diet_preference'] ?? 'None';
        final String allergiesRaw = profile['allergies'] ?? '';

        setState(() {
          selectedDiet = dietOptions.contains(diet) ? diet : 'None';
          selectedAllergies = allergiesRaw.isNotEmpty && allergiesRaw != "None"
              ? Set<String>.from(
            allergiesRaw.split(',').map((e) => e.trim()).where((e) => allergyOptions.contains(e)),
          )
              : {};
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to load profile.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
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
        setState(() => isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Preferences updated.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update preferences.')),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet & Allergies'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => isEditing = true),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Diet Preference',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            isEditing
                ? DropdownButtonFormField<String>(
              value: selectedDiet,
              items: dietOptions.map((diet) {
                return DropdownMenuItem(
                  value: diet,
                  child: Text(diet),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => selectedDiet = val);
                }
              },
              decoration: _inputDecoration(),
            )
                : Text(selectedDiet, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 24),
            const Text(
              'Allergies',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),

            isEditing
                ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allergyOptions.map((allergy) {
                final isSelected = selectedAllergies.contains(allergy);
                return FilterChip(
                  label: Text(allergy),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
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
                );
              }).toList(),
            )
                : Text(
              selectedAllergies.isEmpty
                  ? "None"
                  : selectedAllergies.join(', '),
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 32),
            if (isEditing)
              Center(
                child: ElevatedButton(
                  onPressed: isSaving ? null : _saveProfile,
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

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
