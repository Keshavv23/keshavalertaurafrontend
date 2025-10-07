import 'package:flutter/material.dart';
import '../services/api_service.dart' as api;
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper function to ensure the phone number is in E.164 format (+91...)
  // 🚨 NOTE: This is the redundant local function the fix intended to remove.
  String _standardizePhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleanPhone.startsWith('+')) {
      return cleanPhone;
    }
    // If it's a 10-digit number (common for India), prepend the country code (+91)
    if (cleanPhone.length == 10 && RegExp(r'^\d{10}$').hasMatch(cleanPhone)) {
      return '+91$cleanPhone';
    }

    // For other cases, return an empty string to indicate an invalid format
    return '';
  }

  Future<void> _attemptLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawPhone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 1. Standardize and validate phone number format
    // FIX NOTE: This call should be updated to use api.ApiService().standardizePhoneNumber(rawPhone);
    final phoneNumber = _standardizePhoneNumber(rawPhone);
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid phone number format.';
        _isLoading = false;
      });
      return;
    }

    // 2. Perform API login
    final apiService = api.ApiService();
    final error = await apiService.login(
      phoneNumber: phoneNumber,
      password: password,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (error == null) {
        // Success: Navigate to the Home Screen and clear the stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        // Failure
        setState(() {
          _errorMessage = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log in to Alert Aura'),
        centerTitle: true,
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Phone Number Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g., +919876543210 or 9876543210',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _attemptLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                        )
                      : const Text(
                          'LOG IN',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 40),

                // Registration Link
                TextButton(
                  onPressed: () {
                    // Navigate to the Register Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Register now",
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
