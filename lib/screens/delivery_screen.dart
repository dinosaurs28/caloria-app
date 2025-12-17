import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  // Convert Date to "YYYY-MM-DD" string
  String get _dateStr => _selectedDate.toIso8601String().split('T')[0];

  void _loadDeliveries() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getDeliveriesForDate(_dateStr);
    setState(() {
      _deliveries = data;
      _isLoading = false;
    });
  }

  void _toggleStatus(int id, String currentStatus) async {
    bool isDone = currentStatus == "Pending"; // Toggle logic
    await DatabaseHelper.instance.toggleDeliveryStatus(id, isDone);
    _loadDeliveries(); // Refresh UI
  }

  void _changeDate(int daysToAdd) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: daysToAdd));
    });
    _loadDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate Stats
    int total = _deliveries.length;
    int done = _deliveries.where((d) => d['status'] == 'Delivered').length;

    return Column(
      children: [
        // 1. DATE NAVIGATOR
        Container(
          color: Colors.brown[100],
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => _changeDate(-1),
                icon: const Icon(Icons.arrow_back_ios),
              ),
              Text(
                "$_dateStr ${(_dateStr == DateTime.now().toIso8601String().split('T')[0]) ? '(Today)' : ''}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => _changeDate(1),
                icon: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
        ),

        // 2. PROGRESS BAR
        if (total > 0)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LinearProgressIndicator(
              value: done / total,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
              minHeight: 10,
            ),
          ),
        if (total > 0)
          Text(
            "$done / $total Completed",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

        // 3. THE LIST
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _deliveries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 10),
                      Text("No deliveries for $_dateStr"),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _deliveries.length,
                  itemBuilder: (context, index) {
                    final item = _deliveries[index];
                    final isDone = item['status'] == 'Delivered';

                    return Card(
                      color: isDone ? Colors.green[50] : Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isDone
                              ? Colors.green
                              : Colors.orange,
                          child: Icon(
                            item['meal_type'] == 'Lunch'
                                ? Icons.wb_sunny
                                : Icons.nights_stay,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          item['customer_name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone ? Colors.grey : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item['address'],
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.brown[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.brown,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                item['meal_type'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Checkbox(
                          value: isDone,
                          activeColor: Colors.green,
                          onChanged: (val) =>
                              _toggleStatus(item['id'], item['status']),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
