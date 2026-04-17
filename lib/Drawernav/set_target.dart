import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SetTargetScreen extends StatefulWidget {
  @override
  _SetTargetScreenState createState() => _SetTargetScreenState();
}

class _SetTargetScreenState extends State<SetTargetScreen> {
  double _currentLimit = 300; // Default units target
  bool _isLoading = false;    // Loading state for saving
  bool _isFetching = true;   // Loading state for fetching initial data

  @override
  void initState() {
    super.initState();
    _loadCurrentTarget(); // Screen khulte hi data mangwao
  }

  // --- NEW: FETCH DATA FROM FIREBASE ---
  Future<void> _loadCurrentTarget() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('unit_limit')) {
          setState(() {
            _currentLimit = (data['unit_limit'] as num).toDouble();
          });
        }
      }
    } catch (e) {
      print("Error fetching limit: $e");
    } finally {
      setState(() => _isFetching = false);
    }
  }

  // --- SAVE LOGIC ---
  Future<void> _saveTarget() async {
    setState(() => _isLoading = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      double calculatedBillLimit = _currentLimit * 50;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'unit_limit': _currentLimit,
        'bill_limit': calculatedBillLimit,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Monthly target updated successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Set Monthly Target",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E4D3B))) // Loading jab data aa raha ho
          : Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Define your monthly consumption limit to avoid high bills.",
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 40),

            // Target Display Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E4D3B), Color(0xFF367C5F)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1E4D3B).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  const Text("Target Units", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 10),
                  Text("${_currentLimit.toInt()} kWh",
                      style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("Estimated Bill: PKR ${(_currentLimit * 50).toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            const SizedBox(height: 50),
            const Text("Adjust your limit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),

            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF367C5F),
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: const Color(0xFF1E4D3B),
                overlayColor: const Color(0xFF367C5F).withOpacity(0.2),
                valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                valueIndicatorColor: const Color(0xFF1E4D3B),
                valueIndicatorTextStyle: const TextStyle(color: Colors.white),
              ),
              child: Slider(
                value: _currentLimit,
                min: 50,
                max: 1000,
                divisions: 19,
                label: _currentLimit.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _currentLimit = value;
                  });
                },
              ),
            ),

            const Spacer(),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTarget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4D3B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Target",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}