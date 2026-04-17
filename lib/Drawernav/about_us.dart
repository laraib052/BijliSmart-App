import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F2),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. TOP HEADER (Custom Shape)
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E4D3B), Color(0xFF367C5F)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Aapka App Logo yahan ayega
                        Image.asset('assests/images/logo.png', height: 80, errorBuilder: (c, e, s) => const Icon(Icons.bolt, color: Colors.white, size: 80)),
                        const SizedBox(height: 15),
                        const Text("Smart Energy Manager",
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. OUR VISION (Detailed)
                  buildDetailedSection(
                    "Our Vision",
                    "To become the leading platform for sustainable energy management, helping millions of households across the country reduce waste and contribute to a greener planet through smart technology.",
                    'assests/images/on1.png', // Path updated
                    true,
                  ),

                  const SizedBox(height: 40),

                  // 3. OUR MISSION (Detailed)
                  buildDetailedSection(
                    "Our Mission",
                    "We aim to provide transparent, real-time electricity tracking that empowers users to make informed decisions. By simplifying complex energy data, we help you save money and energy simultaneously.",
                    'assests/images/on2.png', // Path updated
                    false,
                  ),

                  const SizedBox(height: 40),

                  // 4. CORE VALUES SECTION
                  const Text("Core Values", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E4D3B))),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildValueItem(Icons.verified_outlined, "Accuracy"),
                      buildValueItem(Icons.eco_outlined, "Eco-Friendly"),
                      buildValueItem(Icons.security_outlined, "Privacy"),
                      buildValueItem(Icons.support_agent_outlined, "Support"),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 5. OUR TEAM SECTION
                  const Text("Meet Our Team", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E4D3B))),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        buildTeamCard("Laraib Ahmad", "Lead Developer", 'assets/images/lrb.jpg'),
                        buildTeamCard("Ali Khan", "UI Designer", 'assets/images/member2.jpg'),
                        buildTeamCard("Sarah Ahmed", "Project Manager", 'assets/images/member3.jpg'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 6. CONTACT & VERSION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text("Get in touch", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Text("Email: support@energyapp.com", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 5),
                        const Text("Website: www.smartenergy.com", style: TextStyle(color: Colors.grey)),
                        const Divider(height: 30),
                        const Text("v1.0.2 (Beta Edition)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget buildDetailedSection(String title, String desc, String assetPath, bool isImageLeft) {
    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(assetPath, width: 120, height: 120, fit: BoxFit.cover,
          errorBuilder: (c,e,s) => Container(width: 120, height: 120, color: Colors.grey[300], child: const Icon(Icons.image))),
    );

    Widget text = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E4D3B))),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5)),
        ],
      ),
    );

    return Row(
      children: isImageLeft ? [image, const SizedBox(width: 15), text] : [text, const SizedBox(width: 15), image],
    );
  }

  Widget buildValueItem(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: Colors.white, child: Icon(icon, color: const Color(0xFF367C5F))),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget buildTeamCard(String name, String role, String assetPath) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: AssetImage(assetPath),
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(height: 10),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(role, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}