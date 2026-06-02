// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clima_talk/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ClimaTalkApp()));

    // Verify that our app starts.
    expect(find.text('ClimaTalk'), findsOneWidget);

    // Advance time to allow the splash screen's Future.delayed to trigger and push the next screen
    await tester.pump(const Duration(seconds: 3));
    
    // Dispose the widget tree to stop infinite animations (like AnimatedBackground) from timing out the test
    await tester.pumpWidget(Container());
  });
}
