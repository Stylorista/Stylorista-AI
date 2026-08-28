import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stylorista_ai/app.dart';

void main() {
  testWidgets('shows the product home and opens the fit workflow', (
    tester,
  ) async {
    await tester.pumpWidget(const StyloristaApp());
    await tester.pumpAndSettle();

    expect(find.text('Stylorista·AI'), findsWidgets);
    expect(
      find.text('Personal style, built from your real context.'),
      findsOneWidget,
    );
    expect(find.text('Know your fit'), findsOneWidget);

    await tester.tap(find.text('Fit'));
    await tester.pumpAndSettle();

    expect(
      find.text('Measurements that fashion actually uses'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.straighten), findsWidgets);
  });
}
