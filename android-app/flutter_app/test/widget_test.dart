import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttime_ai/features/auth/auth_gate.dart';

void main() {
  testWidgets('Sign-in panel renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SignInPanel())));
    expect(find.text('Sign in to SmartTime AI'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
