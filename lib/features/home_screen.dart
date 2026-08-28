import 'package:flutter/material.dart';

import '../theme/stylorista_theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onSelectFeature,
    required this.sizeLabel,
    required this.colorSeason,
  });

  final ValueChanged<int> onSelectFeature;
  final String? sizeLabel;
  final String? colorSeason;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MobileBrand(),
              const SizedBox(height: 24),
              _Hero(onStart: () => onSelectFeature(1)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _FeatureCard(
                    number: '01',
                    icon: Icons.straighten,
                    title: 'Know your fit',
                    description:
                        'Record fashion-specific measurements and get a transparent starting-size recommendation.',
                    status: sizeLabel == null
                        ? 'Not started'
                        : 'Size $sizeLabel',
                    color: StyloristaColors.plum,
                    onTap: () => onSelectFeature(1),
                  ),
                  _FeatureCard(
                    number: '02',
                    icon: Icons.palette,
                    title: 'Find your colors',
                    description:
                        'Explore a four-season palette using skin, hair and eye color samples.',
                    status: colorSeason ?? 'Not started',
                    color: StyloristaColors.gold,
                    onTap: () => onSelectFeature(2),
                  ),
                  _FeatureCard(
                    number: '03',
                    icon: Icons.wb_cloudy_outlined,
                    title: 'Dress for now',
                    description:
                        'Match climate, season, occasion and personal style to a practical outfit system.',
                    status: 'Ready',
                    color: StyloristaColors.moss,
                    onTap: () => onSelectFeature(3),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const NoticeCard(
                icon: Icons.shield_outlined,
                text:
                    'MVP privacy promise: this interface sends typed measurements and selected color values to your configured API. It does not upload a body or face photo.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileBrand extends StatelessWidget {
  const _MobileBrand();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 850) return const SizedBox.shrink();
        return Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: StyloristaColors.berry,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: const Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Stylorista·AI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: StyloristaColors.ink,
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D1A1B), Color(0xFF462338)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 30,
        runSpacing: 24,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIT · TONE · SEASON · YOU',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFE6B1C5),
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Personal style, built from your real context.',
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Stylorista-AI combines fit guidance, personal color and climate-aware dressing—then explains every recommendation.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: StyloristaColors.ink,
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Build my style profile'),
                ),
              ],
            ),
          ),
          const _Monogram(),
        ],
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(80),
          topRight: Radius.circular(80),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      alignment: Alignment.center,
      child: const Text(
        'S',
        style: TextStyle(
          color: Colors.white,
          fontSize: 84,
          height: 1,
          fontWeight: FontWeight.w200,
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.color,
    required this.onTap,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;
  final String status;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 330,
      height: 250,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const Spacer(),
                    Text(
                      number,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(description, maxLines: 3, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
