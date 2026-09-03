import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class StyloristaApi {
  StyloristaApi({http.Client? client}) : _client = client ?? http.Client();

  static const _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  final http.Client _client;

  Future<Map<String, dynamic>> recommendSize({
    required Map<String, double> measurements,
    required String fitPreference,
  }) {
    return _post('/v1/size/recommend', {
      'measurements': measurements,
      'fit_preference': fitPreference,
    });
  }

  Future<Map<String, dynamic>> analyzeColor({
    required String skinHex,
    required String hairHex,
    required String eyeHex,
  }) {
    return _post('/v1/color/analyze', {
      'skin_hex': skinHex,
      'hair_hex': hairHex,
      'eye_hex': eyeHex,
    });
  }

  Future<Map<String, dynamic>> analyzeBodyPhoto({
    required Uint8List imageBytes,
    required double referenceHeightCm,
  }) {
    return _post('/v1/body-scan/analyze', {
      'image_base64': base64Encode(imageBytes),
      'reference_height_cm': referenceHeightCm,
      'consent_confirmed': true,
    }, timeout: const Duration(seconds: 35));
  }

  Future<Map<String, dynamic>> analyzeAppearancePhoto({
    required Uint8List imageBytes,
  }) {
    return _post('/v1/profile/analyze', {
      'image_base64': base64Encode(imageBytes),
      'consent_confirmed': true,
    }, timeout: const Duration(seconds: 35));
  }

  Future<Map<String, dynamic>> fetchFashionNews({
    required String category,
    int limit = 16,
  }) {
    return _get('/v1/news/feed', {
      'category': category,
      'limit': '$limit',
    }, timeout: const Duration(seconds: 12));
  }

  Future<Map<String, dynamic>> fetchHomeWeather({
    required String city,
    String? sizeLabel,
    String? colorSeason,
  }) {
    return _get('/v1/weather/home', {
      'city': city,
      if (sizeLabel != null && sizeLabel.isNotEmpty) 'size_label': sizeLabel,
      if (colorSeason != null && colorSeason.isNotEmpty)
        'color_season': colorSeason,
    }, timeout: const Duration(seconds: 12));
  }

  Future<Map<String, dynamic>> recommendStyle({
    required String climate,
    required String hemisphere,
    required int month,
    required String occasion,
    required String style,
    required String colorSeason,
    String? sizeLabel,
  }) {
    return _post('/v1/style/recommend', {
      'climate': climate,
      'hemisphere': hemisphere,
      'month': month,
      'occasion': occasion,
      'style': style,
      'color_season': colorSeason,
      if (sizeLabel != null && sizeLabel.isNotEmpty) 'size_label': sizeLabel,
    });
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    late http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_configuredBaseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);
    } on Exception {
      throw const ApiException(
        'The styling service is temporarily unavailable. Check your internet connection and try again.',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded is Map<String, dynamic> ? decoded['detail'] : null;
      throw ApiException(_humanizeError(detail));
    }
    return decoded as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> queryParameters, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    late http.Response response;
    try {
      final uri = Uri.parse(
        '$_configuredBaseUrl$path',
      ).replace(queryParameters: queryParameters);
      response = await _client.get(uri).timeout(timeout);
    } on Exception {
      throw const ApiException(
        'The live service is temporarily unavailable. Check your internet connection and try again.',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded is Map<String, dynamic> ? decoded['detail'] : null;
      throw ApiException(_humanizeError(detail));
    }
    return decoded as Map<String, dynamic>;
  }

  String _humanizeError(dynamic detail) {
    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      return detail.first['msg']?.toString() ??
          'Please review the information and try again.';
    }
    return detail?.toString() ?? 'Something went wrong. Please try again.';
  }
}
