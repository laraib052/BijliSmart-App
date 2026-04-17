import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EnterUsageScreen extends StatefulWidget {
  const EnterUsageScreen({super.key});

  @override
  State<EnterUsageScreen> createState() => _EnterUsageScreenState();
}

class _EnterUsageScreenState extends State<EnterUsageScreen> {
  bool _isUpdating = false;

  // --- FIREBASE UPDATE FUNCTION (Synced with Manage Screen) ---
  Future<void> _addUnits(double units, String deviceName) async {
    setState(() => _isUpdating = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. Daily Usage Update (Key name 'totalUnits' kar di hai taake sync rahe)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_usage')
          .doc(todayId)
          .set({
        'totalUnits': FieldValue.increment(units), // 'units' ko 'totalUnits' kar diya
        'lastUpdated': FieldValue.serverTimestamp(),
        'day': DateFormat('EEE').format(DateTime.now()).toUpperCase(),
        'deviceBreakdown': FieldValue.arrayUnion([{
          'name': deviceName,
          'units': units,
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'manual_entry'
        }])
      }, SetOptions(merge: true));

      // 2. Global total update karna (Dashboard ke main counter ke liye)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'total_units': FieldValue.increment(units),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$deviceName usage added: $units Units"),
          backgroundColor: const Color(0xFF367C5F),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI Code same rakha hai jo aapne diya tha...
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Enter Today's Usage",
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isUpdating)
            const Padding(
                padding: EdgeInsets.all(15),
                child: SizedBox(width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E4D3B)))
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quick Add Units", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),

            // Fridge logic: Agar aapne Fridge manual add karna hai
            InkWell(
              onTap: () => _addUnits(1.5, "Refrigerator"),
              child: buildUsageInputCard("Fridge", "Click to add 1.5 units", Icons.kitchen, "1.5", false),
            ),
            const SizedBox(height: 15),

            InkWell(
              onTap: () => _addUnits(0.5, "Fan"),
              child: buildUsageInputCard("Fan", "Click to add 0.5 units", Icons.wind_power, "0.5", true),
            ),
            const SizedBox(height: 15),

            InkWell(
              onTap: () => _addUnits(2.0, "AC"),
              child: buildUsageInputCard("AC", "Click to add 2.0 units", Icons.ac_unit_outlined, "2.0", false),
            ),

            const SizedBox(height: 15),

            // High usage warning... (Rest of your UI)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 10),
                  Text("High usage alerts active", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers (Wahi jo aapne diye thay) ---
  Widget buildUsageInputCard(String name, String detail, IconData icon, String value, bool hasProgress) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5A937E), size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(detail, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(5)),
            child: Text("+$value", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E4D3B))),
          ),
        ],
      ),
    );
  }
}