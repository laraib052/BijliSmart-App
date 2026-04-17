import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Storage import zaroori hai
import 'package:image_picker/image_picker.dart';
import '../dashboard.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _areaController = TextEditingController();

  String? _selectedProvider;
  String? _selectedProvince;
  String? _selectedCity;
  bool _isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> providers = ["K-Electric", "LESCO", "IESCO", "FESCO", "PESCO"];
  final List<String> provinces = ["Punjab", "Sindh", "KPK", "Balochistan"];
  final List<String> cities = ["Lahore", "Karachi", "Islamabad", "Peshawar", "Faisalabad"];

  // --- 1. PICK IMAGE ---
  Future<void> pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  // --- 2. UPLOAD IMAGE TO FIREBASE STORAGE ---
  Future<String?> uploadImageToFirebase(File imageFile) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      Reference ref = FirebaseStorage.instance.ref().child('profile_pics').child('$uid.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  void showStatus(String msg, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : const Color(0xFF367C5F)),
    );
  }

  // --- 3. FINISH PROFILE (WITH IMAGE LOGIC) ---
  Future<void> finishProfile() async {
    if (!_formKey.currentState!.validate() ||
        _selectedProvider == null ||
        _selectedProvince == null ||
        _selectedCity == null) {
      showStatus("Please complete all fields", true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? imageUrl;
      // Agar user ne image select ki hai toh pehle upload karo
      if (_profileImage != null) {
        imageUrl = await uploadImageToFirebase(_profileImage!);
      }

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "phone": _phoneController.text.trim(),
        "cnic": _cnicController.text.trim(),
        "area": _areaController.text.trim(),
        "province": _selectedProvince,
        "city": _selectedCity,
        "provider": _selectedProvider,
        "profile_image": imageUrl, // URL database mein save ho gaya
        "profileCompleted": true,
        "lastUpdated": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      showStatus("Profile Completed Successfully!", false);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      showStatus("Error: ${e.toString()}", true);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Complete Profile", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E4D3B))),
                const Text("Provide details for smart energy monitoring", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),

                // PROFILE IMAGE UI
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage("assets/images/profile.png") as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(color: const Color(0xFF367C5F), borderRadius: BorderRadius.circular(50)),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: pickImage,
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                buildInput("Phone Number", _phoneController, Icons.phone, context),
                const SizedBox(height: 15),
                buildInput("CNIC", _cnicController, Icons.credit_card, context),
                const SizedBox(height: 15),
                buildInput("Area", _areaController, Icons.location_on, context),
                const SizedBox(height: 15),

                buildDropdown("Province", provinces, _selectedProvince, (val) => setState(() => _selectedProvince = val), context),
                const SizedBox(height: 15),
                buildDropdown("City", cities, _selectedCity, (val) => setState(() => _selectedCity = val), context),
                const SizedBox(height: 15),
                buildDropdown("Provider", providers, _selectedProvider, (val) => setState(() => _selectedProvider = val), context),

                const SizedBox(height: 40),

                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF367C5F)))
                    : Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(colors: [Color(0xFF367C5F), Color(0xFF5AB391)]),
                  ),
                  child: ElevatedButton(
                    onPressed: finishProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                    child: const Text("Finish Setup", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- INPUT & DROPDOWN WIDGETS ---
  Widget buildInput(String label, TextEditingController controller, IconData icon, BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF367C5F)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget buildDropdown(String label, List<String> list, String? selectedValue, Function(String?) onChanged, BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: list.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: (value) => (value == null) ? "Select $label" : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}