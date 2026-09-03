import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stylorista_ai/app.dart';
import 'package:stylorista_ai/features/shop_screen.dart';
import 'package:stylorista_ai/services/session_store.dart';
import 'package:stylorista_ai/services/stylorista_api.dart';

void main() {
  testWidgets('shows login and enters the local demo', (tester) async {
    _useMobileTestViewport(tester);
    final sessionStore = MemorySessionStore();
    await tester.pumpWidget(StyloristaApp(sessionStore: sessionStore));
    await tester.pumpAndSettle();

    expect(
      find.text('See Your Size.\nKnow Your Style.\nShop With Confidence.'),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create new account'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'style@example.com');
    await tester.enterText(fields.at(1), 'fashion123');
    await tester.ensureVisible(find.byKey(const ValueKey('sign-in-button')));
    await tester.tap(find.byKey(const ValueKey('sign-in-button')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('welcome-next')));
    await tester.pumpAndSettle();

    expect(find.text('For Today’s\nWeather'), findsOneWidget);
    expect(find.text('Our Partners'), findsOneWidget);
  });

  testWidgets('returning users open Home directly', (tester) async {
    _useMobileTestViewport(tester);
    final sessionStore = MemorySessionStore(
      initialState: const SessionState(
        authenticated: true,
        welcomeCompleted: true,
      ),
    );

    await tester.pumpWidget(StyloristaApp(sessionStore: sessionStore));
    await tester.pumpAndSettle();

    expect(find.text('For Today’s\nWeather'), findsOneWidget);
    expect(find.text('Welcome to'), findsNothing);
    expect(find.byKey(const ValueKey('sign-in-button')), findsNothing);
  });

  testWidgets('switches to create-account mode', (tester) async {
    _useMobileTestViewport(tester);
    await tester.pumpWidget(StyloristaApp(sessionStore: MemorySessionStore()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create new account'));
    await tester.tap(find.text('Create new account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your profile'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(5));
  });

  testWidgets('opens the shopping workflow for an authenticated session', (
    tester,
  ) async {
    await tester.pumpWidget(
      StyloristaApp(
        initiallyAuthenticated: true,
        sessionStore: MemorySessionStore(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stylorista'), findsOneWidget);
    expect(find.text('Our Partners'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-nav-Shop')));
    await tester.pumpAndSettle();

    expect(find.text('Stylorista Shop'), findsOneWidget);
    expect(find.text('Unlock AI fit shopping'), findsOneWidget);
    expect(find.text('Shopee'), findsWidgets);
    expect(find.text('Lazada'), findsWidgets);

    await tester.tap(find.text('Measurements'));
    await tester.pumpAndSettle();

    expect(
      find.text('Measurements that fashion actually uses'),
      findsOneWidget,
    );
  });

  testWidgets('shop personalizes picks from AI scan measurements', (
    tester,
  ) async {
    _useMobileTestViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ShopScreen(
          measurements: const {
            'height': 165,
            'chest': 94,
            'waist': 77,
            'hip': 103,
          },
          sizeLabel: null,
          colorSeason: 'Autumn',
          onOpenScanner: _ignore,
          onOpenMeasurements: _ignore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your AI fit picks are ready'), findsOneWidget);
    expect(find.textContaining('Suggested size L'), findsOneWidget);
    expect(find.text('AI 96% match'), findsOneWidget);
  });

  testWidgets('news tab filters the live-style feed by fashion category', (
    tester,
  ) async {
    _useMobileTestViewport(tester);
    final api = _FakeNewsApi();
    await tester.pumpWidget(
      StyloristaApp(
        api: api,
        initiallyAuthenticated: true,
        sessionStore: MemorySessionStore(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-nav-News')));
    await tester.pumpAndSettle();

    expect(find.text('Fashion Feed'), findsOneWidget);
    expect(find.text('ALL fashion update'), findsOneWidget);
    expect(find.text('Google News'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('news-category-y2k')));
    await tester.pumpAndSettle();

    expect(api.lastCategory, 'y2k');
    expect(find.text('Y2K fashion update'), findsOneWidget);
  });

  testWidgets('opens the AI camera measurement workflow', (tester) async {
    _useMobileTestViewport(tester);
    await tester.pumpWidget(
      StyloristaApp(
        initiallyAuthenticated: true,
        sessionStore: MemorySessionStore(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-nav-Scan')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('FRONT VIEW  •  HEAD TO TOE'), findsOneWidget);
    expect(find.byTooltip('Choose photo'), findsOneWidget);
    expect(find.bySemanticsLabel('Take photo'), findsOneWidget);
  });
}

void _ignore() {}

class _FakeNewsApi extends StyloristaApi {
  String? lastCategory;

  @override
  Future<Map<String, dynamic>> fetchFashionNews({
    required String category,
    int limit = 16,
  }) async {
    lastCategory = category;
    return {
      'category': category,
      'fetched_at': DateTime.now().toUtc().toIso8601String(),
      'items': [
        {
          'id': 'post-$category',
          'title': '${category.toUpperCase()} fashion update',
          'summary': 'A current fashion story selected for $category style.',
          'url': 'https://example.com/fashion/$category',
          'image_url': null,
          'publisher': 'Fashion Test Daily',
          'platform': 'Google News',
          'category': category,
          'published_at': DateTime.now().toUtc().toIso8601String(),
          'like_count': 320,
          'comment_count': 41,
        },
      ],
      'sources': [
        {
          'name': 'Google News',
          'connected': true,
          'note': 'Live RSS stories',
        },
      ],
    };
  }
}

void _useMobileTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
