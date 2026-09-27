import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/auth/data/models/auth_models.dart';

class AuthService {
  final http.Client client;

  AuthService({http.Client? client}) : client = client ?? http.Client();

  Future<LoginResponse> login(LoginRequest loginRequest) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.login),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(loginRequest.toMap()),
      );

      if (kDebugMode) {
        debugPrint("Login Status: ${response.statusCode}");
        debugPrint("Login Response: ${response.body}");
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return LoginResponse.fromMap(data);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Login error: $e");
      }
      if (e is Exception) rethrow;
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    }
  }

  Future<RegisterResponse> register(RegisterRequest registerRequest) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.register),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(registerRequest.toMap()),
      );

      if (kDebugMode) {
        debugPrint("Register Status: ${response.statusCode}");
        debugPrint("Register Response: ${response.body}");
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return RegisterResponse.fromMap(data);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Register error: $e");
      }
      if (e is Exception) rethrow;
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    }
  }

  Future<void> logout([String? token]) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      await client.post(
        Uri.parse(ApiConstants.logout),
        headers: headers,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Logout error (proceeding to local logout): $e");
      }
    }
  }

  String _parseError(http.Response response) {
    try {
      final Map<String, dynamic> data = json.decode(response.body);
      final message = data['message'] ?? data['error'];
      if (message != null) {
        if (message is List && message.isNotEmpty) {
          return message.first.toString();
        }
        return message.toString();
      }
      if (data['errors'] != null) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstVal = errors.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            return firstVal.first.toString();
          }
          return firstVal.toString();
        }
      }
    } catch (_) {}
    return 'Permintaan gagal (${response.statusCode})';
  }
}