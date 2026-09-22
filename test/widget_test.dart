import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikarir/main.dart';

void main() {
  testWidgets('SikarirApp smoke test', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('HTTP request failed') ||
          details.exceptionAsString().contains('statusCode: 400')) {
        return;
      }
      FlutterError.presentError(details);
    };

    await tester.pumpWidget(const SikarirApp());
    expect(find.text('BLK Connect'), findsWidgets);
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Pelatihan'), findsWidgets);
    expect(find.text('Lowongan'), findsWidgets);
  });
}
