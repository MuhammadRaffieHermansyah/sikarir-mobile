import 'package:sikarir/features/auth/data/models/auth_models.dart';
import 'package:sikarir/features/auth/data/services/auth_local_service.dart';
import 'package:sikarir/features/auth/data/services/auth_service.dart';

class AuthRepository {
  final AuthService authService;
  final AuthLocalService localService;

  AuthRepository({
    AuthService? authService,
    AuthLocalService? localService,
  })  : authService = authService ?? AuthService(),
        localService = localService ?? AuthLocalService();

  Future<LoginResponse> login(LoginRequest loginRequest) async {
    final response = await authService.login(loginRequest);
    print(response);
    await localService.saveUserSession(response);
    return response;
  }

  Future<RegisterResponse> register(RegisterRequest registerRequest) async {
    final response = await authService.register(registerRequest);
    final user = LoginResponse(
      token: response.token,
      userId: response.userId,
      name: response.name,
      email: response.email,
    );
    await localService.saveUserSession(user);
    return response;
  }

  Future<void> logout([String? token]) async {
    try {
      await authService.logout(token);
    } finally {
      await localService.clearUserSession();
    }
  }

  Future<LoginResponse?> getSavedSession() async {
    return await localService.getUserSession();
  }

  Future<void> clearSession() async {
    await localService.clearUserSession();
  }
}
