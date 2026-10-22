import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikarir/app/router/app_router.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/auth.dart';
import 'package:sikarir/features/splash/splash.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SplashScreen displays branding elements correctly',
      (WidgetTester tester) async {
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SplashScreen(minDuration: Duration(milliseconds: 300)),
        ),
      ),
    );

    // Initial frame check
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Portal Karir & Pelatihan Vokasi'), findsOneWidget);
    expect(find.text('BLK DIGITAL ECOSYSTEM'), findsOneWidget);
    expect(find.text('KEMENTERIAN KETENAGAKERJAAN RI'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);

    // Cleanly let timers finish
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('SplashScreen routes to LoginScreen when unauthenticated',
      (WidgetTester tester) async {
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const SplashScreen(minDuration: Duration(milliseconds: 300)),
        ),
      ),
    );

    // Initial check
    expect(find.byType(SplashScreen), findsOneWidget);

    // Fast-forward animation & timer
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Masuk Akun'), findsOneWidget);
  });
}
