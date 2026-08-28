import 'dart:convert';

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
    Map<String, dynamic> payload,
  ) async {
    late http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_configuredBaseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));
    } on Exception {
      throw const ApiException(
        'The styling service is unavailable. Start the Python API and check API_BASE_URL.',
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
