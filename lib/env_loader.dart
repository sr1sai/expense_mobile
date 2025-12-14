import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class EnvLoader {
  static String? _baseUrl;
  static Map<String, String>? _controllers;
  static Map<String, String>? _apiActions;
  static bool _loaded = false;

  static Future<void> _loadEnv({bool isProduction = false}) async {
    if (_loaded) return;
    final envFile = isProduction ? 'assets/env.production.json' : 'assets/env.development.json';
    try {
      final content = await rootBundle.loadString(envFile);
      final jsonMap = jsonDecode(content);
      if (jsonMap is Map<String, dynamic>) {
        _baseUrl = jsonMap['BASE_URL'] as String?;
        final controllers = jsonMap['Controllers'] as Map<String, dynamic>?;
        final actions = jsonMap['APIActions'] as Map<String, dynamic>?;
        _controllers = controllers?.map((k, v) => MapEntry(k, v as String));
        _apiActions = actions?.map((k, v) => MapEntry(k, v as String));
        _loaded = true;
        return;
      }
      throw Exception('Invalid env json structure in $envFile');
    } catch (e) {
      throw Exception('Error loading $envFile: $e');
    }
  }

  static Future<String> loadBaseUrl({bool isProduction = false}) async {
    await _loadEnv(isProduction: isProduction);
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      throw Exception('BASE_URL not found in environment file');
    }
    return _baseUrl!;
  }

  static Future<String> getController(String key, {bool isProduction = false}) async {
    await _loadEnv(isProduction: isProduction);
    final value = _controllers?[key];
    if (value == null || value.isEmpty) {
      throw Exception('Controller "$key" not found in environment file');
    }
    return value;
  }

  static Future<String> getAction(String key, {bool isProduction = false}) async {
    await _loadEnv(isProduction: isProduction);
    final value = _apiActions?[key];
    if (value == null || value.isEmpty) {
      throw Exception('API Action "$key" not found in environment file');
    }
    return value;
  }
}
