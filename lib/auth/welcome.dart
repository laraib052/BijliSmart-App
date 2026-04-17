import 'package:flutter/material.dart';
// In imports ko apne files ke name ke mutabiq sahi karein
import 'login.dart';
import 'signup.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Top Text Section
              Text(
                "Welcome",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E4D3B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Here you log in securely",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 50),

              // 2. Illustration Image
              Center(
                child: Image.asset(
                  'assests/images/welcome.png',
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.security_outlined, size: 150, color: Colors.blue.shade100);
                  },
                ),
              ),

              const SizedBox(height: 60),

              // 3. Log In Button (Navigation added)
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen())
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  side: BorderSide(color: isDark ? Colors.white70 : const Color(0xFF1E4D3B), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  "Log in",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E4D3B),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. Sign Up Button (Navigation added)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpScreen())
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4D3B),
                  minimumSize: const Size(double.infinity, 55),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: BorderSide(color: Colors.black.withOpacity(0.1)),
                ),
                child: const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}