import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'Drawernav/about_us.dart';
import 'Drawernav/add_appliance.dart';
import 'Drawernav/manage_appliances.dart';
import 'Drawernav/personal_info.dart';
import 'Drawernav/set_target.dart';
import 'appearance/theme.dart';
import 'dashboard_features/daily_usage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      UsageContent(),
      BillsScreen(),
      ProfileScreen(),
      SettingsScreen(),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F2),
      drawer: buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E4D3B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          )
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E4D3B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Usage'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Bills'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget buildDrawer(BuildContext context) {
    // Current user ki ID nikalne ke liye
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Drawer(
      backgroundColor: const Color(0xFF1E4D3B),
      child: StreamBuilder<DocumentSnapshot>(
        // Firestore se user ka data live stream ho raha hai
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          // Database se data nikalna
          var userData = snapshot.data?.data() as Map<String, dynamic>?;
          String name = userData?['name'] ?? "User";
          String email = userData?['email'] ?? "No Email";
          String? profilePicUrl = userData?['profile_image'];

          return ListView(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white24,
                  backgroundImage: (profilePicUrl != null && profilePicUrl.isNotEmpty)
                      ? NetworkImage(profilePicUrl)
                      : null,
                  child: (profilePicUrl == null || profilePicUrl.isEmpty)
                      ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "U",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  )
                      : null,
                ),
                accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                accountEmail: Text(email, style: const TextStyle(color: Colors.white70)),
              ),
              buildDrawerItem(context, Icons.add, "Add Appliance", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddApplianceScreen()));
              }),
              buildDrawerItem(context, Icons.settings_suggest, "Manage Appliances", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ManageAppliancesScreen()));
              }),
              buildDrawerItem(context, Icons.track_changes, "Set Target", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => SetTargetScreen()));
              }),
              buildDrawerItem(context, Icons.info_outline, "About Us", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => AboutUsScreen()));
              }),
              buildDrawerItem(context, Icons.person_outline, "Personal Info", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalInfoScreen()));
              }),
              const Divider(color: Colors.white24),
              buildDrawerItem(context, Icons.logout, "Logout", () {
                FirebaseAuth.instance.signOut();
                // Yahan aap Navigation logic add kar sakti hain
              }),
            ],
          );
        }, // Builder ka bracket band
      ), // StreamBuilder ka bracket band
    ); // Drawer ka bracket band
  }
  Widget buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}

// --- SCREEN 0: Usage Content (MAIN BACKEND LOGIC) ---
class UsageContent extends StatelessWidget {
  const UsageContent({super.key});
  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
  Future<String> getAIAdvice(double units, double limit) async {
    // Yahan apni API Key dalein
    const apiKey = "YOUR_GEMINI_API_KEY_HERE";
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final prompt = '''
My electricity bill (units) today is $units kWh and my monthly bill limit is $limit PKR. Tell me in 2 lines in Urdu/Roman Urdu whether my bill is too high? And give me a very simple tip to save electricity.
  ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? "AI is currently unable to provide advice.";
    } catch (e) {
      return "The issue is with the Internet or API.";
    }
  }

  // --- 1. BILL CALCULATION ---
  double calculateDetailedBill(double units) {
    if (units <= 0) return 0;
    double baseCost = 0;
    if (units <= 100) baseCost = units * 22;
    else if (units <= 300) baseCost = (100 * 22) + ((units - 100) * 29);
    else if (units <= 700) baseCost = (100 * 22) + (200 * 29) + ((units - 300) * 38);
    else baseCost = (100 * 22) + (200 * 29) + (400 * 38) + ((units - 700) * 45);

    double fpa = units * 4.5;
    double fixedCharges = 250;
    double subTotal = baseCost + fpa + fixedCharges;
    return subTotal + (subTotal * 0.18);
  }

  // --- 2. BREAKDOWN DATA ---
  Map<String, double> getBillBreakdown(double units) {
    double baseCost = 0;
    if (units <= 100) baseCost = units * 22;
    else if (units <= 300) baseCost = (100 * 22) + ((units - 100) * 29);
    else if (units <= 700) baseCost = (100 * 22) + (200 * 29) + ((units - 300) * 38);
    else baseCost = (100 * 22) + (200 * 29) + (400 * 38) + ((units - 700) * 45);

    double fpa = units * 4.5;
    double fixedCharges = 250;
    double gst = (baseCost + fpa + fixedCharges) * 0.18;
    return {
      "Base Energy Cost": baseCost,
      "Fuel Adjustment (FPA)": fpa,
      "Fixed Charges": fixedCharges,
      "GST (18%)": gst,
      "Total Estimated": baseCost + fpa + fixedCharges + gst,
    };
  }

  // --- 3. SAVE & END MONTH FUNCTION ---
  Future<void> _endMonthAndSave(BuildContext context, double units, double bill) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String monthName = DateFormat('MMMM yyyy').format(DateTime.now());

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('bill_history').add({
        'month': monthName,
        'units': units,
        'totalBill': bill,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'total_units': 0.0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Success! $monthName data saved."), backgroundColor: const Color(0xFF1E4D3B)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showBreakdownSheet(BuildContext context, double units) {
    var breakdown = getBillBreakdown(units);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Tax & Bill Breakdown", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E4D3B))),
            const Divider(height: 30),
            ...breakdown.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: TextStyle(color: e.key.contains("Total") ? Colors.black : Colors.grey[700], fontWeight: e.key.contains("Total") ? FontWeight.bold : FontWeight.normal)),
                  Text("PKR ${e.value.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF367C5F)));

        var userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        double units = (userData?['total_units'] ?? 0.0).toDouble();
        double billLimit = (userData?['bill_limit'] ?? 5000.0).toDouble();
        double estimatedBill = calculateDetailedBill(units);
        double progress = (estimatedBill / billLimit).clamp(0.0, 1.0);

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('daily_usage')
              .orderBy('lastUpdated', descending: true)
              .limit(7)
              .snapshots(),
          builder: (context, usageSnapshot) {
            List<double> weeklyUnits = List.filled(7, 0.0);
            if (usageSnapshot.hasData && usageSnapshot.data!.docs.isNotEmpty) {
              var docs = usageSnapshot.data!.docs;
              for (int i = 0; i < docs.length; i++) {
                if (i < 7) {
                  var data = docs[i].data() as Map<String, dynamic>;
                  // Dono fields check kar raha hai (totalUnits ya units)
                  weeklyUnits[6 - i] = (data['totalUnits'] ?? data['units'] ?? 0.0).toDouble();
                }
              }
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${getGreeting()},",
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    "${userData?['name'] ?? 'User'}!",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4D3B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  buildCostCard(estimatedBill, weeklyUnits),

                  const SizedBox(height: 20),
                  FutureBuilder<String>(
                    future: getAIAdvice(units, billLimit),
                    builder: (context, snapshot) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1E4D3B), Color(0xFF367C5F)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.psychology, color: Colors.white),
                                const SizedBox(width: 10),
                                const Text("AI Smart Insights", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              snapshot.hasData ? snapshot.data! : "AI is thinking...",
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) =>  SetTargetScreen())),
                    child: buildBillLimitCard(context, progress, billLimit),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EnterUsageScreen())),
                          child: buildSmallStatCard("Today's Usage", "${units.toStringAsFixed(1)} kWh", Icons.bolt, Colors.green),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: buildSmallStatCard("Monitoring", "Live", Icons.devices, Colors.blueGrey)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  InkWell(
                    onTap: () => _showBreakdownSheet(context, units),
                    child: buildSmallStatCard("Estimated Bill (Tap for Details)", "PKR ${estimatedBill.toStringAsFixed(0)}", Icons.receipt_long, Colors.teal, isFullWidth: true),
                  ),

                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => _endMonthAndSave(context, units, estimatedBill),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4D3B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text("Save & End Month", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildCostCard(double amount, List<double> weeklyData) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0xFF1E4D3B).withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Estimated Cost", style: TextStyle(color: Colors.grey, fontSize: 13, letterSpacing: 0.5)),
                const SizedBox(height: 5),
                Text("PKR ${amount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1E4D3B))),
              ]),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E4D3B), Color(0xFF2D6A4F)]), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 24),
              )
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 25,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(days[v.toInt() % 7], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    );
                  })),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) => makeGroupData(i, weeklyData[i])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBillLimitCard(BuildContext context, double progress, double limit) {
    Color progressColor = progress > 0.9 ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Monthly Bill Limit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Target: PKR ${limit.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            Icon(Icons.warning_amber_rounded, color: progressColor, size: 30),
          ]),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(height: 80, width: 80, child: CircularProgressIndicator(value: progress, strokeWidth: 8, backgroundColor: Colors.grey.shade200, color: progressColor)),
              Text("${(progress * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget buildSmallStatCard(String title, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 5), Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  BarChartGroupData makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: x == 6 ? [const Color(0xFF1E4D3B), const Color(0xFF42ba96)] : [const Color(0xFF74C69D), const Color(0xFF95D5B2)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 25, color: const Color(0xFFF1F3F2)),
        ),
      ],
    );
  }
}
// Note: BillsScreen, ProfileScreen aur SettingsScreen ka purana code niche lazmi add rakhein.
// --- SCREEN 1: Bills Screen ---
class BillsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F2),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Firebase se saved bills uthana
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('monthly_bills')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1E4D3B)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bill history found."));
          }

          var billsDocs = snapshot.data!.docs;

          // 2. Pending Amount nikalna (Jo Unpaid hain unka total)
          double totalPending = 0;
          for (var doc in billsDocs) {
            if (doc['status'] == "Unpaid") {
              totalPending += double.parse(doc['amount'].toString());
            }
          }

          return Column(
            children: [
              // --- TOP SUMMARY (Total Pending) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E4D3B),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Pending", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text("PKR ${totalPending.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    if (totalPending > 0)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          // Payment logic yahan aayegi
                          _showPaymentDialog(context, uid, billsDocs);
                        },
                        child: const Text("Pay All Pending", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Billing History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E4D3B))),
                    IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
                  ],
                ),
              ),

              // --- BILLS LIST (Live Data) ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: billsDocs.length,
                  itemBuilder: (context, index) {
                    var bill = billsDocs[index];
                    bool isPaid = bill['status'] == "Paid";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPaid ? Icons.check_circle : Icons.pending_actions,
                            color: isPaid ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bill['month'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(isPaid ? "Payment Successful" : "Waiting for payment",
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text("PKR ${bill['amount']}",
                              style: TextStyle(fontWeight: FontWeight.bold, color: isPaid ? Colors.black : Colors.red)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Payment Simulation Dialog ---
  void _showPaymentDialog(BuildContext context, String uid, List<QueryDocumentSnapshot> bills) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Payment"),
        content: const Text("Do you want to mark all pending bills as PAID?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Saare Unpaid bills ko Paid kar dena Firebase mein
              for (var doc in bills) {
                if (doc['status'] == "Unpaid") {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('monthly_bills')
                      .doc(doc.id)
                      .update({'status': 'Paid'});
                }
              }
            },
            child: const Text("Yes, Pay Now"),
          ),
        ],
      ),
    );
  }
}

// --- SCREEN 2: Profile Screen ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // --- 1. LOGOUT LOGIC ---
  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // --- 2. EDIT NAME DIALOG ---
  void _showEditProfileDialog(BuildContext context, String currentName) {
    TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E4D3B)),
            onPressed: () async {
              String uid = FirebaseAuth.instance.currentUser!.uid;
              await FirebaseFirestore.instance.collection('users').doc(uid).update({'name': nameController.text.trim()});
              Navigator.pop(context);
            },
            child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 3. ALERT SETTINGS ---
  void _showLimitDialog(BuildContext context, double currentLimit) {
    TextEditingController limitController = TextEditingController(text: currentLimit.toStringAsFixed(0));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Set Monthly Bill Limit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Budget (PKR)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E4D3B), minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                String uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance.collection('users').doc(uid).update({'bill_limit': double.parse(limitController.text)});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alert limit updated!")));
              },
              child: const Text("Save Limit", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- 4. SECURITY ---
  void _handleSecurity(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password?"),
        content: Text("We will send a password reset link to:\n$email"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset email sent! Check your inbox.")));
            },
            child: const Text("Send Link"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1E4D3B)));
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>?;
          String name = userData?['name'] ?? "User Name";
          String email = userData?['email'] ?? "email@example.com";
          double currentUnits = (userData?['total_units'] ?? 0.0).toDouble();
          double currentLimit = (userData?['bill_limit'] ?? 5000.0).toDouble();

          // DYNAMIC IMAGE URL FROM DATABASE
          String? profilePicUrl = userData?['profile_image'];

          String provider = userData?['provider'] ?? "FESCO";
          String city = userData?['city'] ?? "Faisalabad";
          String province = userData?['province'] ?? "Punjab";

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 220, width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF1E4D3B), Color(0xFF2D6A4F)]),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                      ),
                    ),
                    Positioned(
                      top: 110,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white24,
                              // --- DYNAMIC IMAGE LOGIC ---
                              backgroundImage: (profilePicUrl != null && profilePicUrl.isNotEmpty)
                                  ? NetworkImage(profilePicUrl)
                                  : null,
                              child: (profilePicUrl == null || profilePicUrl.isEmpty)
                                  ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E4D3B))),
                          Text(email, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 125),

                // --- STATS CARD ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem("Current Units", "${currentUnits.toStringAsFixed(1)} kWh", Icons.bolt, Colors.orange),
                        Container(height: 40, width: 1, color: Colors.grey.shade200),
                        _buildStatItem("Bill Limit", "PKR ${currentLimit.toStringAsFixed(0)}", Icons.account_balance_wallet, Colors.green),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- DETAILS SECTION ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 10, bottom: 10),
                        child: Text("Personal Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
                        child: Column(
                          children: [
                            _buildDetailRow("Provider", provider, Icons.electric_bolt),
                            const Divider(),
                            _buildDetailRow("City", city, Icons.location_city),
                            const Divider(),
                            _buildDetailRow("Province", province, Icons.map),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Padding(
                        padding: EdgeInsets.only(left: 10, bottom: 10),
                        child: Text("Account Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      _buildProfileOption(Icons.person_outline_rounded, "Edit Profile", "Update your display name", () {
                        _showEditProfileDialog(context, name);
                      }),
                      _buildProfileOption(Icons.notifications_none_rounded, "Alert Settings", "Update bill limits", () {
                        _showLimitDialog(context, currentLimit);
                      }),
                      _buildProfileOption(Icons.shield_outlined, "Security", "Reset your password via email", () {
                        _handleSecurity(context, email);
                      }),
                      const SizedBox(height: 25),
                      InkWell(
                        onTap: () => _handleLogout(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red.shade100)),
                          child: const Row(
                            children: [
                              Icon(Icons.logout_rounded, color: Colors.redAccent),
                              SizedBox(width: 15),
                              Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- HELPER WIDGETS (Same as before) ---
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1E4D3B)),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildProfileOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF1E4D3B).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF1E4D3B), size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ),
    );
  }
}
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationOn = false;
  bool _isBioMetricOn = false;
  String _selectedLanguage = "English (US)";

  // Data variables
  String userName = "Loading...";
  String userEmail = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1. DATABASE SE DATA FETCH KARNA
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots() // snapshots use kiya taake real-time update ho
          .listen((snapshot) {
        if (snapshot.exists) {
          if (mounted) {
            setState(() {
              userName = snapshot.data()?['name'] ?? "User Name";
              userEmail = user.email ?? "No Email";
            });
          }
        }
      });
    }
  }

  // 2. UPDATE NAME DIALOG (Personal Info Working)
  void _showUpdateNameDialog() {
    TextEditingController nameController = TextEditingController(text: userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              String uid = FirebaseAuth.instance.currentUser!.uid;
              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                'name': nameController.text.trim(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name Updated!")));
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // 3. LANGUAGE PICKER (Working)
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Language", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: const Text("English (US)"),
              trailing: _selectedLanguage == "English (US)" ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () { setState(() => _selectedLanguage = "English (US)"); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text("Urdu (اردو)"),
              trailing: _selectedLanguage == "Urdu (اردو)" ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () { setState(() => _selectedLanguage = "Urdu (اردو)"); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  // 4. LOGOUT FUNCTION
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              "Settings",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF1E4D3B)
              ),
            ),
            const SizedBox(height: 25),

            buildSectionHeader("Account Settings"),
            const SizedBox(height: 10),
            buildSettingCard(context, [
              // PERSONAL INFO (Now Clickable)
              buildListTile(context, Icons.person_outline, "Personal Info", userName, () => _showUpdateNameDialog()),
              const Divider(height: 1),
              // LANGUAGE (Now Clickable)
              buildListTile(context, Icons.language, "Language", _selectedLanguage, () => _showLanguagePicker()),
            ]),

            const SizedBox(height: 25),

            buildSectionHeader("Notifications & Privacy"),
            const SizedBox(height: 10),
            buildSettingCard(context, [
              buildSwitchTile(context, Icons.notifications_none, "Push Notifications", "Alerts for high usage", _isNotificationOn, (val) {
                setState(() => _isNotificationOn = val);
              }),
              const Divider(height: 1),
              buildSwitchTile(context, Icons.fingerprint, "Biometric Lock", "Secure your app usage", _isBioMetricOn, (val) {
                setState(() => _isBioMetricOn = val);
              }),
            ]),

            const SizedBox(height: 25),

            buildSectionHeader("App Appearance"),
            const SizedBox(height: 10),
            buildSettingCard(context, [
              buildSwitchTile(
                  context,
                  Icons.dark_mode_outlined,
                  "Dark Mode",
                  "Switch between themes",
                  themeProvider.isDarkMode,
                      (val) => themeProvider.toggleTheme(val)
              ),
            ]),

            const SizedBox(height: 25),

            buildSectionHeader("Danger Zone"),
            const SizedBox(height: 10),
            buildSettingCard(context, [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                subtitle: const Text("Sign out of your account", style: TextStyle(fontSize: 12)),
                onTap: () => _handleLogout(context),
              ),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS (No Change) ---
  Widget buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.8));
  }

  Widget buildSettingCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(children: children)
      ),
    );
  }

  Widget buildListTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFF1E4D3B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF1E4D3B), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget buildSwitchTile(BuildContext context, IconData icon, String title, String subtitle, bool value, Function(bool) onChanged) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFF1E4D3B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF1E4D3B), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      activeColor: const Color(0xFF367C5F),
    );
  }
}
