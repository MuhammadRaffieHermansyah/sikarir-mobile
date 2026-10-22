import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikarir/core/storage/auth_local_storage.dart';
import 'package:sikarir/features/auth/data/models/auth_models.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthLocalStorage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should save, retrieve and clear auth data properly', () async {
      final storage = AuthLocalStorage();

      expect(await storage.hasToken(), isFalse);
      expect(await storage.getSavedAuthData(), isNull);

      final loginResponse = LoginResponse(
        token: 'test-token-12345',
        userId: 'user-001',
        name: 'Raffie Hermansyah',
        email: 'raffie@example.com',
      );

      await storage.saveLoginResponse(loginResponse);

      expect(await storage.hasToken(), isTrue);
      expect(await storage.getToken(), equals('test-token-12345'));

      final retrieved = await storage.getSavedAuthData();
      expect(retrieved, isNotNull);
      expect(retrieved!.token, equals('test-token-12345'));
      expect(retrieved.userId, equals('user-001'));
      expect(retrieved.name, equals('Raffie Hermansyah'));
      expect(retrieved.email, equals('raffie@example.com'));

      await storage.clearAuthData();

      expect(await storage.hasToken(), isFalse);
      expect(await storage.getToken(), isNull);
      expect(await storage.getSavedAuthData(), isNull);
    });
  });

  group('AuthProvider Persistence & Auto-login Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'saved-jwt-token',
        'user_id': '42',
        'user_name': 'Ahmad Fauzi',
        'user_email': 'ahmad@blk.id',
      });
    });

    test('should auto-authenticate when token exists in storage', () async {
      final authProvider = AuthProvider();
      await authProvider.init();

      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user, isNotNull);
      expect(authProvider.user?.token, equals('saved-jwt-token'));
      expect(authProvider.user?.name, equals('Ahmad Fauzi'));
      expect(authProvider.user?.email, equals('ahmad@blk.id'));
    });

    test('should clear authentication state and storage on logout', () async {
      final authProvider = AuthProvider();
      await authProvider.init();
      expect(authProvider.isAuthenticated, isTrue);

      await authProvider.logout();

      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);

      final storage = AuthLocalStorage();
      expect(await storage.hasToken(), isFalse);
    });
  });
}
