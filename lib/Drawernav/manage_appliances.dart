import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageAppliancesScreen extends StatefulWidget {
  const ManageAppliancesScreen({super.key});

  @override
  _ManageAppliancesScreenState createState() => _ManageAppliancesScreenState();
}

class _ManageAppliancesScreenState extends State<ManageAppliancesScreen> {
  final Map<String, Map<String, dynamic>> _liveStatus = {};
  Timer? _timer;
  final double _unitRate = 55.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _liveStatus.forEach((id, device) {
            if (device['isOn'] == true) {
              device['seconds'] += 1;
              if (device['limit'] > 0 && device['seconds'] >= device['limit']) {
                device['isOn'] = false;
                // --- TIMER KHATAM HONE PAR SAVE ---
                _saveUsageSession(id, device['name'], device['seconds'], device['watts']);
                _showTimeOverAlert(device['name']);
                device['limit'] = 0;
              }
            }
          });
        });
      }
    });
  }

  // --- DATABASE SAVING LOGIC ---
  Future<void> _saveUsageSession(String id, String name, int seconds, int watts) async {
    if (seconds < 5) return; // Bohat thode seconds save nahi karenge

    String uid = FirebaseAuth.instance.currentUser!.uid;
    double unitsUsed = (watts * (seconds / 3600)) / 1000;
    String today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD

    DocumentReference dailyDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('daily_usage')
        .doc(today);

    await dailyDoc.set({
      'totalUnits': FieldValue.increment(unitsUsed),
      'lastUpdated': FieldValue.serverTimestamp(),
      'deviceBreakdown': FieldValue.arrayUnion([{
        'name': name,
        'units': double.parse(unitsUsed.toStringAsFixed(4)),
        'duration': seconds,
        'timestamp': DateTime.now().toIso8601String(),
      }])
    }, SetOptions(merge: true));

    // Reset seconds after saving to avoid double counting
    _liveStatus[id]!['seconds'] = 0;
  }

  void _showTimeOverAlert(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.alarm_on, color: Colors.red),
            SizedBox(width: 10),
            Text("Time's Up!", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("The set timer for $name has finished. Device turned off."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF367C5F), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Future<void> _showSetTimerDialog(String id, String name) async {
    int? minutes;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text("Set Timer for $name"),
        content: TextField(
          keyboardType: TextInputType.number,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: const InputDecoration(hintText: "Enter minutes", suffixText: "min"),
          onChanged: (val) => minutes = int.tryParse(val),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF367C5F)),
            onPressed: () {
              if (minutes != null && minutes! > 0) {
                setState(() {
                  _liveStatus[id]!['limit'] = minutes! * 60;
                  _liveStatus[id]!['seconds'] = 0;
                  _liveStatus[id]!['isOn'] = true;
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Start Timer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double _calculateLiveUnits(int watts, int seconds) {
    return (watts * (seconds / 3600)) / 1000;
  }

  String _formatDuration(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Live Energy Monitor",
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E4D3B), fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('appliances').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            var docs = snapshot.data!.docs;

            for (var doc in docs) {
              if (!_liveStatus.containsKey(doc.id)) {
                _liveStatus[doc.id] = {
                  "name": doc['name'],
                  "watts": (doc['watts'] as num).toInt(),
                  "isOn": false,
                  "seconds": 0,
                  "limit": 0,
                  "color": _getCategoryColor(doc['category']),
                  "icon": _getCategoryIcon(doc['category']),
                };
              }
            }

            return Column(
              children: [
                _buildTotalUsageCard(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.sensors, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text("Live Device Status",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) => _buildLiveApplianceCard(docs[index].id, isDark),
                  ),
                ),
                _buildAddButton(context),
              ],
            );
          }
      ),
    );
  }

  Widget _buildTotalUsageCard() {
    double totalUnits = 0;
    _liveStatus.forEach((id, d) {
      totalUnits += _calculateLiveUnits(d['watts'], d['seconds']);
    });

    return Container(
      margin: const EdgeInsets.all(25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E4D3B), Color(0xFF367C5F)]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Total Session Usage", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 5),
              Text("${totalUnits.toStringAsFixed(4)} kWh", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text("Est. Cost: Rs. ${(totalUnits * _unitRate).toStringAsFixed(2)}", style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const CircleAvatar(radius: 25, backgroundColor: Colors.white12, child: Icon(Icons.bolt, color: Colors.yellow, size: 30)),
        ],
      ),
    );
  }

  Widget _buildLiveApplianceCard(String id, bool isDark) {
    var device = _liveStatus[id]!;
    double units = _calculateLiveUnits(device['watts'], device['seconds']);
    bool hasLimit = device['limit'] > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        border: device['isOn'] ? Border.all(color: const Color(0xFF367C5F), width: 1.5) : null,
      ),
      child: Row(
        children: [
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(color: device['color'].withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(device['icon'], color: device['color'], size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Running: ${_formatDuration(device['seconds'])}",
                    style: TextStyle(fontSize: 12, color: device['isOn'] ? Colors.green : Colors.grey)),
                if(hasLimit && device['isOn'])
                  Text("Auto-OFF in: ${_formatDuration(device['limit'] - device['seconds'])}",
                      style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _miniTag("${device['watts']}W", isDark ? Colors.white10 : Colors.grey.shade100, isDark ? Colors.white70 : Colors.black54),
                    const SizedBox(width: 5),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.timer_outlined, size: 20, color: hasLimit ? Colors.red : const Color(0xFF367C5F)),
                      onPressed: () => _showSetTimerDialog(id, device['name']),
                    ),
                  ],
                )
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: device['isOn'],
                activeColor: const Color(0xFF367C5F),
                onChanged: (val) {
                  // --- SWITCH OFF HONE PAR SAVE ---
                  if (val == false) {
                    _saveUsageSession(id, device['name'], device['seconds'], device['watts']);
                  }
                  setState(() => device['isOn'] = val);
                },
              ),
              Text("${units.toStringAsFixed(3)} kWh", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _miniTag(String txt, Color bg, Color txColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(txt, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: txColor)),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E4D3B),
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () {
          // Navigator.push(context, MaterialPageRoute(builder: (context) => AddApplianceScreen()));
        },
        child: const Text("+ Register New Appliance", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch(category) {
      case 'Kitchen': return Icons.kitchen;
      case 'Bedroom': return Icons.bed;
      case 'Office': return Icons.laptop;
      case 'Living Room': return Icons.tv;
      default: return Icons.devices;
    }
  }

  Color _getCategoryColor(String category) {
    switch(category) {
      case 'Kitchen': return Colors.orange;
      case 'Bedroom': return Colors.blue;
      case 'Office': return Colors.purple;
      case 'Living Room': return Colors.cyan;
      default: return Colors.green;
    }
  }
}