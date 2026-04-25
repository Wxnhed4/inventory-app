import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inventory/screens/onboarding_screen.dart';

void main() {
  testWidgets('onboarding screen renders first page', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    expect(find.text('Control Kitchen Stock'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
