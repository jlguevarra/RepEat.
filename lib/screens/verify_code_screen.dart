import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reset_password_screen.dart';
import 'package:flutter/services.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeCtrl = TextEditingController();

  bool _isLoading = false;
  bool _canResend = false;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
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

  void startTimer() {
    setState(() {
      _secondsLeft = 60;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final apiUrl = 'http://192.168.100.76/repEatApi/verify_code.php'; // Replace with your LAN IP

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'email': widget.email,
          'code': _codeCtrl.text.trim(),
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _showCustomSnackBar(data['message'] ?? 'Code verified successfully!', true); // Updated SnackBar

        // Add small delay to show success message
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(
                  email: widget.email,
                  code: _codeCtrl.text.trim(), // ✅ Pass the code here
                ),
              ),
            );
          }
        });
      } else {
        _showCustomSnackBar(data['message'] ?? 'Invalid verification code', false); // Updated SnackBar
      }
    } catch (e) {
      _showCustomSnackBar('Network error: ${e.toString()}', false); // Updated SnackBar
    } finally {
      if (mounted) { // Check if mounted before setState
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    final resendUrl = 'http://192.168.100.76/repEatApi/forgot_password.php'; // Replace with your LAN IP

    try {
      final response = await http.post(
        Uri.parse(resendUrl),
        body: {'email': widget.email},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _showCustomSnackBar(data['message'] ?? 'Verification code resent!', true); // Updated SnackBar
        startTimer();
      } else {
        _showCustomSnackBar(data['message'] ?? 'Failed to resend code', false); // Updated SnackBar
      }
    } catch (e) {
      _showCustomSnackBar('Failed to resend: ${e.toString()}', false); // Updated SnackBar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50, // Softer background - Improved Design
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.deepPurple.shade800), // Updated color
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea( // Improved Design
        child: SingleChildScrollView( // Allow scrolling if needed
          padding: const EdgeInsets.all(24), // Improved Design
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Improved Design
              children: [
                // Header Section - Improved Design
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sms_outlined,
                      size: 50,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Title - Improved Design
                Text(
                  "Verify Your Email",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle - Improved Design
                Text(
                  "We've sent a 6-digit code to",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
                const SizedBox(height: 30),

                // OTP Input Field - Improved Design
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 24,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '------',
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
                    counterText: '',
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

                // Character counter - Improved Design
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

                // Verify Button - Improved Design
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
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
                      'Verify Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Resend Code Section - Improved Design
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
                        onPressed: _canResend ? _resendCode : null,
                        child: Text(
                          _canResend
                              ? 'Resend Code'
                              : 'Resend in $_secondsLeft sec',
                          style: TextStyle(
                            color: _canResend
                                ? Colors.deepPurple.shade700
                                : Colors.grey[500],
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
      ),
    );
  }
}