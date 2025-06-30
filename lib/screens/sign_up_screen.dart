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
  bool _obscure = true;

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final response = await http.post(
      Uri.parse('http://192.168.0.11/repEatApi/signup.php'),
      body: {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
      },
    );

    final data = jsonDecode(response.body);
    if (data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Code sent')),
      );

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Error sending code')),
      );
    }

    setState(() => _loading = false);
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
      backgroundColor: Colors.deepPurple.shade800,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Sign Up'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildField(_nameCtrl, 'Full Name'),
                const SizedBox(height: 20),
                _buildField(_emailCtrl, 'Email',
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email required';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return 'Invalid email';
                      }
                      return null;
                    }),
                const SizedBox(height: 20),
                _buildPasswordField(_passwordCtrl, 'Password'),
                const SizedBox(height: 20),
                _buildPasswordField(_confirmPasswordCtrl, 'Confirm Password',
                    validator: (v) {
                      if (v != _passwordCtrl.text) return 'Passwords do not match';
                      return null;
                    }),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _loading ? null : _sendVerificationCode,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Send Verification Code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label,
      {TextInputType keyboard = TextInputType.text,
        String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      validator: validator ?? (v) => (v == null || v.isEmpty) ? '$label required' : null,
      decoration: _decoration(label),
    );
  }

  Widget _buildPasswordField(TextEditingController ctrl, String label,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      obscureText: _obscure,
      style: const TextStyle(color: Colors.white),
      validator: validator ??
              (v) => (v == null || v.length < 8) ? 'Minimum 8 characters' : null,
      decoration: _decoration(label).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white12,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder:
      OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54)),
      focusedBorder:
      OutlineInputBorder(borderSide: const BorderSide(color: Colors.white)),
    );
  }
}
