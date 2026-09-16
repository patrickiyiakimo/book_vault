import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vault/main.dart';
import 'package:book_vault/screens/splash_screen.dart';

void main() {
  testWidgets('BookVault app shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BookVaultApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories), findsOneWidget);
    expect(find.text('BookVault'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });
}
