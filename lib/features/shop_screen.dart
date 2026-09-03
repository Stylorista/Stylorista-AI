import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/stylorista_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.measurements,
    required this.sizeLabel,
    required this.colorSeason,
    required this.onOpenScanner,
    required this.onOpenMeasurements,
  });

  final Map<String, double>? measurements;
  final String? sizeLabel;
  final String? colorSeason;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenMeasurements;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _query = '';
  String _category = 'All';

  static const _categories = ['All', 'Tops', 'Bottoms', 'Dresses', 'Outerwear'];

  static const _catalog = [
    _ShopItem(
      title: 'Relaxed linen blouse',
      category: 'Tops',
      searchTerms: 'women relaxed linen blouse',
      imageAlignment: Alignment.topLeft,
      fitReason: 'Easy shoulder and sleeve fit',
    ),
    _ShopItem(
      title: 'High-rise wide-leg trousers',
      category: 'Bottoms',
      searchTerms: 'women high waist wide leg trousers',
      imageAlignment: Alignment.topRight,
      fitReason: 'Waist-to-hip friendly cut',
    ),
    _ShopItem(
      title: 'Adjustable wrap midi dress',
      category: 'Dresses',
      searchTerms: 'women adjustable wrap midi dress',
      imageAlignment: Alignment.bottomLeft,
      fitReason: 'Adjustable natural waist',
    ),
    _ShopItem(
      title: 'Lightweight tailored blazer',
      category: 'Outerwear',
      searchTerms: 'women lightweight tailored blazer',
      imageAlignment: Alignment.bottomRight,
      fitReason: 'Balanced shoulder structure',
    ),
    _ShopItem(
      title: 'Soft ribbed everyday top',
      category: 'Tops',
      searchTerms: 'women soft ribbed fitted top',
      imageAlignment: Alignment.topRight,
      fitReason: 'Flexible bust and waist fit',
    ),
    _ShopItem(
      title: 'Straight-leg everyday jeans',
      category: 'Bottoms',
      searchTerms: 'women straight leg high waist jeans',
      imageAlignment: Alignment.bottomRight,
      fitReason: 'Room through hip and inseam',
    ),
  ];

  bool get _hasProfile =>
      widget.measurements != null ||
      (widget.sizeLabel != null && widget.sizeLabel!.trim().isNotEmpty);

  String get _recommendedSize {
    final savedSize = widget.sizeLabel?.trim();
    if (savedSize != null && savedSize.isNotEmpty) return savedSize;
    final values = widget.measurements;
    if (values == null) return '—';
    final chest = values['chest'] ?? 0;
    final hip = values['hip'] ?? 0;
    final largest = chest > hip ? chest : hip;
    if (largest < 84) return 'XS';
    if (largest < 92) return 'S';
    if (largest < 100) return 'M';
    if (largest < 110) return 'L';
    if (largest < 120) return 'XL';
    return '2XL';
  }

  String get _colorCue {
    final season = widget.colorSeason?.toLowerCase();
    if (season == null || season.isEmpty) return 'neutral colors';
    if (season.contains('spring')) return 'warm spring colors';
    if (season.contains('summer')) return 'soft summer colors';
    if (season.contains('autumn')) return 'earthy autumn colors';
    if (season.contains('winter')) return 'clear winter colors';
    return '$season colors';
  }

  List<_ShopItem> get _visibleItems {
    final normalizedQuery = _query.trim().toLowerCase();
    final items = _catalog.where((item) {
      final categoryMatches = _category == 'All' || item.category == _category;
      final queryMatches =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.category.toLowerCase().contains(normalizedQuery);
      return categoryMatches && queryMatches;
    }).toList();
    if (!_hasProfile) return items;
    items.sort((left, right) {
      return _personalFitScore(right).compareTo(_personalFitScore(left));
    });
    return items;
  }

  int _personalFitScore(_ShopItem item) {
    final measurements = widget.measurements;
    if (measurements == null) return 0;
    final chest = measurements['chest'] ?? 0;
    final waist = measurements['waist'] ?? 0;
    final hip = measurements['hip'] ?? 0;
    var score = 0;
    if (hip > chest * 1.06 && item.category == 'Tops') score += 3;
    if (chest > hip * 1.06 && item.category == 'Bottoms') score += 3;
    if ((hip - waist).abs() > 14 && item.category == 'Dresses') score += 4;
    if ((chest - hip).abs() < 7 && item.category == 'Outerwear') score += 2;
    if (item.searchTerms.contains('adjustable')) score += 2;
    return score;
  }

  Future<void> _openMarketplace(
    _Marketplace marketplace,
    _ShopItem item,
  ) async {
    final sizeTerm = _hasProfile ? ' size $_recommendedSize' : '';
    final query = '${item.searchTerms}$sizeTerm $_colorCue philippines';
    final uri = marketplace == _Marketplace.shopee
        ? Uri.https('shopee.ph', '/search', {'keyword': query})
        : Uri.https('www.lazada.com.ph', '/catalog/', {'q': query});
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!opened && mounted) _showLinkError();
    } on Exception {
      if (mounted) _showLinkError();
    }
  }

  void _showLinkError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The shopping link could not be opened on this device.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    return Material(
      color: const Color(0xFFF7F4EF),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ShopHeader(
              onSearchChanged: (value) => setState(() => _query = value),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _AiFitBanner(
                hasProfile: _hasProfile,
                size: _recommendedSize,
                measurements: widget.measurements,
                colorSeason: widget.colorSeason,
                onOpenScanner: widget.onOpenScanner,
                onOpenMeasurements: widget.onOpenMeasurements,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 72,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = _category == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = category),
                    selectedColor: StyloristaColors.sand,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : StyloristaColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: StyloristaColors.sand.withValues(alpha: 0.35),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recommended for you',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text('${items.length} picks'),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No fashion matches found.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.crossAxisExtent >= 920
                      ? 4
                      : constraints.crossAxisExtent >= 620
                      ? 3
                      : 2;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 11,
                      mainAxisSpacing: 12,
                      childAspectRatio: columns == 2 ? 0.60 : 0.66,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = items[index];
                      return _ProductCard(
                        item: item,
                        size: _recommendedSize,
                        hasProfile: _hasProfile,
                        onShopee: () =>
                            _openMarketplace(_Marketplace.shopee, item),
                        onLazada: () =>
                            _openMarketplace(_Marketplace.lazada, item),
                      );
                    }, childCount: items.length),
                  );
                },
              ),
            ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(22, 0, 22, 28),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Each card is a personalized outfit search, not a copied or sponsored listing. Shopee and Lazada buttons open their current stock and prices using your saved size and color profile. Always check the seller’s size chart.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.onSearchChanged});

  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: StyloristaColors.sand,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Stylorista Shop',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.favorite_border_rounded, color: Colors.white),
              SizedBox(width: 16),
              Icon(Icons.notifications_none_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('shop-search'),
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search your AI fashion picks',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: const Icon(Icons.tune_rounded),
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFitBanner extends StatelessWidget {
  const _AiFitBanner({
    required this.hasProfile,
    required this.size,
    required this.measurements,
    required this.colorSeason,
    required this.onOpenScanner,
    required this.onOpenMeasurements,
  });

  final bool hasProfile;
  final String size;
  final Map<String, double>? measurements;
  final String? colorSeason;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenMeasurements;

  @override
  Widget build(BuildContext context) {
    final waist = measurements?['waist'];
    final hip = measurements?['hip'];
    final profileDetails = waist != null && hip != null
        ? 'Waist ${waist.toStringAsFixed(0)} cm  •  Hip ${hip.toStringAsFixed(0)} cm'
        : 'Add measurements for more accurate matches';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF573326), Color(0xFF8A5A40)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(
                  hasProfile
                      ? Icons.auto_awesome_rounded
                      : Icons.photo_camera_rounded,
                  color: StyloristaColors.sandText,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasProfile
                          ? 'Your AI fit picks are ready'
                          : 'Unlock AI fit shopping',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasProfile
                          ? 'Suggested size $size  •  ${colorSeason ?? 'Color profile not set'}\n$profileDetails\nEvery button opens current marketplace results for this profile.'
                          : 'Add a verified body profile so Stylorista can rank outfit searches for your proportions and open live marketplace results.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('shop-open-scan'),
                  onPressed: onOpenScanner,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF573326),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.photo_camera_outlined, size: 19),
                  label: Text(hasProfile ? 'Update scan' : 'Take photo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenMeasurements,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white60),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.straighten_rounded, size: 19),
                  label: const Text('Measurements'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.size,
    required this.hasProfile,
    required this.onShopee,
    required this.onLazada,
  });

  final _ShopItem item;
  final String size;
  final bool hasProfile;
  final VoidCallback onShopee;
  final VoidCallback onLazada;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('shop-product-${item.title}'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 50,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CollageCrop(alignment: item.imageAlignment),
                Positioned(
                  left: 8,
                  top: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF513225).withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: Text(
                        hasProfile
                            ? 'For your size $size'
                            : 'Live style search',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: 8,
                  top: 7,
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.favorite_border_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 50,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hasProfile
                        ? '${item.fitReason}  •  Size $size'
                        : item.fitReason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10.5,
                    ),
                  ),
                  const Spacer(),
                  const Row(
                    children: [
                      Icon(
                        Icons.sync_rounded,
                        size: 15,
                        color: Color(0xFF2E7D32),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Live prices & stock',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _MarketButton(
                          label: 'Shopee',
                          color: const Color(0xFFEE4D2D),
                          onPressed: onShopee,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MarketButton(
                          label: 'Lazada',
                          color: const Color(0xFF1A2E8E),
                          onPressed: onLazada,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketButton extends StatelessWidget {
  const _MarketButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _CollageCrop extends StatelessWidget {
  const _CollageCrop({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * 2;
        final height = constraints.maxHeight * 2;
        return ClipRect(
          child: OverflowBox(
            alignment: alignment,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: Image.asset(
              'assets/images/partner_collage.png',
              width: width,
              height: height,
              fit: BoxFit.fill,
            ),
          ),
        );
      },
    );
  }
}

class _ShopItem {
  const _ShopItem({
    required this.title,
    required this.category,
    required this.searchTerms,
    required this.imageAlignment,
    required this.fitReason,
  });

  final String title;
  final String category;
  final String searchTerms;
  final Alignment imageAlignment;
  final String fitReason;
}

enum _Marketplace { shopee, lazada }
