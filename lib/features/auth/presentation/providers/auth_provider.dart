import 'package:flutter/foundation.dart';
import 'package:sikarir/features/auth/data/models/auth_models.dart';
import 'package:sikarir/features/auth/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({
    AuthRepository? authRepository,
    bool autoInit = false,
  })  : _authRepository = authRepository ?? AuthRepository() {
    if (autoInit) {
      init();
    }
  }

  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  LoginResponse? _user;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  LoginResponse? get user => _user;
  String? get errorMessage => _errorMessage;

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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Memeriksa dan memuat session user tersimpan dari SharedPreferences
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedUser = await _authRepository.getSavedUser();
      if (savedUser != null && savedUser.token.trim().isNotEmpty) {
        _user = savedUser;
        _isAuthenticated = true;
        if (kDebugMode) {
          debugPrint("AuthProvider: Auto-login berhasil untuk user ${savedUser.name} (${savedUser.email})");
        }
      } else {
        _user = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("AuthProvider Error loading saved session: $e");
      }
      _user = null;
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> login(LoginRequest loginRequest) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.login(loginRequest);
      _user = response;
      _isAuthenticated = true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(RegisterRequest registerRequest) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.register(registerRequest);
      // Auto-authenticate after successful registration
      _user = LoginResponse(
        token: response.token,
        userId: response.userId,
        name: response.name,
        email: response.email,
      );
      _isAuthenticated = true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final currentToken = _user?.token;
    try {
      await _authRepository.logout(currentToken);
    } catch (_) {
      // Ignore network errors on logout to allow local logout
    } finally {
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }
}