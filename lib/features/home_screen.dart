import 'package:flutter/material.dart';

import '../services/stylorista_api.dart';
import '../theme/stylorista_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.api,
    required this.onSelectFeature,
    required this.sizeLabel,
    required this.colorSeason,
  });

  final StyloristaApi api;
  final ValueChanged<int> onSelectFeature;
  final String? sizeLabel;
  final String? colorSeason;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _cityController = TextEditingController(
    text: 'Manila',
  );
  HomeWeather? _weather;
  String? _error;
  bool _loading = false;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sizeLabel != widget.sizeLabel ||
        oldWidget.colorSeason != widget.colorSeason) {
      _loadWeather();
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    final city = _cityController.text.trim();
    if (city.length < 2) {
      setState(() => _error = 'Enter a city with at least two letters.');
      return;
    }
    final requestSerial = ++_requestSerial;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await widget.api.fetchHomeWeather(
        city: city,
        sizeLabel: widget.sizeLabel,
        colorSeason: widget.colorSeason,
      );
      if (!mounted || requestSerial != _requestSerial) return;
      setState(() => _weather = HomeWeather.fromJson(response));
    } on ApiException catch (error) {
      if (!mounted || requestSerial != _requestSerial) return;
      setState(() => _error = error.message);
    } on Exception {
      if (!mounted || requestSerial != _requestSerial) return;
      setState(() => _error = 'The weather forecast could not be read.');
    } finally {
      if (mounted && requestSerial == _requestSerial) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: StyloristaColors.sand,
      child: RefreshIndicator(
        onRefresh: _loadWeather,
        color: StyloristaColors.sandText,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _HeroCard(onTap: () => widget.onSelectFeature(7)),
            _WeatherSection(
              weather: _weather,
              loading: _loading,
              error: _error,
              cityController: _cityController,
              onSearch: _loadWeather,
            ),
            _RelevantFashion(
              tips: _weather?.fashion ?? _fallbackFashion,
              live: _weather != null,
              onOpen: () => widget.onSelectFeature(7),
            ),
            _Partners(onSelectFeature: widget.onSelectFeature),
          ],
        ),
      ),
    );
  }

  List<FashionWeatherTip> get _fallbackFashion => [
    const FashionWeatherTip(
      kind: 'outfit',
      title: 'Breathable everyday layers',
      reason: 'Live weather will refine the fabric weight and outer layer.',
    ),
    const FashionWeatherTip(
      kind: 'weather',
      title: 'Weather-ready finish',
      reason:
          'The forecast will recommend rain, sun, wind, and footwear extras.',
    ),
    FashionWeatherTip(
      kind: 'fit',
      title: 'Your fit starting point',
      reason: widget.sizeLabel == null
          ? 'Complete a body scan to personalize this recommendation.'
          : 'Start with size ${widget.sizeLabel} and verify each garment chart.',
    ),
    FashionWeatherTip(
      kind: 'color',
      title: 'Your color accent',
      reason: widget.colorSeason == null
          ? 'Complete Color Analysis to add a complexion-friendly accent.'
          : 'Use a ${widget.colorSeason} accent close to your face.',
    ),
  ];
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(26, safeTop + 25, 26, 25),
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
              const SizedBox(height: 25),
              Semantics(
                button: true,
                label: 'Open outfit suggestions for today’s weather',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(15),
                    child: Ink(
                      height: 174,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/home_hero.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 250,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.80),
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: const Text(
                            'For Today’s\nWeather',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: StyloristaColors.sandText,
                              fontSize: 34,
                              height: 1.08,
                              fontWeight: FontWeight.w400,
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

class _WeatherSection extends StatelessWidget {
  const _WeatherSection({
    required this.weather,
    required this.loading,
    required this.error,
    required this.cityController,
    required this.onSearch,
  });

  final HomeWeather? weather;
  final bool loading;
  final String? error;
  final TextEditingController cityController;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Weather now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    weather?.source ?? 'Live forecast',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 8, 11),
                      child: TextField(
                        key: const ValueKey('home-city-field'),
                        controller: cityController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => onSearch(),
                        decoration: InputDecoration(
                          hintText: 'City or city, country',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          suffixIcon: IconButton(
                            key: const ValueKey('home-weather-search'),
                            tooltip: 'Update weather',
                            onPressed: loading ? null : onSearch,
                            icon: const Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                    ),
                    if (loading)
                      const LinearProgressIndicator(
                        value: 0.65,
                        minHeight: 3,
                        color: StyloristaColors.sandText,
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 17),
                      child: weather == null
                          ? _WeatherPlaceholder(error: error, onRetry: onSearch)
                          : _WeatherContent(weather: weather!),
                    ),
                    if (weather != null && error != null)
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFFFF3E5),
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          '$error Showing the last forecast.',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherPlaceholder extends StatelessWidget {
  const _WeatherPlaceholder({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          error == null ? Icons.cloud_sync_outlined : Icons.cloud_off_outlined,
          size: 40,
          color: StyloristaColors.sandText,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            error ?? 'Loading the current and tomorrow forecast for Manila…',
            style: const TextStyle(height: 1.35),
          ),
        ),
        if (error != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({required this.weather});

  final HomeWeather weather;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF4E7DC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                _weatherIcon(weather.current.weatherCode),
                size: 42,
                color: StyloristaColors.sandText,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather.displayLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${weather.current.temperature.round()}°',
                    style: const TextStyle(
                      fontSize: 40,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    weather.current.condition,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _WeatherMetric(
                  icon: Icons.thermostat_rounded,
                  text: 'Feels ${weather.current.apparent.round()}°',
                ),
                const SizedBox(height: 7),
                _WeatherMetric(
                  icon: Icons.water_drop_outlined,
                  text: '${weather.current.humidity}% humidity',
                ),
                const SizedBox(height: 7),
                _WeatherMetric(
                  icon: Icons.air_rounded,
                  text: '${weather.current.wind.round()} km/h',
                ),
              ],
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Divider(height: 1),
        ),
        Row(
          children: [
            Icon(
              _weatherIcon(weather.tomorrow.weatherCode),
              color: StyloristaColors.sandText,
              size: 32,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tomorrow',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    weather.tomorrow.condition,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${weather.tomorrow.high.round()}° / ${weather.tomorrow.low.round()}°',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 13),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${weather.tomorrow.rainChance}% rain',
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  'UV ${weather.tomorrow.uv.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _WeatherMetric extends StatelessWidget {
  const _WeatherMetric({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.black45),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10.5)),
      ],
    );
  }
}

class _RelevantFashion extends StatelessWidget {
  const _RelevantFashion({
    required this.tips,
    required this.live,
    required this.onOpen,
  });

  final List<FashionWeatherTip> tips;
  final bool live;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your relevant fashion',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      live ? 'FORECAST MATCHED' : 'PROFILE PREVIEW',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 640;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tips.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: wide ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: wide ? 0.98 : 1.12,
                    ),
                    itemBuilder: (context, index) {
                      return _FashionTipCard(tip: tips[index], onTap: onOpen);
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('home-full-weather-look'),
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF513225),
                  ),
                  icon: const Icon(Icons.checkroom_rounded),
                  label: const Text('Build my full weather look'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FashionTipCard extends StatelessWidget {
  const _FashionTipCard({required this.tip, required this.onTap});

  final FashionWeatherTip tip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1E4D8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _fashionIcon(tip.kind),
                  color: StyloristaColors.sandText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tip.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  tip.reason,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, height: 1.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Partners extends StatelessWidget {
  const _Partners({required this.onSelectFeature});

  final ValueChanged<int> onSelectFeature;

  static const _items = [
    _PartnerItem('Fit wardrobe', Alignment.topLeft, 1),
    _PartnerItem('Personal colors', Alignment.topRight, 6),
    _PartnerItem('Styled looks', Alignment.bottomLeft, 7),
    _PartnerItem('Capsule wardrobe', Alignment.bottomRight, 7),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 28),
      child: Column(
        children: [
          const Text(
            'Our Partners',
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
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
                  return Semantics(
                    button: true,
                    label: item.label,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(21),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onSelectFeature(item.featureIndex),
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
                },
              ),
            ),
          ),
        ],
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

class _PartnerItem {
  const _PartnerItem(this.label, this.alignment, this.featureIndex);

  final String label;
  final Alignment alignment;
  final int featureIndex;
}

IconData _weatherIcon(int code) {
  if (code == 0 || code == 1) return Icons.wb_sunny_rounded;
  if (code == 2 || code == 3 || code == 45 || code == 48) {
    return Icons.cloud_rounded;
  }
  if (code >= 71 && code <= 86) return Icons.ac_unit_rounded;
  if (code >= 95) return Icons.thunderstorm_rounded;
  return Icons.water_drop_rounded;
}

IconData _fashionIcon(String kind) {
  return switch (kind) {
    'weather' => Icons.umbrella_rounded,
    'fit' => Icons.straighten_rounded,
    'color' => Icons.palette_rounded,
    _ => Icons.checkroom_rounded,
  };
}

class HomeWeather {
  const HomeWeather({
    required this.location,
    required this.region,
    required this.country,
    required this.current,
    required this.tomorrow,
    required this.fashion,
    required this.source,
  });

  factory HomeWeather.fromJson(Map<String, dynamic> json) {
    return HomeWeather(
      location: json['location'] as String,
      region: json['region'] as String?,
      country: json['country'] as String?,
      current: CurrentWeather.fromJson(json['current'] as Map<String, dynamic>),
      tomorrow: TomorrowWeather.fromJson(
        json['tomorrow'] as Map<String, dynamic>,
      ),
      fashion: (json['fashion'] as List<dynamic>)
          .map(
            (item) => FashionWeatherTip.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      source: json['source'] as String,
    );
  }

  final String location;
  final String? region;
  final String? country;
  final CurrentWeather current;
  final TomorrowWeather tomorrow;
  final List<FashionWeatherTip> fashion;
  final String source;

  String get displayLocation => [
    location,
    if (region != null && region!.isNotEmpty && region != location) region!,
    if (country != null && country!.isNotEmpty) country!,
  ].join(', ');
}

class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.apparent,
    required this.humidity,
    required this.wind,
    required this.weatherCode,
    required this.condition,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_c'] as num).toDouble(),
      apparent: (json['apparent_temperature_c'] as num).toDouble(),
      humidity: (json['humidity_percent'] as num).round(),
      wind: (json['wind_kmh'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).round(),
      condition: json['condition'] as String,
    );
  }

  final double temperature;
  final double apparent;
  final int humidity;
  final double wind;
  final int weatherCode;
  final String condition;
}

class TomorrowWeather {
  const TomorrowWeather({
    required this.high,
    required this.low,
    required this.rainChance,
    required this.uv,
    required this.weatherCode,
    required this.condition,
  });

  factory TomorrowWeather.fromJson(Map<String, dynamic> json) {
    return TomorrowWeather(
      high: (json['temperature_max_c'] as num).toDouble(),
      low: (json['temperature_min_c'] as num).toDouble(),
      rainChance: (json['precipitation_probability'] as num).round(),
      uv: (json['uv_index_max'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).round(),
      condition: json['condition'] as String,
    );
  }

  final double high;
  final double low;
  final int rainChance;
  final double uv;
  final int weatherCode;
  final String condition;
}

class FashionWeatherTip {
  const FashionWeatherTip({
    required this.kind,
    required this.title,
    required this.reason,
  });

  factory FashionWeatherTip.fromJson(Map<String, dynamic> json) {
    return FashionWeatherTip(
      kind: json['kind'] as String,
      title: json['title'] as String,
      reason: json['reason'] as String,
    );
  }

  final String kind;
  final String title;
  final String reason;
}
