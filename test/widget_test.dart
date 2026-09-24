import 'package:flutter_test/flutter_test.dart';
import 'package:sikarir/main.dart';

void main() {
  testWidgets('SikarirApp shows login screen when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SikarirApp());

    expect(find.text('Selamat datang kembali'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Belum punya akun? Daftar'), findsOneWidget);
  });
}