import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'verify_email_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.76/repEatApi/signup.php'), // Ensure this URL is correct for your network
        body: {
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showCustomSnackBar(data['message'] ?? 'Verification code sent successfully!', true);

        // Add small delay to show success message
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VerifyEmailScreen(
                  name: _nameCtrl.text.trim(),
                  email: _emailCtrl.text.trim(),
                  password: _passwordCtrl.text.trim(),
                ),
              ),
            );
          }
        });
      } else {
        _showCustomSnackBar(data['message'] ?? 'Failed to send verification code', false);
      }
    } catch (e) {
      _showCustomSnackBar('Network error. Please try again.', false); // Simplified error message
    } finally {
      // Only update state if the widget is still active
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50, // Softer background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.deepPurple.shade800),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // ✅ Re-introduce SingleChildScrollView to prevent overflow
      body: SafeArea(
        child: SingleChildScrollView(
          // Use Padding for horizontal margins and overall padding
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15), // Reduced top space

                // Header Section - Smaller
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_outlined,
                      size: 35, // Smaller icon
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 15), // Reduced space

                // Title
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 24, // Smaller title
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
                const SizedBox(height: 6), // Reduced space

                // Subtitle
                Text(
                  "Join RepEat to start your fitness journey",
                  style: TextStyle(
                    fontSize: 14, // Smaller subtitle
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 25), // Space before form

                // Name Field
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                    hintText: 'Enter your full name',
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                      Icons.person_outline,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Full name is required';
                    if (value.length < 2) return 'Name must be at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14), // Consistent spacing

                // Email Field
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                      Icons.email_outlined,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password Field
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                    hintText: 'Create a password',
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                      Icons.lock_outline,
                      color: Colors.deepPurple.shade700,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required';
                    if (value.length < 8) return 'Password must be at least 8 characters';
                    // Removed complex regex validator to match the removed requirements list
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                    hintText: 'Confirm your password',
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                      Icons.lock_outline,
                      color: Colors.deepPurple.shade700,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20), // Space before button

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 48, // Shorter button
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 15, // Slightly smaller text
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15), // Space after button

                // Login Prompt
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Already have an account?",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13, // Smaller text
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            color: Colors.deepPurple.shade700,
                            fontSize: 13, // Smaller text
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20), // Bottom padding within scroll
              ],
            ),
          ),
        ),
      ),
    );
  }
}