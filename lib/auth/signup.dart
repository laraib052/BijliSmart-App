import 'package:bijlismart/auth/verification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'complete_profile.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  // Modern Theme Colors
  final Color primaryDark = const Color(0xFF1E4D3B);
  final Color accentGreen = const Color(0xFF367C5F);
  final Color bgColor = const Color(0xFFF8FAF9);

  void showStatusMessage(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        String uid = userCredential.user!.uid;

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'createdAt': DateTime.now(),
          'profileCompleted': false,
        });

        // 1. Verification link bheja
        await userCredential.user?.sendEmailVerification();
        showStatusMessage("Account Created! Please check your email.", false);

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          // 2. Ab user ko waiting screen par bheja
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
          );
        }
      } catch (e) {
        showStatusMessage(e.toString().split(']').last.trim(), true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Illustration Image (Matching Login Screen)
                Image.asset(
                  'assests/images/signup.png',
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Icon(Icons.person_add_rounded, size: 80, color: accentGreen),
                ),

                const SizedBox(height: 20),
                Text("Create Account",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryDark)),
                const SizedBox(height: 8),
                const Text("Sign up to start saving energy!",
                    style: TextStyle(color: Colors.grey, fontSize: 14)),

                const SizedBox(height: 35),

                // Name Field
                TextFormField(
                    controller: nameController,
                    decoration: buildInputDeco("Full Name", Icons.person_outline),
                    validator: (val) => val!.isEmpty ? "Enter your name" : null
                ),
                const SizedBox(height: 15),

                // Email Field
                TextFormField(
                    controller: emailController,
                    decoration: buildInputDeco("Email address", Icons.email_outlined),
                    validator: (val) => (val == null || !val.contains('@')) ? "Enter valid email" : null
                ),
                const SizedBox(height: 15),

                // Password Field
                TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: buildInputDeco("Password", Icons.lock_outline),
                    validator: (val) => val!.length < 6 ? "Min 6 characters required" : null
                ),

                const SizedBox(height: 40),

                _isLoading
                    ? CircularProgressIndicator(color: accentGreen)
                    : SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: _signUp,
                    child: const Text("Create Account",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text("Login here",
                            style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold))
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration buildInputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}