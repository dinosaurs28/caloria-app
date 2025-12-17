import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  List<Map<String, dynamic>> _plans = [];
  int? _selectedPlanId;
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  void _loadPlans() async {
    final data = await DatabaseHelper.instance.getPlans();
    setState(() {
      _plans = data;
      if (data.isNotEmpty) _selectedPlanId = data[0]['id'];
    });
  }

  void _saveCustomer() async {
    if (_nameController.text.isEmpty || _selectedPlanId == null) return;

    // 1. Find the selected plan details to get duration
    final plan = _plans.firstWhere((p) => p['id'] == _selectedPlanId);
    int duration = plan['duration_days'];

    // 2. Calculate Expiry Date
    DateTime expiryDate = _startDate.add(Duration(days: duration));

    // 3. Save to DB
    await DatabaseHelper.instance.addCustomer({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'plan_id': _selectedPlanId,
      'start_date': _startDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'is_active': 1,
    });

    if (mounted) Navigator.pop(context); // Go back to Home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Customer")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Customer Info",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone Number"),
            ),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Delivery Address"),
            ),

            const SizedBox(height: 30),
            const Text(
              "Subscription Plan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            _plans.isEmpty
                ? const Text(
                    "No Plans Available. Please add a plan first!",
                    style: TextStyle(color: Colors.red),
                  )
                : DropdownButtonFormField<int>(
                    value: _selectedPlanId,
                    items: _plans.map((plan) {
                      return DropdownMenuItem<int>(
                        value: plan['id'],
                        child: Text("${plan['name']} (${plan['price']})"),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedPlanId = val),
                    decoration: const InputDecoration(
                      labelText: "Select Package",
                    ),
                  ),

            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Start Date: "),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                  child: Text(
                    "${_startDate.toLocal()}".split(' ')[0],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              onPressed: _saveCustomer,
              child: const Text("Start Subscription"),
            ),
          ],
        ),
      ),
    );
  }
}
