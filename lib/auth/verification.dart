import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'complete_profile.dart'; // Apni screen ka sahi path dein

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // 1. Check karein user pehle se verified to nahi
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      // 2. Agar nahi hai, to har 3 second baad Firebase se check karein (Auto Check)
      timer = Timer.periodic(
        const Duration(seconds: 3),
            (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel(); // Screen band hote hi timer rok dein
    super.dispose();
  }

  // 3. Firebase se puchne wala function ke "Bhai verify hua?"
  Future checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload(); // Data refresh karein

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isEmailVerified) {
      timer?.cancel();
      // Agar verify ho gaya, to agli screen par bhej dein
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_rounded, size: 100, color: Color(0xFF367C5F)),
            const SizedBox(height: 20),
            const Text(
              "Verify your Email",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "A verification link has been sent to your email address. Please check your inbox and click the link to continue..",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Color(0xFF367C5F)),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () => FirebaseAuth.instance.currentUser?.sendEmailVerification(),
              child: const Text("Didn't receive an email? Resend Link", style: TextStyle(color: Color(0xFF367C5F))),
            ),
          ],
        ),
      ),
    );
  }
}