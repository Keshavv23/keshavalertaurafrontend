import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for HapticFeedback
import '../services/api_service.dart' as api;
import 'login_screen.dart';
import 'add_emergency_contact_screen.dart';

import 'package:geolocator/geolocator.dart';
import 'package:shake/shake.dart';
import 'dart:async'; // Required for Timer

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSosActive = false;
  late final ShakeDetector _detector;
  Timer? _shakeDebounceTimer;

  // State Variables for Timer/Cancellation
  Timer? _sosTimer;
  int _countdown = 10;
  bool _isWarningVisible = false;

  // --- SHAKE DETECTION LOGIC ---
  void _onShakeDetected(ShakeEvent event) {
    // Debounce to prevent multiple triggers from one shake
    if (_shakeDebounceTimer?.isActive ?? false) return;
    _shakeDebounceTimer = Timer(const Duration(seconds: 5), () {
      _shakeDebounceTimer = null;
    });

    if (mounted && !_isWarningVisible) {
      // Vibrate and start the warning
      HapticFeedback.vibrate();
      _showSosWarningDialog();
    }
  }

  // --- LIFECYCLE MANAGEMENT ---
  @override
  void initState() {
    super.initState();
    _detector = ShakeDetector.waitForStart(
      onPhoneShake: _onShakeDetected,
      shakeThresholdGravity: 2.7,
      shakeSlopTimeMS: 500,
    );
    _detector.startListening();
  }

  @override
  void dispose() {
    _detector.stopListening();
    _shakeDebounceTimer?.cancel();
    _sosTimer?.cancel(); // Ensure the SOS timer is cancelled
    super.dispose();
  }

  // --- UTILITIES ---
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

  void _cancelSos() {
    _sosTimer?.cancel();
    _countdown = 10; // Reset countdown
    if (_isWarningVisible) {
      // Dismiss the dialog
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _isWarningVisible = false;
      });
      _showSnackbar('SOS Alert Cancelled.', Colors.blueGrey);
    }
  }

  // --- DIALOG & TIMER LOGIC ---
  void _showSosWarningDialog() {
    if (_isWarningVisible) return; // Prevent double dialog

    setState(() {
      _isWarningVisible = true;
      _countdown = 10; // Start the timer from 10
    });

    HapticFeedback.heavyImpact(); // Vibrate to confirm action

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // StatefulBuilder is necessary to update the countdown text inside the dialog
        return StatefulBuilder(
          builder: (context, setStateSB) {
            _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (!mounted) {
                timer.cancel();
                return;
              }
              setStateSB(() {
                _countdown--;
              });
              if (_countdown < 0) {
                timer.cancel();
                // When timer reaches zero, trigger the final alert action
                _handleSosAlert(shouldPopDialog: true);
              }
            });

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('EMERGENCY ALERT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SOS will be sent in...',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_countdown < 0 ? 0 : _countdown}', // Show 0 if negative
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      color: _countdown <= 3 ? Colors.red : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Press CANCEL to stop the alert.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              actions: <Widget>[
                Center(
                  child: ElevatedButton(
                    onPressed: _cancelSos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'CANCEL',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Ensure state is reset if dialog is dismissed for any reason
      _isWarningVisible = false;
      _sosTimer?.cancel();
    });
  }

  // --- SOS ALERT HANDLING (FINAL ACTION) ---
  Future<void> _handleSosAlert({bool shouldPopDialog = false}) async {
    // If called from the button press or shake but warning is not visible, show the warning first.
    if (!_isWarningVisible && !shouldPopDialog) {
      _showSosWarningDialog();
      return;
    }

    // This section runs ONLY when the timer hits zero (shouldPopDialog is true).
    _sosTimer?.cancel();

    if (shouldPopDialog && mounted) {
      // Dismiss the warning dialog before starting the location process
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _isWarningVisible = false;
      });
    }

    if (_isSosActive) return;

    setState(() {
      _isSosActive = true;
    });

    try {
      // 1. Location Permission Check (Standard Geolocator logic)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          _showSnackbar(
              'Location permission denied. SOS failed.', Colors.orange);
          return;
        }
      }

      _showSnackbar('Getting location and sending alert...', Colors.red);

      // 2. Get Current Position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // 3. Send Alert to API (Will be updated for Feature 3 later)
      final result = await api.ApiService().sendSosAlert(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (result == null) {
        _showSnackbar('SOS Alert Sent Successfully!', Colors.green);
      } else {
        _showSnackbar('SOS failed: $result', Colors.red);
      }
    } on TimeoutException {
      _showSnackbar('Failed to get location in time. SOS failed.', Colors.red);
    } catch (e) {
      _showSnackbar('An unexpected error occurred: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isSosActive = false;
        });
      }
    }
  }

  // --- LOGOUT & NAVIGATION ---
  Future<void> _logout() async {
    await api.ApiService().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // --- WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final buttonSize = size.width * 0.7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KeshavAlertAura'),
        actions: [
          IconButton(
            icon: Icon(Icons.group_add, color: Colors.red.shade700),
            tooltip: 'Manage Contacts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddEmergencyContactScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red.shade700),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Press the button below or shake your phone vigorously to start the 10-second alert countdown.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 60),

              // 🚨 CIRCULAR SOS BUTTON (UI/UX)
              Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  // Button calls _handleSosAlert, which initiates the warning dialog
                  onPressed: _isSosActive || _isWarningVisible
                      ? null
                      : () => _handleSosAlert(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isSosActive ? Colors.grey : Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    elevation: 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isSosActive
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 4),
                            )
                          : const Icon(Icons.warning_amber_rounded, size: 70),
                      const SizedBox(height: 10),
                      Text(
                        _isSosActive ? 'Sending...' : 'SOS',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
