import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawcart/features/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders basic UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('ClawCart'), findsWidgets);
  });
}