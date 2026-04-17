import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddApplianceScreen extends StatefulWidget {
  const AddApplianceScreen({super.key});

  @override
  _AddApplianceScreenState createState() => _AddApplianceScreenState();
}

class _AddApplianceScreenState extends State<AddApplianceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController wattController = TextEditingController();

  double _usageHours = 5.0; // Default hours
  int _quantity = 1;
  String _selectedCategory = 'Living Room';

  final List<String> _categories = ['Living Room', 'Kitchen', 'Bedroom', 'Office', 'Other'];

  // --- REAL DATABASE SAVING LOGIC ---
  Future<void> _saveAppliance() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. Current User ID lena
        String uid = FirebaseAuth.instance.currentUser!.uid;

        // 2. Data Map taiyar karna
        Map<String, dynamic> applianceData = {
          'name': nameController.text.trim(),
          'watts': double.parse(wattController.text),
          'category': _selectedCategory,
          'usageHours': _usageHours,
          'quantity': _quantity,
          'createdAt': FieldValue.serverTimestamp(), // Sorting ke liye
        };

        // 3. Firestore mein save karna (Users -> UID -> appliances)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('appliances')
            .add(applianceData);

        // Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Appliance Added Successfully!", style: TextStyle(color: Colors.white)),
              backgroundColor: Color(0xFF367C5F)
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        // Error Handling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F2),
      appBar: AppBar(
        title: const Text("Add New Appliance", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLabel("Appliance Name"),
              TextFormField(
                controller: nameController,
                decoration: buildInputDecoration("e.g. Inverter AC, Refrigerator", Icons.devices),
                validator: (v) => v!.isEmpty ? "Please enter name" : null,
              ),

              const SizedBox(height: 20),

              buildLabel("Power Consumption (Watts)"),
              TextFormField(
                controller: wattController,
                keyboardType: TextInputType.number,
                decoration: buildInputDecoration("e.g. 1500", Icons.bolt),
                validator: (v) => v!.isEmpty ? "Enter wattage" : null,
              ),

              const SizedBox(height: 25),

              buildLabel("Category"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildLabel("Daily Usage (Hours)"),
                  Text("${_usageHours.toInt()} hrs", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF367C5F))),
                ],
              ),
              Slider(
                value: _usageHours,
                min: 1, max: 24,
                divisions: 23,
                activeColor: const Color(0xFF367C5F),
                onChanged: (val) => setState(() => _usageHours = val),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Quantity", style: TextStyle(fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _quantity > 1 ? _quantity-- : null)),
                        Text("$_quantity", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF367C5F)), onPressed: () => setState(() => _quantity++)),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF367C5F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _saveAppliance,
                  child: const Text("Save Appliance", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  InputDecoration buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF367C5F)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }
}