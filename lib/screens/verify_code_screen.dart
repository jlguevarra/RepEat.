// lib/screens/verify_code_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reset_password_screen.dart';

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

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final apiUrl = 'http://localhost/repEatApi/verify_code.php';

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(email: widget.email, code: _codeCtrl.text.trim()),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Error')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade800,
      appBar: AppBar(
        title: const Text('Verify Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text("Enter 6-digit code sent to your email",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Code',
                    labelStyle: const TextStyle(color: Colors.white70),
                    counterStyle: const TextStyle(color: Colors.white38),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white54),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 6) return 'Enter valid 6-digit code';
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Verify Code'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
