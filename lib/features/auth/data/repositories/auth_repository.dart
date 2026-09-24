import 'package:sikarir/features/auth/data/models/auth_models.dart';
import 'package:sikarir/features/auth/data/services/auth_service.dart';

class AuthRepository {
  final AuthService authService;

  AuthRepository({AuthService? authService})
      : authService = authService ?? AuthService();

  Future<LoginResponse> login(LoginRequest loginRequest) async {
    return await authService.login(loginRequest);
  }

  Future<RegisterResponse> register(RegisterRequest registerRequest) async {
    return await authService.register(registerRequest);
  }

  Future<void> logout([String? token]) async {
    await authService.logout(token);
  }
}