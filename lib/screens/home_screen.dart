import 'package:flutter/material.dart';
import 'manage_plans_screen.dart';
import 'add_customer_screen.dart';
import 'delivery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- WIDGETS FOR TABS ---

  // 1. Delivery Tab (Still Placeholder for now)
  Widget _buildDeliveryTab() {
    return const DeliveryScreen();
  }

  // 2. Admin Tab (The Dashboard)
  Widget _buildAdminTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildAdminCard(
            icon: Icons.fastfood,
            title: "Manage Meal Plans",
            subtitle: "Add or remove menu packages",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManagePlansScreen()),
            ),
          ),
          const SizedBox(height: 15),
          _buildAdminCard(
            icon: Icons.person_add,
            title: "Onboard Customer",
            subtitle: "Start a new subscription",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to make the cards look nice
  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.brown[100],
          child: Icon(icon, color: Colors.brown),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cafe Manager'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: _selectedIndex == 0 ? _buildDeliveryTab() : _buildAdminTab(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Delivery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
