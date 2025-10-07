import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart' as api;
import 'add_emergency_contact_screen.dart'; // Next screen after successful registration
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  // The phone number passed here is already in E.164 format (+91...)
  const OtpVerificationScreen({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _attemptRegistration() async {
    // 1. Validate all form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    final otp = _otpController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 2. Call the API to complete registration and get the token
    final error = await api.ApiService().completeRegistration(
      phoneNumber: widget.phoneNumber,
      password: password,
      name: name,
      otp: otp,
    );

    if (!mounted) return;

    if (error == null) {
      // Success: Clear the navigation stack and go to the Add Contact screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => const AddEmergencyContactScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      // Failure: Show the error message
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Finalize Registration',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900),
                ),
                const SizedBox(height: 10),
                Text(
                  'Code sent to: ${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password (Min 6 characters)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // OTP Field
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ], // Only allows digits
                  maxLength: 6, // Standard OTP length
                  decoration: InputDecoration(
                    labelText: 'OTP',
                    counterText: '', // Hide the character counter
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.vpn_key),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 4) {
                      return 'Please enter the valid OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _attemptRegistration,
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
                            'REGISTER',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Go to Login
                TextButton(
                  onPressed: () {
                    // Navigate to the Login Screen and clear the stack
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text(
                    'Already have an account? Login',
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
