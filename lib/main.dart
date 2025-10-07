// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  // Essential for plugins (like SecureStorage) to initialize before runApp
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlertApp());
}

class AlertApp extends StatelessWidget {
  const AlertApp({Key? key}) : super(key: key);

  // SecureStorage instance to check for a token
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Logic to decide whether to show Home or Login screen
  Future<Widget> _getInitialScreen() async {
    // Check if a JWT token is already stored
    final token = await _storage.read(key: 'jwt_access_token');

    // If a token exists, go straight to the Home Screen
    if (token != null) {
      return const HomeScreen();
    }
    // Otherwise, show the Login Screen
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeshavAlertaura',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      // Use FutureBuilder to determine the initial screen based on token presence
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a simple loading indicator while checking the token
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.redAccent),
                    SizedBox(height: 16),
                    Text("Checking session...",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }
          // Display the determined screen (HomeScreen or LoginScreen), defaulting to LoginScreen
          return snapshot.data ?? const LoginScreen();
        },
      ),
    );
  }
}
