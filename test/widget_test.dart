import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stylorista_ai/app.dart';

void main() {
  testWidgets('shows login and enters the local demo', (tester) async {
    _useMobileTestViewport(tester);
    await tester.pumpWidget(const StyloristaApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('CREATE NEW ACCOUNT'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'style@example.com');
    await tester.enterText(fields.at(1), 'fashion123');
    await tester.ensureVisible(find.text('LOG IN'));
    await tester.tap(find.text('LOG IN'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(
      find.text('Personal style, built from your real context.'),
      findsOneWidget,
    );
  });

  testWidgets('switches to create-account mode', (tester) async {
    _useMobileTestViewport(tester);
    await tester.pumpWidget(const StyloristaApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('CREATE NEW ACCOUNT'));
    await tester.tap(find.text('CREATE NEW ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('Create your profile'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(5));
  });

  testWidgets('opens the fit workflow for an authenticated session', (
    tester,
  ) async {
    await tester.pumpWidget(const StyloristaApp(initiallyAuthenticated: true));
    await tester.pumpAndSettle();

    expect(find.text('Stylorista·AI'), findsWidgets);
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

void _useMobileTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
