import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/certificate/data/models/certificate_model.dart';
import 'package:sikarir/features/certificate/data/repositories/certificate_repository.dart';
import 'package:sikarir/features/certificate/presentation/certificate_screen.dart';
import 'package:sikarir/features/certificate/presentation/providers/certificate_provider.dart';
import 'package:sikarir/features/profile/presentation/providers/peserta_provider.dart';

class _RepoPalsu extends CertificateRepository {
  final List<CertificateModel> data;
  _RepoPalsu(this.data);

  @override
  Future<List<CertificateModel>> getCertificates([String? token]) async => data;
}

CertificateModel _sertifikat({String fileUrl = 'http://10.0.0.1:8000/storage/sertifikat/a.pdf'}) => CertificateModel(
      id: '1',
      title: 'Web Developer',
      issuer: 'BLK',
      issueDate: '2026-11-20',
      validUntil: '-',
      certificateNumber: 'SRT-0001',
      status: 'aktif',
      fileUrl: fileUrl,
      category: 'TI',
    );

Future<void> _pasang(WidgetTester tester, CertificateModel cert, Future<bool> Function(Uri) openUrl) async {
  // Layar lebar: font uji (Ahem) jauh lebih lebar dari font asli.
  tester.view.physicalSize = const Size(1800, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PesertaProvider()),
        ChangeNotifierProvider(create: (_) => CertificateProvider(repository: _RepoPalsu([cert]))),
      ],
      child: MaterialApp(home: CertificateScreen(openUrl: openUrl)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Unduh PDF membuka file sertifikat dari server', (tester) async {
    Uri? dibuka;
    await _pasang(tester, _sertifikat(), (uri) async {
      dibuka = uri;
      return true;
    });

    await tester.tap(find.text('Unduh PDF'));
    await tester.pumpAndSettle();

    expect(dibuka.toString(), 'http://10.0.0.1:8000/storage/sertifikat/a.pdf');
    expect(find.textContaining('Mengunduh'), findsNothing);
  });

  testWidgets('Gagal membuka file menampilkan pesan dan tombol salin', (tester) async {
    await _pasang(tester, _sertifikat(), (_) async => false);

    await tester.tap(find.text('Unduh PDF'));
    await tester.pump();

    expect(find.textContaining('tidak dapat dibuka'), findsOneWidget);
    expect(find.text('Salin URL'), findsOneWidget);
  });

  testWidgets('Sertifikat tanpa file tidak membuka apa pun', (tester) async {
    var dipanggil = false;
    await _pasang(tester, _sertifikat(fileUrl: ''), (_) async {
      dipanggil = true;
      return true;
    });

    await tester.tap(find.text('Unduh PDF'));
    await tester.pump();

    expect(dipanggil, isFalse);
    expect(find.textContaining('belum diunggah'), findsOneWidget);
  });
}
