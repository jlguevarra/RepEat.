// lib/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // --- 1. ADD THIS IMPORT for TimeoutException ---
import 'dart:io';   // --- 2. ADD THIS IMPORT for SocketException ---
import 'verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  bool _isLoading = false;

  // Custom Snackbar method (No changes here)
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

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final apiUrl = 'https://repeatapp.site/repEatApi/forgot_password.php';

    // --- 3. REFINED TRY-CATCH BLOCK ---
    try {
      // Add a timeout to the request to prevent it from hanging indefinitely
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'email': _emailCtrl.text.trim()},
      ).timeout(const Duration(seconds: 10)); // Request will fail if it takes longer than 10 seconds

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showCustomSnackBar('Reset code sent successfully!', true);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VerifyCodeScreen(email: _emailCtrl.text.trim()),
              ),
            );
          }
        });
      } else {
        _showCustomSnackBar(data['message'] ?? 'Failed to send reset code. Please try again.', false);
      }
    } on TimeoutException catch (_) {
      // This is caught when the server is too slow to respond.
      _showCustomSnackBar('The server took too long to respond. Please try again later.', false);
    } on SocketException catch (_) {
      // This is caught when there is no internet connection or the server is down.
      _showCustomSnackBar('No Internet connection. Please check your network.', false);
    } on http.ClientException catch (_) {
      // This can catch other HTTP-related errors.
      _showCustomSnackBar('Failed to connect to the server. Please try again later.', false);
    } catch (e) {
      // This is a general catch-all for any other unexpected errors.
      _showCustomSnackBar('An unexpected error occurred: ${e.toString()}', false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // --- END OF REFINED BLOCK ---


  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- NO CHANGES NEEDED IN THE BUILD METHOD ---
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.deepPurple.shade800),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                      Icons.lock_reset_outlined,
                      size: 50,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                Text(
                  "Forgot Password?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  "Enter your email address and we'll send you a code to reset your password.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                TextFormField(
                  controller: _emailCtrl,
                  // CORRECT
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
                const SizedBox(height: 30),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Send Reset Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Back to Login
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Colors.deepPurple.shade700,
                        fontSize: 14,
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