import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/features/auth/data/models/auth_models.dart';
import 'package:sikarir/features/auth/presentation/pages/login_page.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';

void main() {
  test('LoginResponse membaca tanda wajib ganti sandi dan menyimpannya', () {
    final hasilReset = LoginResponse.fromMap({
      'token': 't',
      'data': {'id': 1, 'name': 'Ani', 'email': 'a@x.id', 'role': 'peserta', 'must_change_password': true},
    });
    expect(hasilReset.mustChangePassword, isTrue);
    expect(LoginResponse.fromMap(hasilReset.toMap()).mustChangePassword, isTrue);

    final biasa = LoginResponse.fromMap({
      'token': 't',
      'data': {'id': 2, 'name': 'Budi', 'email': 'b@x.id', 'must_change_password': false},
    });
    expect(biasa.mustChangePassword, isFalse);
  });

  testWidgets('Lupa sandi mengarahkan ke admin BLK, bukan mengaku mengirim email', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.ensureVisible(find.text('Lupa sandi?'));
    await tester.tap(find.text('Lupa sandi?'));
    await tester.pumpAndSettle();

    expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
    expect(find.textContaining('Hubungi admin BLK'), findsOneWidget);
    expect(find.textContaining('telah dikirim'), findsNothing);

    await tester.tap(find.text('Mengerti'));
    await tester.pumpAndSettle();
    expect(find.text('Lupa Kata Sandi?'), findsNothing);
  });
}
