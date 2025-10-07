import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keshav_alert_aura_neww/main.dart';
import 'package:keshav_alert_aura_neww/screens/login_screen.dart';

void main() {
  testWidgets('App runs and shows LoginScreen initially',
      (WidgetTester tester) async {
    // Build the app and trigger a frame.
    // Assuming your main app class is 'AlertApp'
    await tester.pumpWidget(const AlertApp());

    // Verify that the AlertApp widget loads the LoginScreen.
    expect(find.byType(AlertApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Log in to Alert Aura'), findsOneWidget);

    // You can add more specific assertions here, e.g., checking for the phone input field.
    expect(find.byIcon(Icons.phone), findsOneWidget);
  });
}
