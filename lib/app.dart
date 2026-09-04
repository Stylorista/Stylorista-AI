import 'dart:async';

import 'package:flutter/material.dart';

import 'features/color_analysis_screen.dart';
import 'features/auth_screen.dart';
import 'features/camera_measurement_screen.dart';
import 'features/fashion_news_screen.dart';
import 'features/home_screen.dart';
import 'features/measurements_screen.dart';
import 'features/profile_screen.dart';
import 'features/season_style_screen.dart';
import 'features/shop_screen.dart';
import 'features/welcome_screen.dart';
import 'services/session_store.dart';
import 'services/stylorista_api.dart';
import 'theme/stylorista_theme.dart';

class StyloristaApp extends StatelessWidget {
  const StyloristaApp({
    super.key,
    this.api,
    this.initiallyAuthenticated = false,
    this.sessionStore,
  });

  final StyloristaApi? api;
  final bool initiallyAuthenticated;
  final SessionStore? sessionStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FashionTech',
      debugShowCheckedModeBanner: false,
      theme: buildStyloristaTheme(),
      home: AuthGate(
        api: api ?? StyloristaApi(),
        initiallyAuthenticated: initiallyAuthenticated,
        sessionStore: sessionStore ?? PreferencesSessionStore(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.api,
    required this.sessionStore,
    this.initiallyAuthenticated = false,
  });

  final StyloristaApi api;
  final SessionStore sessionStore;
  final bool initiallyAuthenticated;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _ready = widget.initiallyAuthenticated;
  late bool _authenticated = widget.initiallyAuthenticated;
  late bool _welcomeCompleted = widget.initiallyAuthenticated;
  String? _accountToken;
  double? _referenceHeightCm;
  Map<String, double>? _measurements;
  String? _sizeLabel;

  @override
  void initState() {
    super.initState();
    if (!widget.initiallyAuthenticated) {
      _restoreSession();
    }
  }

  Future<void> _restoreSession() async {
    final startupDelay = Future<void>.delayed(const Duration(seconds: 1));
    SessionState session;
    try {
      session = await widget.sessionStore.read();
    } on Exception {
      session = const SessionState.signedOut();
    }
    if (session.authenticated && session.token == null) {
      session = const SessionState.signedOut();
      try {
        await widget.sessionStore.setAuthenticated(false);
      } on Exception {
        // Continue to the sign-in screen if legacy preferences cannot be reset.
      }
    }
    await startupDelay;
    if (!mounted) return;
    setState(() {
      _authenticated = session.authenticated;
      _welcomeCompleted = session.welcomeCompleted;
      _accountToken = session.token;
      _referenceHeightCm = session.heightCm;
      _measurements = session.measurements;
      _sizeLabel = session.sizeLabel;
      _ready = true;
    });
    final token = session.token;
    if (session.authenticated && token != null) {
      unawaited(_refreshAccountProfile(token));
    }
  }

  Future<void> _refreshAccountProfile(String token) async {
    try {
      final profile = await widget.api.fetchAccountProfile(token: token);
      final account = AccountSession.fromApi({
        'token': token,
        'profile': profile,
      });
      await widget.sessionStore.saveAccountSession(account);
      if (!mounted || _accountToken != token) return;
      setState(() {
        _referenceHeightCm = account.heightCm;
        _measurements = account.measurements;
        _sizeLabel = account.sizeLabel;
      });
    } on Exception {
      // Cached profile data keeps the app usable while the API wakes up.
    }
  }

  Future<void> _authenticate(AccountSession session, bool isNewAccount) async {
    try {
      await widget.sessionStore.saveAccountSession(session);
      await widget.sessionStore.setWelcomeCompleted(!isNewAccount);
    } on Exception {
      // The user can still enter the app if device storage is unavailable.
    }
    if (!mounted) return;
    setState(() {
      _authenticated = true;
      _welcomeCompleted = !isNewAccount;
      _accountToken = session.token;
      _referenceHeightCm = session.heightCm;
      _measurements = session.measurements;
      _sizeLabel = session.sizeLabel;
    });
  }

  Future<void> _completeWelcome() async {
    try {
      await widget.sessionStore.setWelcomeCompleted(true);
    } on Exception {
      // Continue for this session even if the preference cannot be stored.
    }
    if (!mounted) return;
    setState(() => _welcomeCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: !_ready
          ? const _SessionLoadingScreen(key: ValueKey('session-loading'))
          : !_authenticated
          ? AuthScreen(
              key: const ValueKey('auth-screen'),
              api: widget.api,
              onAuthenticated: _authenticate,
            )
          : !_welcomeCompleted
          ? WelcomeScreen(
              key: const ValueKey('welcome-screen'),
              onContinue: _completeWelcome,
            )
          : StyloristaShell(
              key: const ValueKey('app-shell'),
              api: widget.api,
              sessionStore: widget.sessionStore,
              accountToken: _accountToken,
              referenceHeightCm: _referenceHeightCm,
              initialMeasurements: _measurements,
              initialSizeLabel: _sizeLabel,
            ),
    );
  }
}

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF7F0E9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOutCubic,
              builder: (context, value, child) => Transform.rotate(
                angle: value * 6.283,
                child: Transform.scale(
                  scale: 0.9 + (value * 0.1),
                  child: child,
                ),
              ),
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: StyloristaColors.sand, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2B573326),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF8A5A40),
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Styling your next look…',
              style: TextStyle(
                color: Color(0xFF573326),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StyloristaShell extends StatefulWidget {
  const StyloristaShell({
    super.key,
    required this.api,
    required this.sessionStore,
    this.accountToken,
    this.referenceHeightCm,
    this.initialMeasurements,
    this.initialSizeLabel,
  });

  final StyloristaApi api;
  final SessionStore sessionStore;
  final String? accountToken;
  final double? referenceHeightCm;
  final Map<String, double>? initialMeasurements;
  final String? initialSizeLabel;

  @override
  State<StyloristaShell> createState() => _StyloristaShellState();
}

class _StyloristaShellState extends State<StyloristaShell> {
  int _selectedIndex = 0;
  late String? _sizeLabel = widget.initialSizeLabel;
  String? _colorSeason;
  late Map<String, double>? _scannedMeasurements = widget.initialMeasurements;

  void _selectPage(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _saveScanMeasurements(Map<String, double> values) async {
    setState(() => _scannedMeasurements = values);
    var savedSize = _sizeLabel;
    try {
      final result = await widget.api.recommendSize(
        measurements: values,
        fitPreference: 'regular',
      );
      savedSize = result['recommended_size'] as String;
      if (mounted) {
        setState(() => _sizeLabel = savedSize);
      }
    } on ApiException {
      // The scan remains useful even if the optional size follow-up is offline.
    }
    try {
      await widget.sessionStore.saveMeasurementProfile(values, savedSize);
      final token = widget.accountToken;
      if (token != null) {
        await widget.api.saveAccountMeasurements(
          token: token,
          measurements: values,
          sizeLabel: savedSize,
        );
      }
    } on Exception {
      // Keep the accepted measurements on screen if cloud sync is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        api: widget.api,
        onSelectFeature: _selectPage,
        sizeLabel: _sizeLabel,
        colorSeason: _colorSeason,
      ),
      ShopScreen(
        measurements: _scannedMeasurements,
        sizeLabel: _sizeLabel,
        colorSeason: _colorSeason,
        onOpenScanner: () => _selectPage(2),
        onOpenMeasurements: () => _selectPage(5),
      ),
      CameraMeasurementScreen(
        api: widget.api,
        active: _selectedIndex == 2,
        referenceHeightCm: widget.referenceHeightCm,
        onBack: () => _selectPage(0),
        onMeasurementsReady: _saveScanMeasurements,
        onColorSeasonAnalyzed: (value) => setState(() => _colorSeason = value),
        onOpenShop: () => _selectPage(1),
      ),
      FashionNewsScreen(api: widget.api, active: _selectedIndex == 3),
      ProfileScreen(
        api: widget.api,
        sizeLabel: _sizeLabel,
        colorSeason: _colorSeason,
        onOpenFit: () => _selectPage(2),
        onOpenWeather: () => _selectPage(7),
        onOpenColorAnalysis: () => _selectPage(6),
        onColorSeasonAnalyzed: (value) => setState(() => _colorSeason = value),
      ),
      MeasurementsScreen(
        api: widget.api,
        initialMeasurements: _scannedMeasurements,
        onSizeRecommended: (value) => setState(() => _sizeLabel = value),
      ),
      ColorAnalysisScreen(
        api: widget.api,
        onSeasonAnalyzed: (value) => setState(() => _colorSeason = value),
      ),
      SeasonStyleScreen(
        api: widget.api,
        sizeLabel: _sizeLabel,
        colorSeason: _colorSeason,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final content = IndexedStack(
          index: _selectedIndex,
          children: [
            screens.first,
            for (final screen in screens.skip(1)) SafeArea(child: screen),
          ],
        );
        if (wide) {
          return Scaffold(
            backgroundColor: _selectedIndex == 0
                ? StyloristaColors.sand
                : StyloristaColors.cream,
            body: Row(
              children: [
                _DesktopNavigation(
                  selectedIndex: _selectedIndex,
                  onSelect: _selectPage,
                ),
                Expanded(child: content),
              ],
            ),
          );
        }
        return Scaffold(
          extendBody: false,
          resizeToAvoidBottomInset: true,
          backgroundColor: _selectedIndex == 0
              ? StyloristaColors.sand
              : StyloristaColors.cream,
          body: content,
          bottomNavigationBar: _selectedIndex == 2
              ? null
              : _BottomNavigation(
                  selectedIndex: _selectedIndex,
                  onSelect: _selectPage,
                ),
        );
      },
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _destinations = [
    (
      label: 'Home',
      screenIndex: 0,
      icon: Icons.home_outlined,
      selected: Icons.home_rounded,
    ),
    (
      label: 'Shop',
      screenIndex: 1,
      icon: Icons.shopping_cart_outlined,
      selected: Icons.shopping_cart_rounded,
    ),
    (
      label: 'News',
      screenIndex: 3,
      icon: Icons.newspaper_outlined,
      selected: Icons.newspaper_rounded,
    ),
    (
      label: 'Profile',
      screenIndex: 4,
      icon: Icons.person_outline_rounded,
      selected: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: 92 + bottomInset,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 10,
            right: 10,
            bottom: 6 + bottomInset,
            height: 66,
            child: Material(
              color: Colors.white,
              elevation: 10,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  for (final destination in _destinations.take(2))
                    Expanded(
                      child: _BottomNavigationItem(
                        key: ValueKey('home-nav-${destination.label}'),
                        label: destination.label,
                        icon: selectedIndex == destination.screenIndex
                            ? destination.selected
                            : destination.icon,
                        selected: selectedIndex == destination.screenIndex,
                        onTap: () => onSelect(destination.screenIndex),
                      ),
                    ),
                  const SizedBox(width: 78),
                  for (final destination in _destinations.skip(2))
                    Expanded(
                      child: _BottomNavigationItem(
                        key: ValueKey('home-nav-${destination.label}'),
                        label: destination.label,
                        icon: selectedIndex == destination.screenIndex
                            ? destination.selected
                            : destination.icon,
                        selected: selectedIndex == destination.screenIndex,
                        onTap: () => onSelect(destination.screenIndex),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 2,
            child: Semantics(
              button: true,
              selected: selectedIndex == 2,
              label: 'Scan',
              child: Tooltip(
                message: 'AI body scan',
                child: Material(
                  key: const ValueKey('home-nav-Scan'),
                  color: selectedIndex == 2
                      ? StyloristaColors.sand
                      : Colors.white,
                  elevation: 12,
                  shadowColor: Colors.black38,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onSelect(2),
                    customBorder: const CircleBorder(),
                    child: SizedBox.square(
                      dimension: 80,
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 43,
                        color: selectedIndex == 2
                            ? Colors.white
                            : StyloristaColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationItem extends StatelessWidget {
  const _BottomNavigationItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: selected ? 48 : 42,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? StyloristaColors.sand.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  scale: selected ? 1.08 : 1,
                  child: Icon(
                    icon,
                    size: 30,
                    color: selected
                        ? StyloristaColors.sandText
                        : Colors.black.withValues(alpha: 0.66),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: StyloristaColors.ink,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _BrandMark(light: true),
          ),
          const SizedBox(height: 42),
          _NavItem(
            index: 0,
            icon: Icons.home_outlined,
            label: 'Home',
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),
          _NavItem(
            index: 1,
            icon: Icons.shopping_cart_outlined,
            label: 'Shop',
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),
          _NavItem(
            index: 2,
            icon: Icons.photo_camera_outlined,
            label: 'AI body scan',
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),
          _NavItem(
            index: 3,
            icon: Icons.newspaper_outlined,
            label: 'Fashion news',
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),
          _NavItem(
            index: 4,
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),
          const Spacer(),
          Text(
            'Private by design\nPrototype · v0.1',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.58),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int index;
  final IconData icon;
  final String label;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onSelect(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: selected ? Colors.white : Colors.white60),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.light});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : StyloristaColors.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: StyloristaColors.berry,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text(
            'F',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Fashion',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              TextSpan(
                text: 'Tech',
                style: TextStyle(
                  color: StyloristaColors.berry,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
