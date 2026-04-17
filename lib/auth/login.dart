import 'package:bijlismart/auth/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import '../dashboard.dart';
import 'complete_profile.dart';
import 'forget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // --- NEW: RESEND LINK FUNCTION ---
  void _resendLink() async {
    if (emailController.text.isEmpty || !emailController.text.contains("@")) {
      showStatusMessage("Please enter your email first", true);
      return;
    }
    try {
      // Firebase doesn't allow sending link without recent login or just email in some cases
      // Best way: check if user exists or send via password reset logic style
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      showStatusMessage("Verification/Reset link sent to your email!", false);
    } catch (e) {
      showStatusMessage(e.toString().split(']').last.trim(), true);
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (userCredential.user!.emailVerified) {
          DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
          bool isCompleted = doc.exists && (doc.get('profileCompleted') ?? false);

          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) => isCompleted ? DashboardScreen() : const CompleteProfileScreen()
            ));
          }
        } else {
          await _auth.signOut();
          showStatusMessage("Email not verified! Please check your inbox.", true);
        }
      } catch (e) {
        showStatusMessage(e.toString().split(']').last.trim(), true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId: "1050594572005-gvs3o74jqvkf3ri603ovko031v08pjkp.apps.googleusercontent.com",
      ).signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName,
            'email': user.email,
            'createdAt': DateTime.now(),
            'profileCompleted': false,
          });
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CompleteProfileScreen()));
        } else {
          bool isCompleted = userDoc.get('profileCompleted') ?? false;
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) => isCompleted ? DashboardScreen() : const CompleteProfileScreen()
            ));
          }
        }
      }
    } catch (e) {
      showStatusMessage("Google Sign-In failed: ${e.toString()}", true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Image.asset('assests/images/login.png', height: 200, errorBuilder: (c, e, s) => Icon(Icons.bolt_rounded, size: 100, color: accentGreen)),
                const SizedBox(height: 30),
                Text("Welcome back!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryDark)),
                const Text("Let's login for explore continues", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 40),

                TextFormField(
                  controller: emailController,
                  decoration: buildInputDecoration('Enter your email', Icons.email_outlined),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: buildInputDecoration('••••••••', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? 'Password min 6 characters' : null,
                ),

                // --- RESET AND VERIFICATION LINKS ROW ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _resendLink,
                      child: Text("Sent verification link", style: TextStyle(color: accentGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResetPasswordScreen())),
                        child: const Text("Forgot password?", style: TextStyle(color: Colors.grey, fontSize: 12))
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _isLoading
                    ? CircularProgressIndicator(color: accentGreen)
                    : SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: accentGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _login,
                    child: const Text("Log In", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 25),
                const Text("You can Connect with", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity, height: 55,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _signInWithGoogle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assests/images/google.png', height: 22, errorBuilder: (c,e,s) => const Icon(Icons.g_mobiledata)),
                        const SizedBox(width: 12),
                        const Text("Sign Up with Google", style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                        child: Text("Sign Up here", style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold))
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

  InputDecoration buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentGreen, width: 1)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }
}