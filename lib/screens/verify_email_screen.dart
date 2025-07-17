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

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter 6-digit code')));
      return;
    }

    setState(() => _loading = true);

    final verifyRes = await http.post(
      Uri.parse('http://192.168.0.11/repEatApi/verify_email_code.php'),
      body: {
        'email': widget.email,
        'code': _codeCtrl.text.trim(),
      },
    );

    final verifyData = jsonDecode(verifyRes.body);
    if (verifyData['success']) {
      final registerRes = await http.post(
        Uri.parse('http://192.168.0.11repEatApi/register_user.php'),
        body: {
          'name': widget.name,
          'email': widget.email,
          'password': widget.password,
        },
      );

      final regData = jsonDecode(registerRes.body);
      if (regData['success']) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Account created!')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(regData['message'] ?? 'Registration failed')),
        );
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(verifyData['message'])));
    }

    setState(() => _loading = false);
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    final resend = await http.post(
      Uri.parse('http://192.168.0.11/repEatApi/signup.php'),
      body: {
        'name': widget.name,
        'email': widget.email,
        'password': widget.password,
      },
    );

    final data = jsonDecode(resend.body);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(data['message'] ?? 'Code resent')));

    _startCountdown();
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
      backgroundColor: Colors.deepPurple.shade800,
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                "Enter the 6-digit code sent to your email.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeCtrl,
                maxLength: 6,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 👈 Restrict to numbers only
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  labelStyle: TextStyle(color: Colors.white70),
                  counterStyle: TextStyle(color: Colors.white38),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _verifyCode,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Verify & Register'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resendCountdown > 0 ? null : _resendCode,
                child: Text(_resendCountdown > 0
                    ? 'Resend in $_resendCountdown sec'
                    : 'Resend Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
