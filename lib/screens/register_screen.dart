import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import '../services/api_service.dart' as api; // Use relative path
import 'otp_verification_screen.dart'; // Use relative path

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // 💡 FIX: Removed redundant local _standardizePhoneNumber function.
  // We now rely exclusively on api.ApiService().standardizePhoneNumber.

  // Handles the attempt to send the OTP via the API.
  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawPhone = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 1. Standardize and validate phone number format using ApiService helper
    final phoneNumber = api.ApiService().standardizePhoneNumber(rawPhone);
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage =
            'Invalid phone number format. Use 10 digits or include +CC.';
        _isLoading = false;
      });
      return;
    }

    // 2. Call the API
    final error = await api.ApiService().requestRegistrationOtp(
      phoneNumber: phoneNumber,
    );

    if (!mounted) return;

    if (error == null) {
      // Success: Navigate to the OTP verification screen, passing the E.164 phone number
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: phoneNumber,
          ),
        ),
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
        title: const Text('Register'),
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
                  'Create Your Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter your phone number to receive a verification code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Phone Number Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g., +919876543210 or 9876543210',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
                      return 'Phone number is too short.';
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

                // Send OTP Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestOtp,
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
                            'SEND OTP',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 40),

                // Navigate to Login
                TextButton(
                  onPressed: () {
                    // Navigate to the Login Screen (assuming Register is pushed on top of Login)
                    Navigator.pop(context);
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
