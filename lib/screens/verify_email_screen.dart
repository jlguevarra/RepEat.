import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import 'package:flutter/services.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const VerifyEmailScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  // Custom Snackbar method
  void _showCustomSnackBar(String message, bool isSuccess) {
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

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.length != 6) {
      _showCustomSnackBar('Please enter a 6-digit code', false);
      return;
    }

    setState(() => _loading = true);

    try {
      final verifyRes = await http.post(
        Uri.parse('http://192.168.1.252/repEatApi/verify_email_code.php'),
        body: {
          'email': widget.email,
          'code': _codeCtrl.text.trim(),
        },
      );

      final verifyData = jsonDecode(verifyRes.body);
      if (verifyData['success'] == true) { // Check for boolean true
        final registerRes = await http.post(
          Uri.parse('http://192.168.1.252/repEatApi/register_user.php'),
          body: {
            'name': widget.name,
            'email': widget.email,
            'password': widget.password,
          },
        );

        final regData = jsonDecode(registerRes.body);
        if (regData['success'] == true) { // Check for boolean true
          _showCustomSnackBar('Account created successfully!', true);

          // Add a small delay to show the success message
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            }
          });
        } else {
          _showCustomSnackBar(regData['message'] ?? 'Registration failed', false);
        }
      } else {
        _showCustomSnackBar(verifyData['message'] ?? 'Invalid verification code', false);
      }
    } catch (e) {
      _showCustomSnackBar('Network error. Please try again.', false);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    try {
      final resend = await http.post(
        Uri.parse('http://192.168.1.252/repEatApi/signup.php'),
        body: {
          'name': widget.name,
          'email': widget.email,
          'password': widget.password,
        },
      );

      final data = jsonDecode(resend.body);
      if (data['success'] == true) { // Check for boolean true
        _showCustomSnackBar(data['message'] ?? 'Verification code resent!', true);
        _startCountdown();
      } else {
        _showCustomSnackBar(data['message'] ?? 'Failed to resend code', false);
      }
    } catch (e) {
      _showCustomSnackBar('Failed to resend code. Please try again.', false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _timer?.cancel();
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
      body: SafeArea(
        child: SingleChildScrollView( // Allow scrolling if needed
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align children to start
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
                    Icons.mark_email_read_outlined,
                    size: 50,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Title
              Text(
                "Verify Your Email",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade900,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                "We've sent a 6-digit code to",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade800,
                ),
              ),
              const SizedBox(height: 30),

              // OTP Input Field
              TextFormField(
                controller: _codeCtrl,
                maxLength: 6,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  letterSpacing: 8, // Space out digits
                ),
                textAlign: TextAlign.center, // Center the text
                decoration: InputDecoration(
                  hintText: '------', // Hint for empty state
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 24,
                    letterSpacing: 8,
                  ),
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
                  counterText: '', // Hide default counter
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Verification code is required';
                  }
                  if (value.length != 6) {
                    return 'Code must be 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Character counter indicator
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_codeCtrl.text.length}/6',
                  style: TextStyle(
                    color: _codeCtrl.text.length == 6
                        ? Colors.green
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Verify & Register Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyCode,
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
                    'Verify & Register',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Resend Code Section
              Center(
                child: Column(
                  children: [
                    Text(
                      "Didn't receive the code?",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _resendCountdown > 0 ? null : _resendCode,
                      child: Text(
                        _resendCountdown > 0
                            ? 'Resend in $_resendCountdown sec'
                            : 'Resend Code',
                        style: TextStyle(
                          color: _resendCountdown > 0
                              ? Colors.grey[500]
                              : Colors.deepPurple.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}