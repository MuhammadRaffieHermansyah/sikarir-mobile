import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/auth/data/models/auth_models.dart';

class AuthService {
  final http.Client client;

  AuthService({http.Client? client}) : client = client ?? http.Client();

  Future<LoginResponse> login(LoginRequest loginRequest) async {
    print("URL : ${ApiConstants.login}");
    print("LoginRequest : ${loginRequest.toMap()}");
    final response = await client.post(
      Uri.parse(ApiConstants.login),
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(loginRequest.toMap()),
    );

    print("RESPONSE body : ${response}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return LoginResponse.fromMap(data);
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<RegisterResponse> register(RegisterRequest registerRequest) async {
    final response = await client.post(
      Uri.parse(ApiConstants.register),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode(registerRequest.toMap()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      return RegisterResponse.fromMap(data);
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<void> logout() async {
    await client.post(Uri.parse(ApiConstants.logout));
  }

  String _parseError(http.Response response) {
    try {
      final Map<String, dynamic> data = json.decode(response.body);
      final message = data['message'] ?? data['error'];
      if (message != null) {
        return message.toString();
      }
    } catch (_) {}
    return 'Request gagal (${response.statusCode})';
  }
}