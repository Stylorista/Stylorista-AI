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

  testWidgets('home shows current weather, tomorrow, and relevant fashion', (
    tester,
  ) async {
    _useMobileTestViewport(tester);
    await tester.pumpWidget(
      StyloristaApp(
        api: _FakeNewsApi(),
        initiallyAuthenticated: true,
        sessionStore: MemorySessionStore(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weather now'), findsOneWidget);
    expect(find.text('Partly cloudy'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Rain showers'), findsOneWidget);
    expect(find.text('Your relevant fashion'), findsOneWidget);
    expect(find.text('Airy warm-weather layers'), findsOneWidget);
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
    expect(find.text('For your size L'), findsWidgets);
    expect(find.text('Live prices & stock'), findsWidgets);
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

  testWidgets('profile tab opens the curated feature hub', (tester) async {
    _useMobileTestViewport(tester);
    await tester.pumpWidget(
      StyloristaApp(
        initiallyAuthenticated: true,
        sessionStore: MemorySessionStore(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-nav-Profile')));
    await tester.pumpAndSettle();

    expect(find.text('Curated for you!'), findsOneWidget);
    expect(find.text('Will it Fit?'), findsOneWidget);
    expect(find.text('In-the-Weather'), findsOneWidget);
    expect(find.text('Accessories'), findsOneWidget);
    expect(find.text('Color Analysis'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-weather')));
    await tester.pumpAndSettle();
    expect(find.text('Today’s context'), findsOneWidget);
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
        {'name': 'Google News', 'connected': true, 'note': 'Live RSS stories'},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> fetchHomeWeather({
    required String city,
    String? sizeLabel,
    String? colorSeason,
  }) async {
    return _homeWeatherResponse(city);
  }
}

Map<String, dynamic> _homeWeatherResponse(String city) => {
  'location': city,
  'region': 'Metro Manila',
  'country': 'Philippines',
  'timezone': 'Asia/Manila',
  'updated_at': DateTime.now().toUtc().toIso8601String(),
  'current': {
    'temperature_c': 30.0,
    'apparent_temperature_c': 35.0,
    'humidity_percent': 74,
    'wind_kmh': 12.0,
    'weather_code': 2,
    'condition': 'Partly cloudy',
    'is_day': true,
  },
  'tomorrow': {
    'date': '2026-09-04',
    'temperature_max_c': 31.0,
    'temperature_min_c': 25.0,
    'apparent_temperature_max_c': 36.0,
    'precipitation_probability': 58,
    'uv_index_max': 7.2,
    'weather_code': 80,
    'condition': 'Rain showers',
  },
  'fashion': [
    {
      'kind': 'outfit',
      'title': 'Airy warm-weather layers',
      'reason': 'Breathable pieces for today.',
    },
    {
      'kind': 'weather',
      'title': 'Rain-ready finishing pieces',
      'reason': 'Carry a compact umbrella.',
    },
    {
      'kind': 'fit',
      'title': 'Your fit starting point',
      'reason': 'Complete a body scan.',
    },
    {
      'kind': 'color',
      'title': 'Your color accent',
      'reason': 'Add your saved color profile.',
    },
  ],
  'source': 'Open-Meteo forecast',
};

void _useMobileTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
