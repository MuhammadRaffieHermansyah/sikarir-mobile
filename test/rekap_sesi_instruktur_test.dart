import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikarir/features/instructor/data/models/attendance_session_model.dart';
import 'package:sikarir/features/instructor/presentation/widgets/session_participants_sheet.dart';

AttendanceSession _sesi(Map<String, dynamic> extra) => AttendanceSession.fromMap({
      'id_sesi': 9,
      'id_kelas': 1,
      'pertemuan_ke': 2,
      'tanggal': '2026-11-26',
      'jam_mulai': '08:00',
      'jam_selesai': '15:00',
      'absen_dibuka': false,
      'jumlah_hadir': 2,
      ...extra,
    });

Future<void> _pasang(WidgetTester tester, Future<List<SessionParticipant>> Function() load) async {
  tester.view.physicalSize = const Size(1800, 3200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SessionParticipantsSheet(session: _sesi({}), load: load),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('Sesi membaca jumlah izin, sakit, dan alpha untuk ringkasan kartu', () {
    final sesi = _sesi({'jumlah_izin': 1, 'jumlah_sakit': 0, 'jumlah_alpha': 1, 'jumlah_peserta': 4});
    expect(sesi.summaryLabel, 'Hadir 2 · Izin 1 · Sakit 0 · Alpha 1');

    final berjalan = _sesi({'jumlah_belum': 3});
    expect(berjalan.summaryLabel, 'Hadir 2 · Izin 0 · Sakit 0 · Belum 3');
  });

  testWidgets('Rekap menampilkan nama dan status tiap peserta', (tester) async {
    await _pasang(tester, () async => [
          SessionParticipant.fromMap({'id_peserta': 1, 'nama': 'Ani', 'status': 'hadir', 'jam_hadir': '08:05'}),
          SessionParticipant.fromMap({'id_peserta': 2, 'nama': 'Budi', 'status': 'izin', 'keterangan': 'Acara keluarga'}),
          SessionParticipant.fromMap({'id_peserta': 3, 'nama': 'Dodi', 'status': 'alpha'}),
        ]);

    expect(find.text('Rekap Pertemuan 2'), findsOneWidget);
    expect(find.text('Ani'), findsOneWidget);
    expect(find.text('Pukul 08:05'), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('Acara keluarga'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Hadir 1'), findsOneWidget);
    expect(find.text('Izin 1'), findsOneWidget);
    expect(find.text('Alpha 1'), findsOneWidget);
  });

  testWidgets('Gagal memuat rekap menampilkan pesan dan bisa dicoba lagi', (tester) async {
    var panggil = 0;
    await _pasang(tester, () async {
      panggil++;
      if (panggil == 1) throw Exception('Server tidak dapat dihubungi.');
      return [SessionParticipant.fromMap({'id_peserta': 1, 'nama': 'Ani', 'status': 'hadir'})];
    });

    expect(find.text('Server tidak dapat dihubungi.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Ani'), findsOneWidget);
  });
}
