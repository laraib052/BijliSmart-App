import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../onboarding.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // 3 seconds baad khud hi Onboarding par chala jaye ga
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Animated Logo (Lottie file ya Scale Animation)
            // Agar aapke paas lottie file nahi hai, toh simple scale effect:
            TweenAnimationBuilder(
              duration: const Duration(seconds: 2),
              tween: Tween<double>(begin: 0.5, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Image.asset(
                'assests/images/logo.png', // Apna logo path dein
                height: 180,
              ),
            ),

            const SizedBox(height: 20),

            // 2. App Name with Fade-in effect
            Text(
              "BijliSmart",
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: isDark ? Colors.white : const Color(0xFF1E4D3B),
              ),
            ),

            const SizedBox(height: 10),

            // 3. Simple Loading Line ya Dots
            const SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                color: Color(0xFF367C5F),
                backgroundColor: Colors.black12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}