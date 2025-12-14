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
      final userController = await EnvLoader.getController('UserController');
      final verifyAction = await EnvLoader.getAction('VerifyUser');
      final uri = Uri.parse(
        '$baseUrl$userController$verifyAction',
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

  Future<Response<UserPublicDTO>> getUserById(String id) async {
    try {
      final baseUrl = await _getBaseUrl();
      final userController = await EnvLoader.getController('UserController');
      final getUserAction = await EnvLoader.getAction('GetuserById');
      final uri = Uri.parse(
        '$baseUrl$userController$getUserAction',
      ).replace(queryParameters: {'id': id});
      final response = await http.get(uri);

      debugPrint('GetUserById response: ${response.statusCode}');
      debugPrint('GetUserById response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = Response<UserPublicDTO>.fromJson(
          jsonDecode(response.body),
          dataParser: (json) => UserPublicDTO.fromJson(json),
        );
        return data;
      }
      return Response<UserPublicDTO>(
        status: false,
        message: 'Failed',
        data: null,
      );
    } catch (e) {
      debugPrint('GetUserById error: $e');
      return Response<UserPublicDTO>(
        status: false,
        message: e.toString(),
        data: null,
      );
    }
  }

  Future<Response<String>> registerUser(UserDTO user) async {
    try {
      final baseUrl = await _getBaseUrl();
      final userController = await EnvLoader.getController('UserController');
      final registerAction = await EnvLoader.getAction('RegisterUser');
      final uri = Uri.parse('$baseUrl$userController$registerAction');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      debugPrint('RegisterUser response: ${response.statusCode}');
      debugPrint('RegisterUser response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = Response<String>.fromJson(jsonDecode(response.body));
        return data;
      }
      return Response<String>(status: false, message: 'Failed', data: null);
    } catch (e) {
      debugPrint('RegisterUser error: $e');
      return Response<String>(status: false, message: e.toString(), data: null);
    }
  }
}
