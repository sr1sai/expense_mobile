import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../env_loader.dart';
import '../models/user.dart';
import '../models/response.dart';

class AuthService {
  String? _baseUrl;

  Future<String> _getBaseUrl() async {
    if (_baseUrl != null) return _baseUrl!;
    _baseUrl = await EnvLoader.loadBaseUrl();
    return _baseUrl!;
  }

  Future<Response<String>> validateCredentials(
    String email,
    String password,
  ) async {
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse(
        '$baseUrl/api/User/IsValidCredentials',
      ).replace(queryParameters: {'email': email, 'password': password});
      final response = await http.get(uri);

      debugPrint('Login response: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = Response<String>.fromJson(jsonDecode(response.body));
        return data;
      }
      return Response<String>(status: false, message: 'Failed', data: null);
    } catch (e) {
      debugPrint('Login error: $e');
      return Response<String>(status: false, message: e.toString(), data: null);
    }
  }

  Future<Response<User>> getUserById(String id) async {
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse(
        '$baseUrl/api/User/GetUserById',
      ).replace(queryParameters: {'id': id});
      final response = await http.get(uri);

      debugPrint('GetUserById response: ${response.statusCode}');
      debugPrint('GetUserById response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = Response<User>.fromJson(
          jsonDecode(response.body),
          dataParser: (json) => User.fromJson(json),
        );
        return data;
      }
      return Response<User>(status: false, message: 'Failed', data: null);
    } catch (e) {
      debugPrint('GetUserById error: $e');
      return Response<User>(status: false, message: e.toString(), data: null);
    }
  }
}

class ApiResponse<T> {
  final bool status;
  final String message;
  final T? data;

  ApiResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? dataParser,
  }) {
    return ApiResponse<T>(
      status: json['status'] == true,
      message: json['message'] ?? '',
      data: dataParser != null && json['data'] != null
          ? dataParser(json['data'])
          : json['data'] as T?,
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson({
    bool includePassword = false,
    String? password,
  }) {
    final map = {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
    };
    if (includePassword && password != null) {
      map['password'] = password;
    }
    return map;
  }
}
