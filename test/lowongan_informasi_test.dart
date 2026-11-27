import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/job/data/models/job_model.dart';
import 'package:sikarir/features/job/data/repositories/job_repository.dart';
import 'package:sikarir/features/job/presentation/job_list_screen.dart';
import 'package:sikarir/features/job/presentation/providers/job_provider.dart';
import 'package:sikarir/features/profile/presentation/providers/peserta_provider.dart';

class _RepoPalsu extends JobRepository {
  final List<JobVacancyModel> data;
  _RepoPalsu(this.data);

  @override
  Future<JobFetchResult> getJobs([String? token]) async => JobFetchResult(jobs: data);
}

JobVacancyModel _lowongan({Map<String, dynamic> mitra = const {'nama_perusahaan': 'PT Maju', 'no_telp': '0812-3456-789'}}) =>
    JobVacancyModel.fromMap({
      'id_lowongan': 7,
      'judul_lowongan': 'Teknisi Las',
      'status': 'aktif',
      'mitra': mitra,
    });

Future<void> _pasang(WidgetTester tester, JobVacancyModel job, Future<bool> Function(Uri) openUrl) async {
  // Layar lebar: font uji (Ahem) jauh lebih lebar dari font asli.
  tester.view.physicalSize = const Size(1800, 3200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PesertaProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider(repository: _RepoPalsu([job]))),
      ],
      child: MaterialApp(home: JobListScreen(openUrl: openUrl)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('Model lowongan membaca nomor telepon dari data mitra', () {
    expect(_lowongan().contactPhone, '0812-3456-789');
    expect(_lowongan(mitra: const {'nama_perusahaan': 'PT Maju'}).contactPhone, isEmpty);
  });

  testWidgets('Lowongan hanya informasi: tidak ada tombol lamar, detail berisi kontak perusahaan', (tester) async {
    Uri? dibuka;
    await _pasang(tester, _lowongan(), (uri) async {
      dibuka = uri;
      return true;
    });

    expect(find.textContaining('Lamar'), findsNothing);

    await tester.ensureVisible(find.text('Lihat Detail'));
    await tester.tap(find.text('Lihat Detail'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Lowongan ini bersifat informasi'), findsOneWidget);
    expect(find.textContaining('Kirim Lamaran'), findsNothing);

    await tester.tap(find.text('Hubungi 0812-3456-789'));
    await tester.pumpAndSettle();

    expect(dibuka.toString(), 'https://wa.me/628123456789');
  });

  testWidgets('Tanpa nomor telepon, detail menampilkan keterangan kontak belum ada', (tester) async {
    await _pasang(tester, _lowongan(mitra: const {'nama_perusahaan': 'PT Maju'}), (_) async => true);

    await tester.ensureVisible(find.text('Lihat Detail'));
    await tester.tap(find.text('Lihat Detail'));
    await tester.pumpAndSettle();

    expect(find.text('Kontak perusahaan belum dicantumkan.'), findsOneWidget);
  });
}
