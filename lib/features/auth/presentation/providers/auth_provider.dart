import 'package:flutter/foundation.dart';
import 'package:sikarir/features/auth/data/models/auth_models.dart';
import 'package:sikarir/features/auth/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  LoginResponse? _user;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  LoginResponse? get user => _user;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set isAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  set user(LoginResponse? value) {
    _user = value;
    notifyListeners();
  }

  Future<void> login(LoginRequest loginRequest) async {
    isLoading = true;
    try {
      final response = await _authRepository.login(loginRequest);
      user = response;
      isAuthenticated = true;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  Future<void> register(RegisterRequest registerRequest) async {
    isLoading = true;
    try {
      final response = await _authRepository.register(registerRequest);
      // After successful registration, auto-login
      user = LoginResponse(
        token: response.token,
        userId: response.userId,
        name: response.name,
        email: response.email,
      );
      isAuthenticated = true;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    isAuthenticated = false;
    user = null;
    notifyListeners();
  }
}