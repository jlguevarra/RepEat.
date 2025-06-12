import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/gym.jpg', // Replace with your image path
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.deepPurple.shade300,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 40),
                  CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(10),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text('Sign up with email'),
                    onPressed: () {
                      // Handle email signup
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'or use social sign up',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _socialButton(
                    icon: Icons.g_mobiledata,
                    label: 'Continue with Google',
                    onTap: () {
                      // Google sign-in logic
                    },
                  ),
                  const SizedBox(height: 12),
                  _socialButton(
                    icon: Icons.facebook,
                    label: 'Continue with Facebook',
                    onTap: () {
                      // Facebook sign-in logic
                    },
                  ),
                  const SizedBox(height: 12),
                  _socialButton(
                    icon: Icons.apple,
                    label: 'Continue with Apple',
                    onTap: () {
                      // Apple sign-in logic
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have account? ",
                        style: TextStyle(color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to login screen
                        },
                        child: const Text(
                          "Log In",
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
