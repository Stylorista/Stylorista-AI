import 'package:flutter/material.dart';

import 'features/color_analysis_screen.dart';
import 'features/auth_screen.dart';
import 'features/camera_measurement_screen.dart';
import 'features/home_screen.dart';
import 'features/measurements_screen.dart';
import 'features/season_style_screen.dart';
import 'services/stylorista_api.dart';
import 'theme/stylorista_theme.dart';

class StyloristaApp extends StatelessWidget {
  const StyloristaApp({
    super.key,
    this.api,
    this.initiallyAuthenticated = false,
  });

  final StyloristaApi? api;
  final bool initiallyAuthenticated;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stylorista-AI',
      debugShowCheckedModeBanner: false,
      theme: buildStyloristaTheme(),
      home: AuthGate(
        api: api ?? StyloristaApi(),
        initiallyAuthenticated: initiallyAuthenticated,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.api,
    this.initiallyAuthenticated = false,
  });

  final StyloristaApi api;
  final bool initiallyAuthenticated;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _authenticated = widget.initiallyAuthenticated;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _authenticated
          ? StyloristaShell(key: const ValueKey('app-shell'), api: widget.api)
          : AuthScreen(
              key: const ValueKey('auth-screen'),
              onAuthenticated: () => setState(() => _authenticated = true),
            ),
    );
  }
}

class StyloristaShell extends StatefulWidget {
  const StyloristaShell({super.key, required this.api});

  final StyloristaApi api;

  @override
  State<StyloristaShell> createState() => _StyloristaShellState();
}

class _StyloristaShellState extends State<StyloristaShell> {
  int _selectedIndex = 0;
  String? _sizeLabel;
  String? _colorSeason;
  Map<String, double>? _scannedMeasurements;

  void _selectPage(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onSelectFeature: _selectPage,
        sizeLabel: _sizeLabel,
        colorSeason: _colorSeason,
      ),
      MeasurementsScreen(
        api: widget.api,
        initialMeasurements: _scannedMeasurements,
        onSizeRecommended: (value) => setState(() => _sizeLabel = value),
      ),
      CameraMeasurementScreen(
        api: widget.api,
        active: _selectedIndex == 2,
        onBack: () => _selectPage(0),
        onMeasurementsReady: (values) =>
            setState(() => _scannedMeasurements = values),
        onOpenFit: () => _selectPage(1),
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
          backgroundColor: _selectedIndex == 0
              ? StyloristaColors.sand
              : StyloristaColors.cream,
          body: content,
          bottomNavigationBar: _BottomNavigation(
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
      label: 'Fit',
      screenIndex: 1,
      icon: Icons.shopping_cart_outlined,
      selected: Icons.shopping_cart_rounded,
    ),
    (
      label: 'Colors',
      screenIndex: 3,
      icon: Icons.newspaper_outlined,
      selected: Icons.newspaper_rounded,
    ),
    (
      label: 'Style',
      screenIndex: 4,
      icon: Icons.person_outline_rounded,
      selected: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: 116 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 11,
            right: 11,
            bottom: 8 + bottomInset,
            height: 74,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
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
                  const SizedBox(width: 104),
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
            top: 0,
            child: Semantics(
              button: true,
              selected: selectedIndex == 2,
              label: 'Scan',
              child: Tooltip(
                message: 'AI body scan',
                child: Material(
                  key: const ValueKey('home-nav-Scan'),
                  color: Colors.white,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onSelect(2),
                    customBorder: const CircleBorder(),
                    child: const SizedBox.square(
                      dimension: 112,
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 70,
                        color: Colors.black,
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
        child: InkResponse(
          onTap: onTap,
          radius: 31,
          child: SizedBox.expand(
            child: Icon(
              icon,
              size: 37,
              color: selected
                  ? Colors.black
                  : Colors.black.withValues(alpha: 0.78),
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
            icon: Icons.straighten_outlined,
            label: 'My fit',
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
            icon: Icons.palette_outlined,
            label: 'My colors',
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),
          _NavItem(
            index: 4,
            icon: Icons.checkroom_outlined,
            label: 'Seasonal style',
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
            'S',
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
                text: 'Stylorista',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              TextSpan(
                text: '·AI',
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
