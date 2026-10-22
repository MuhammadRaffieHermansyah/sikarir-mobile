import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikarir/features/auth/auth.dart';
import 'package:sikarir/features/splash/splash.dart';
import 'package:sikarir/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SikarirApp displays SplashScreen on startup and navigates to LoginScreen when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SikarirApp());

    // Initially shows SplashScreen
    expect(find.byType(SplashScreen), findsOneWidget);

    // Fast-forward splash animation
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Reaches LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Masuk Akun'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);
  });
}

