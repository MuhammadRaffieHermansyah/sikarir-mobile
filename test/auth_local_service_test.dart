import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikarir/features/auth/data/models/auth_models.dart';
import 'package:sikarir/features/auth/data/repositories/auth_repository.dart';
import 'package:sikarir/features/auth/data/services/auth_local_service.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AuthLocalService can save, get, and clear user session', () async {
    final localService = AuthLocalService();

    final testUser = LoginResponse(
      token: 'sample-jwt-token-12345',
      userId: 'usr_001',
      name: 'Budi Santoso',
      email: 'budi@example.com',
    );

    // Initial state: no session
    expect(await localService.hasSession(), false);
    expect(await localService.getUserSession(), isNull);

    // Save session
    await localService.saveUserSession(testUser);
    expect(await localService.hasSession(), true);
    expect(await localService.getToken(), 'sample-jwt-token-12345');

    // Restore session
    final restoredUser = await localService.getUserSession();
    expect(restoredUser, isNotNull);
    expect(restoredUser?.token, 'sample-jwt-token-12345');
    expect(restoredUser?.name, 'Budi Santoso');
    expect(restoredUser?.email, 'budi@example.com');

    // Clear session
    await localService.clearUserSession();
    expect(await localService.hasSession(), false);
    expect(await localService.getUserSession(), isNull);
  });

  test('AuthProvider restores session when token exists in SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'saved-token-abc',
      'auth_user_id': '42',
      'auth_name': 'Siti Rahma',
      'auth_email': 'siti@example.com',
    });

    final authProvider = AuthProvider(
      authRepository: AuthRepository(
        localService: AuthLocalService(),
      ),
    );

    final hasSession = await authProvider.checkAuthSession();

    expect(hasSession, true);
    expect(authProvider.isAuthenticated, true);
    expect(authProvider.token, 'saved-token-abc');
    expect(authProvider.user?.name, 'Siti Rahma');

    // Logout should clear session and state
    await authProvider.logout();
    expect(authProvider.isAuthenticated, false);
    expect(authProvider.token, isNull);
    expect(authProvider.user, isNull);
  });
}

