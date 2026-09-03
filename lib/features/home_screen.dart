import 'package:flutter/material.dart';

import '../theme/stylorista_theme.dart';

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
    return ColoredBox(
      color: StyloristaColors.sand,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _HeroCard(onTap: () => onSelectFeature(4)),
            _Partners(onSelectFeature: onSelectFeature),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(26, safeTop + 28, 26, 27),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(21),
          bottomRight: Radius.circular(21),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              const _Wordmark(),
              const SizedBox(height: 31),
              Semantics(
                button: true,
                label: 'See style suggestions for today\'s weather',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(15),
                    child: Ink(
                      height: 202,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/home_hero.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 258,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: const Text(
                            'For Today’s\nWeather',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: StyloristaColors.sandText,
                              fontSize: 37,
                              height: 1.12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Stylorista',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
              fontSize: 52,
              height: 1,
              fontWeight: FontWeight.w300,
              letterSpacing: -2.2,
            ),
          ),
          const SizedBox(width: 13),
          Container(width: 53, height: 1.2, color: Colors.black87),
          const SizedBox(width: 13),
          const Text(
            'AI',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'serif',
              fontSize: 45,
              height: 1,
              fontWeight: FontWeight.w300,
              letterSpacing: -1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Partners extends StatelessWidget {
  const _Partners({required this.onSelectFeature});

  final ValueChanged<int> onSelectFeature;

  static const _items = [
    _PartnerItem(
      label: 'Fit wardrobe',
      alignment: Alignment.topLeft,
      featureIndex: 1,
    ),
    _PartnerItem(
      label: 'Personal colors',
      alignment: Alignment.topRight,
      featureIndex: 6,
    ),
    _PartnerItem(
      label: 'Styled looks',
      alignment: Alignment.bottomLeft,
      featureIndex: 4,
    ),
    _PartnerItem(
      label: 'Capsule wardrobe',
      alignment: Alignment.bottomRight,
      featureIndex: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 22),
      child: Column(
        children: [
          const Text(
            'Our Partners',
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 34),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 302),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 48,
                  mainAxisSpacing: 17,
                ),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _PartnerTile(
                    item: item,
                    onTap: () => onSelectFeature(item.featureIndex),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerItem {
  const _PartnerItem({
    required this.label,
    required this.alignment,
    required this.featureIndex,
  });

  final String label;
  final Alignment alignment;
  final int featureIndex;
}

class _PartnerTile extends StatelessWidget {
  const _PartnerTile({required this.item, required this.onTap});

  final _PartnerItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _CollageQuadrant(alignment: item.alignment),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollageQuadrant extends StatelessWidget {
  const _CollageQuadrant({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: OverflowBox(
            alignment: alignment,
            minWidth: constraints.maxWidth * 2,
            maxWidth: constraints.maxWidth * 2,
            minHeight: constraints.maxHeight * 2,
            maxHeight: constraints.maxHeight * 2,
            child: Image.asset(
              'assets/images/partner_collage.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        );
      },
    );
  }
}
