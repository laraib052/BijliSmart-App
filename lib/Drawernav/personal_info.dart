import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PersonalInfoScreen extends StatelessWidget {
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text("Personal Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          // Agar data nahi milta toh empty map use karein
          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildSectionHeader("ACCOUNT IDENTITY"),
                _buildInfoTile("Account ID", userData['accID'] ?? "Generating...", Icons.fingerprint, Colors.blue),

                const SizedBox(height: 25),
                _buildSectionHeader("CONTACT INFORMATION"),
                _buildInfoTile("Full Name", userData['name'] ?? "Not Set", Icons.person_outline, Colors.teal),
                _buildInfoTile("Email Address", userData['email'] ?? _user?.email ?? "Not Set", Icons.email_outlined, Colors.redAccent),
                _buildInfoTile("Phone Number", userData['phone'] ?? "Not Provided", Icons.phone_android_outlined, Colors.green),

                const SizedBox(height: 25),
                _buildSectionHeader("ENERGY & LOCATION"),
                _buildInfoTile("Energy Provider", userData['provider'] ?? "Not Selected", Icons.electric_bolt, Colors.orange),
                _buildInfoTile("Location", userData['location'] ?? "Not Set", Icons.location_on_outlined, Colors.indigo),

                const SizedBox(height: 30),
                // Edit Button
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      // Yahan aap Edit wala form khol sakti hain
                    },
                    icon: const Icon(Icons.edit, color: Color(0xFF367C5F)),
                    label: const Text("Edit Information", style: TextStyle(color: Color(0xFF367C5F), fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E4D3B))),
            ],
          ),
        ],
      ),
    );
  }
}