import 'package:sikarir/core/storage/auth_local_storage.dart';
import 'package:sikarir/features/auth/data/models/auth_models.dart';
import 'package:sikarir/features/auth/data/services/auth_service.dart';

class AuthRepository {
  final AuthService authService;
  final AuthLocalStorage authLocalStorage;

  AuthRepository({
    AuthService? authService,
    AuthLocalStorage? authLocalStorage,
  })  : authService = authService ?? AuthService(),
        authLocalStorage = authLocalStorage ?? AuthLocalStorage();

  Future<LoginResponse> login(LoginRequest loginRequest) async {
    final response = await authService.login(loginRequest);
    if (response.token.isNotEmpty) {
      await authLocalStorage.saveLoginResponse(response);
    }
    return response;
  }

  Future<RegisterResponse> register(RegisterRequest registerRequest) async {
    final response = await authService.register(registerRequest);
    if (response.token.isNotEmpty) {
      await authLocalStorage.saveAuthData(
        token: response.token,
        userId: response.userId,
        name: response.name,
        email: response.email,
      );
    }
    return response;
  }

  Future<LoginResponse?> getSavedUser() async {
    return await authLocalStorage.getSavedAuthData();
  }

  Future<String?> getToken() async {
    return await authLocalStorage.getToken();
  }

  Future<bool> isLoggedIn() async {
    return await authLocalStorage.hasToken();
  }

  Future<void> logout([String? token]) async {
    try {
      await authService.logout(token);
    } finally {
      await authLocalStorage.clearAuthData();
    }
  }
}