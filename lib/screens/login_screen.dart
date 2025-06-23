import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _goToDashboard(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // Get screen dimensions

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/gym.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.deepPurple.shade800.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 60),

                        // App title (optional logo can be added here)
                        Text(
                          'RepEat',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Track your reps. Fuel your body.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),

                        const Spacer(),

                        CupertinoButton.filled(
                          borderRadius: BorderRadius.circular(10),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          onPressed: () => _goToDashboard(context),
                          child: const Text(
                          'Sign up with Email',
                          style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          ),
                          ),
                          ),

                        const SizedBox(height: 16),

                        const Text(
                          'Or sign up with',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _socialButton(
                          icon: Icons.g_mobiledata,
                          label: 'Continue with Google',
                          onTap: () => _goToDashboard(context),
                        ),
                        const SizedBox(height: 12),
                        _socialButton(
                          icon: Icons.facebook,
                          label: 'Continue with Facebook',
                          onTap: () => _goToDashboard(context),
                        ),
                        const SizedBox(height: 12),
                        _socialButton(
                          icon: Icons.apple,
                          label: 'Continue with Apple',
                          onTap: () => _goToDashboard(context),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(color: Colors.white),
                            ),
                            GestureDetector(
                              onTap: () => _goToDashboard(context),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
