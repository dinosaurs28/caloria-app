import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passController = TextEditingController();
  bool _isFirstTime = true;
  String? _storedPass;
  String _statusMessage = "Loading...";

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  // Check if user has set a password before
  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final pass = prefs.getString('admin_pass');

    setState(() {
      if (pass == null) {
        _isFirstTime = true;
        _statusMessage = "Set your Admin Password";
      } else {
        _isFirstTime = false;
        _storedPass = pass;
        _statusMessage = "Enter Admin Password";
      }
    });
  }

  Future<void> _handleLogin() async {
    final input = _passController.text;
    final prefs = await SharedPreferences.getInstance();

    if (_isFirstTime) {
      // SETTING PASSWORD
      if (input.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password must be 4+ chars")),
        );
        return;
      }
      await prefs.setString('admin_pass', input);
      _navigateToHome();
    } else {
      // CHECKING PASSWORD
      if (input == _storedPass) {
        _navigateToHome();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Wrong Password!")));
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.coffee, size: 80, color: Colors.brown),
              const SizedBox(height: 20),
              Text(
                "Cafe Manager",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              const SizedBox(height: 40),
              Text(_statusMessage, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _passController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _handleLogin,
                child: Text(_isFirstTime ? "Set Password & Start" : "Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
