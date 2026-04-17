import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // 🔹 Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assests/images/bg.jpg'), // spelling fix
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🔹 Overlay to reduce opacity
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white.withOpacity(0.5), // 0.0-1.0 (opacity)
          ),

          // 🔹 Original content on top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [

                  const SizedBox(height: 40),

                  // Logo
                  Image.asset(
                    'assests/images/logo.png', // spelling fix
                    height: 90,
                  ),

                  const SizedBox(height: 20),

                  // App Name
                  const Text(
                    'BijliSmart',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tagline
                  const Text(
                    'Track your daily electricity usage\nand save on your bill',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Illustration
                  Image.asset(
                    'assests/images/home.png', // spelling fix
                    height: 260,
                  ),

                  const Spacer(),

                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5A4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
