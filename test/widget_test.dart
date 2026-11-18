import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikarir/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SikarirApp shows login screen when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SikarirApp());
    await tester.pumpAndSettle();

    expect(find.text('Masuk Akun'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);
  });
}
