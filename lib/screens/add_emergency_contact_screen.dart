import 'package:flutter/material.dart';
import '../services/api_service.dart' as api; // MUST use the 'as api' prefix
import 'home_screen.dart'; // Navigate here on success

// Screen to collect the user's first emergency contact information.
class AddEmergencyContactScreen extends StatefulWidget {
  const AddEmergencyContactScreen({Key? key}) : super(key: key);

  @override
  State<AddEmergencyContactScreen> createState() =>
      _AddEmergencyContactScreenState();
}

class _AddEmergencyContactScreenState extends State<AddEmergencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Utility to show snackbar messages
  void _showSnackbar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }

  // Handles the form submission and API call.
  void _attemptAddContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawPhone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 1. Standardize and validate phone number format
    final phoneNumber = api.ApiService().standardizePhoneNumber(rawPhone);
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage =
            'Invalid phone number format. Must be 10 digits or start with +.';
        _isLoading = false;
      });
      return;
    }

    // 2. Make the API call
    final errorMessage = await api.ApiService().addEmergencyContact(
      name: name,
      phone: phoneNumber,
    );

    // 3. Handle response
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (errorMessage == null) {
        // Success
        _showSnackbar('Contact added successfully!', Colors.green);
        // Navigate to the next screen on success (home_screen.dart)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        setState(() {
          // Display the error, which could be the "Authentication token missing..."
          _errorMessage = errorMessage;
        });
        _showSnackbar('Error: $errorMessage', Colors.red);
      }
    }
  }

// ... rest of the file

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Emergency Contact'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Your First Contact',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Contact Name Input
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Contact Name',
                      hintText: 'e.g., Mom, Husband, Friend',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the contact\'s name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Contact Phone Number Input
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone Number',
                      hintText: 'Include country code (e.g., +919876543210)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the contact\'s phone number.';
                      }
                      // Basic validation, more strict validation happens in ApiService
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

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _attemptAddContact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Save Contact',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
