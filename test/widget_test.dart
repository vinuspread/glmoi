// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';

import 'package:app_admin/core/theme/app_theme.dart';
import 'package:app_admin/core/widgets/admin_background.dart';

void main() {
  testWidgets('AdminBackground renders child', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: AdminBackground(child: Text('hello'))),
      ),
    );

    expect(find.text('hello'), findsOneWidget);
  });
}
