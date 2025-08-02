import 'package:flutter/material.dart';
import 'onboarding_step3.dart';

class OnboardingStep1 extends StatefulWidget {
  final int userId;

  const OnboardingStep1({super.key, required this.userId});

  @override
  State<OnboardingStep1> createState() => _OnboardingStep1State();
}

class _OnboardingStep1State extends State<OnboardingStep1> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedGender;
  DateTime? _birthDate;

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

  void _nextStep() async { // Make method async for potential future use
    if (!_formKey.currentState!.validate()) return;

    if (_birthDate == null) {
      _showCustomSnackBar('Please select your birthdate', false);
      return;
    }

    final now = DateTime.now();
    final age = now.year - _birthDate!.year;
    // Adjust age if birthday hasn't occurred this year
    if (_birthDate!.month > now.month ||
        (_birthDate!.month == now.month && _birthDate!.day > now.day)) {
      // Birthday hasn't happened yet this year
    } else {
      // Birthday has happened or is today
    }
    // More precise age check if needed:
    // if (_birthDate!.isAfter(now) || age < 10 || (age == 10 && ...)) {
    if (_birthDate!.isAfter(now) || age < 10) {
      _showCustomSnackBar('Please enter a valid birthdate (10+ years old)', false);
      return;
    }

    // Navigate to next step
    if (mounted) { // Check if widget is still mounted before navigation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingStep3(
            userId: widget.userId,
            gender: _selectedGender!,
            birthdate: _birthDate!,
          ),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100, now.month, now.day),
      lastDate: now,
      builder: (context, child) { // Optional: Customize date picker theme
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple, // Header background color
              onPrimary: Colors.white, // Header text color
              surface: Colors.white, // Background color
              onSurface: Colors.black, // Default text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple, // Text color for buttons like 'Cancel' and 'OK'
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50, // Softer background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Personal Info'),
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
                      Icons.person_outline,
                      size: 50,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                Text(
                  "Tell Us About Yourself",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  "This helps us personalize your experience",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                // Gender Selection Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Gender',
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
                      Icons.transgender,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  value: _selectedGender,
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedGender = value);
                  },
                  validator: (value) =>
                  value == null ? 'Please select your gender' : null,
                ),
                const SizedBox(height: 24),

                // Birthdate Picker
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Birthdate',
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
                      Icons.calendar_today_outlined,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0), // Adjust padding
                    title: Text(
                      _birthDate == null
                          ? 'Select your birthdate'
                          : '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}',
                      style: TextStyle(
                        color: _birthDate == null ? Colors.grey : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: _pickDate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade700, // Button color
                        foregroundColor: Colors.white, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0, // Remove button shadow
                      ),
                      child: const Text('Pick Date'),
                    ),
                  ),
                ),
                const SizedBox(height: 40), // Space before button

                // Next Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Next',
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