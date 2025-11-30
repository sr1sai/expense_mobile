import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class EnvLoader {
  static String? _baseUrl;

  static Future<String> loadBaseUrl({bool isProduction = false}) async {
    if (_baseUrl != null) return _baseUrl!;
    final envFile = isProduction ? 'assets/env.production.json' : 'assets/env.development.json';
    try {
      final content = await rootBundle.loadString(envFile);
      final jsonMap = jsonDecode(content);
      if (jsonMap is Map<String, dynamic> && jsonMap.containsKey('BASE_URL')) {
        _baseUrl = jsonMap['BASE_URL'] as String;
        return _baseUrl!;
      }
      throw Exception('BASE_URL not found in $envFile');
    } catch (e) {
      throw Exception('Error loading $envFile: $e');
    }
  }
}
