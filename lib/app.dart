import 'package:flutter/material.dart';

import 'features/color_analysis_screen.dart';
import 'features/home_screen.dart';
import 'features/measurements_screen.dart';
import 'features/season_style_screen.dart';
import 'services/stylorista_api.dart';
import 'theme/stylorista_theme.dart';

class StyloristaApp extends StatelessWidget {
  const StyloristaApp({super.key, this.api});

  final StyloristaApi? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stylorista-AI',
      debugShowCheckedModeBanner: false,
      theme: buildStyloristaTheme(),
      home: StyloristaShell(api: api ?? StyloristaApi()),
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
        final content = SafeArea(
          child: IndexedStack(index: _selectedIndex, children: screens),
        );
        if (wide) {
          return Scaffold(
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
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectPage,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.straighten_outlined),
                selectedIcon: Icon(Icons.straighten),
                label: 'Fit',
              ),
              NavigationDestination(
                icon: Icon(Icons.palette_outlined),
                selectedIcon: Icon(Icons.palette),
                label: 'Color',
              ),
              NavigationDestination(
                icon: Icon(Icons.checkroom_outlined),
                selectedIcon: Icon(Icons.checkroom),
                label: 'Style',
              ),
            ],
          ),
        );
      },
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
            icon: Icons.palette_outlined,
            label: 'My colors',
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),
          _NavItem(
            index: 3,
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
