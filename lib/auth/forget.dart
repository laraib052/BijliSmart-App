import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    // Theme Colors (Matching your Login/SignUp)
    final Color primaryDark = const Color(0xFF1E4D3B);
    final Color accentGreen = const Color(0xFF367C5F);
    final Color bgColor = const Color(0xFFF8FAF9);

    void showStatus(String msg, bool isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.redAccent : accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Illustration Image (Matching the flow)
            Image.asset(
              'assests/images/reset.png',
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => Icon(Icons.lock_reset_rounded, size: 100, color: accentGreen),
            ),

            const SizedBox(height: 30),

            Text("Reset Password",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryDark)),
            const SizedBox(height: 10),
            const Text(
              "Enter your email address below to receive a password reset link.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 40),

            // Email Input Field
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade400, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentGreen, width: 1),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Send Link Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  String email = emailController.text.trim();
                  if (email.contains("@") && email.length > 5) {
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      showStatus("Reset link sent! Please check your inbox.", false);
                      Navigator.pop(context);
                    } catch (e) {
                      showStatus(e.toString().split(']').last.trim(), true);
                    }
                  } else {
                    showStatus("Please enter a valid email address", true);
                  }
                },
                child: const Text("Send Reset Link",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),

            // Back to Login Link
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Back to Login",
                  style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}