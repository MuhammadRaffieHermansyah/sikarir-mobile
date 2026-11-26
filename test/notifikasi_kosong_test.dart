import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/core/widgets/blk_header.dart';
import 'package:sikarir/features/notification/notification.dart';
import 'package:sikarir/features/profile/presentation/providers/peserta_provider.dart';

void main() {
  testWidgets('Lembar notifikasi menampilkan keadaan kosong, bukan contoh statis', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NotificationSheet())));

    expect(find.text('Belum ada notifikasi'), findsOneWidget);
    expect(find.text('Kelas Tatap Muka Besok'), findsNothing);
    expect(find.text('Loker Baru Mitra BLK'), findsNothing);
  });

  testWidgets('Lonceng header tidak menampilkan titik belum dibaca', (tester) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PesertaProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: BlkHeader(sectionTitle: 'Beranda', onNotificationTap: () {}),
          ),
        ),
      ),
    );

    final titikOranye = find.byWidgetPredicate(
      (w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == AppColors.orange,
    );
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(titikOranye, findsNothing);
  });
}
