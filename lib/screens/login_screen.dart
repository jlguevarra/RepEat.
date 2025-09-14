import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'sign_up_screen.dart';
import 'forgot_password_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main_nav_screen.dart';
import 'onboarding/onboarding_step1.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage; // For inline error (no SnackBar)

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiUrl = 'http://192.168.100.11/repEatApi/login.php';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = data['user'];
        final int userId = int.parse(user['id'].toString());
        final bool isOnboarded = user['is_onboarded'] == true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userId);
        await prefs.setBool('is_onboarded', isOnboarded);
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_name', user['name']);

        // Navigate to next screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => isOnboarded
                ? MainNavScreen(userId: userId)
                : OnboardingStep1(userId: userId),
          ),
        );
      } else {
        // ✅ Set error message (no SnackBar)
        setState(() {
          _errorMessage = data['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      // ✅ Show connection error inline
      setState(() {
        _errorMessage = 'Unable to connect. Please check your network.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Prevents resizing when keyboard opens
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/gym.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.deepPurple.shade900.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          // Content Layer
          SafeArea(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(), // Prevents unwanted scroll
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // App Title
                      Text(
                        'RepEat',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fuel Your Gains. Track Your Progress.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 50),

                      // Login Form
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email Field
                              TextFormField(
                                controller: _emailCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Email is required';
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Password is required';
                                  if (value.length < 8) return 'Password must be at least 8 characters';
                                  return null;
                                },
                              ),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),

                              // ✅ Inline Error Message (Modern & Clean)
                              if (_errorMessage != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.redAccent, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            height: 1.3,
                                          ),
                                          overflow: TextOverflow.clip,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ✅ Login Button (Always Visible)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: CupertinoButton.filled(
                            borderRadius: BorderRadius.circular(10),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const CupertinoActivityIndicator()
                                : const Text(
                              'Log In',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Sign Up Prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: _goToSignUp,
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Expanded(child: SizedBox()), // Pushes content up
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}