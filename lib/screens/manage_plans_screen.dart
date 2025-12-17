import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class ManagePlansScreen extends StatefulWidget {
  const ManagePlansScreen({super.key});

  @override
  State<ManagePlansScreen> createState() => _ManagePlansScreenState();
}

class _ManagePlansScreenState extends State<ManagePlansScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  // Inputs for new plan
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController(
    text: "30",
  ); // Default 30 days
  int _mealsPerDay = 1;

  @override
  void initState() {
    super.initState();
    _refreshPlans();
  }

  void _refreshPlans() async {
    final data = await DatabaseHelper.instance.getPlans();
    setState(() {
      _plans = data;
      _isLoading = false;
    });
  }

  void _addPlan() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) return;

    await DatabaseHelper.instance.addPlan({
      'name': _nameController.text,
      'meals_per_day': _mealsPerDay,
      'price': double.parse(_priceController.text),
      'duration_days': int.parse(_durationController.text),
    });

    _nameController.clear();
    _priceController.clear();
    _durationController.text = "30";
    Navigator.pop(context); // Close dialog
    _refreshPlans(); // Reload list
  }

  void _deletePlan(int id) async {
    await DatabaseHelper.instance.deletePlan(id);
    _refreshPlans();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Meal Package"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Plan Name (e.g. Veg Lunch)",
                ),
              ),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price"),
              ),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Duration (Days)"),
              ),
              const SizedBox(height: 10),
              DropdownButton<int>(
                value: _mealsPerDay,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text("1 Meal / Day")),
                  DropdownMenuItem(value: 2, child: Text("2 Meals / Day")),
                ],
                onChanged: (val) => setState(() {
                  _mealsPerDay = val!;
                  Navigator.pop(context); // Close old dialog
                  _showAddDialog(); // Reopen to show change (simple hack)
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(onPressed: _addPlan, child: const Text("Save")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Plans")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
          ? const Center(child: Text("No Plans Added Yet"))
          : ListView.builder(
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      plan['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${plan['duration_days']} Days  |  ${plan['meals_per_day']} Meals/Day",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePlan(plan['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
