import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/data/repositories/attendance_repository.dart';
import 'package:sikarir/features/attendance/data/services/attendance_service.dart';
import 'package:sikarir/features/attendance/data/services/location_service.dart';
import 'package:sikarir/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_status_style.dart';
import 'package:sikarir/features/attendance/utils/attendance_formatters.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';

Map<String, dynamic> _absen({
  required int id,
  String tanggal = '2026-11-24',
  String status = 'hadir',
  int jadwal = 1,
}) =>
    {
      'id_absen': id,
      'id_peserta': 7,
      'id_jadwal': jadwal,
      'tanggal': tanggal,
      'jam_hadir': '08:00',
      'status_kehadiran': status,
    };

http.Response _json(Object body, [int status = 200]) =>
    http.Response(json.encode(body), status,
        headers: {'content-type': 'application/json'});

AttendanceService _service(MockClientHandler handler) =>
    AttendanceService(client: MockClient(handler));

Position _position({
  double lat = LocationService.defaultLat,
  double lng = LocationService.defaultLng,
  double accuracy = 5,
}) =>
    Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 11, 24),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

/// Repository palsu: perilaku diatur lewat closure.
class FakeAttendanceRepository extends AttendanceRepository {
  Future<AttendancePage> Function(int page) onPage =
      (_) async => const AttendancePage(items: [], hasMore: false);
  Future<AttendanceItem?> Function() onToday = () async => null;
  Future<AttendanceRekap?> Function() onRekap = () async => null;
  Future<AttendanceSubmitResult> Function(AttendanceSubmitRequest r)? onSubmit;
  Future<AttendanceItem> Function(String absenId)? onClockOut;
  int submitCalls = 0;

  @override
  Future<AttendancePage> getAttendancePage({int page = 1, String? token}) =>
      onPage(page);

  @override
  Future<AttendanceItem?> getTodayAttendance([String? token]) => onToday();

  @override
  Future<AttendanceRekap?> getAttendanceSummaryReport([String? token]) =>
      onRekap();

  @override
  Future<AttendanceSubmitResult> submitAttendance(
    AttendanceSubmitRequest request, [
    String? token,
  ]) {
    submitCalls++;
    return onSubmit!(request);
  }

  @override
  Future<AttendanceItem> clockOut({
    required String absenId,
    required double latitude,
    required double longitude,
    String? token,
  }) =>
      onClockOut!(absenId);
}

AttendanceSubmitResult _result(List<AttendanceItem> items,
        {List<String> skipped = const [], String? message}) =>
    AttendanceSubmitResult(items: items, skippedDates: skipped, message: message);

AttendanceSubmitRequest _request({
  String status = 'hadir',
  String tanggal = '2026-11-24',
  String? tanggalSelesai,
  String? attachmentPath,
}) =>
    AttendanceSubmitRequest(
      jadwalId: '1',
      pesertaId: '7',
      tanggal: tanggal,
      jamHadir: '09:00',
      status: status,
      tanggalSelesai: tanggalSelesai,
      attachmentPath: attachmentPath,
    );

void main() {
  group('attendance_formatters', () {
    test('format tanggal & waktu', () {
      final d = DateTime(2026, 11, 24, 8, 5, 9); // Selasa
      expect(formatLongDate(d), '24 November 2026');
      expect(formatDayDate(d), 'Selasa, 24 November 2026');
      expect(formatMonthYear(d), 'November 2026');
      expect(formatClock(d), '08:05');
      expect(formatClock(d, withSeconds: true), '08:05:09');
      expect(formatApiDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(formatApiTime(d), '08:05');
    });

    test('tryParseApiDate menerima Y-m-d dan ISO, menolak sampah', () {
      expect(tryParseApiDate('2026-11-24'), DateTime(2026, 11, 24));
      expect(tryParseApiDate('2026-11-24T00:00:00.000000Z'),
          DateTime(2026, 11, 24));
      expect(tryParseApiDate('Hari Ini'), isNull);
      expect(tryParseApiDate('2026-13-40'), isNull);
    });

    test('formatApiDateLabel fallback ke teks asli', () {
      expect(formatApiDateLabel('2026-11-24'), 'Selasa, 24 November 2026');
      expect(formatApiDateLabel('Hari Ini'), 'Hari Ini');
    });
  });

  group('AttendanceItem', () {
    test('fromMap membaca kontrak backend', () {
      final item = AttendanceItem.fromMap({
        ..._absen(id: 3),
        'keterangan': 'catatan',
        'latitude': '-8.1575',
        'jarak_meter': 12.5,
        'jadwal': {
          'pelatihan': {'nama_pelatihan': 'Las SMAW'},
          'ruangan_workshop': {'nama_ruangan': 'Workshop A'},
        },
      });
      expect(item.id, '3');
      expect(item.classId, '1');
      expect(item.className, 'Las SMAW');
      expect(item.roomName, 'Workshop A');
      expect(item.clockInTime, '08:00');
      expect(item.latitude, -8.1575);
      expect(item.jarakMeter, 12.5);
      expect(item.notes, 'catatan');
    });

    test('normalizeStatus menyamakan alpa/alpha dan huruf besar', () {
      expect(AttendanceItem.normalizeStatus('alpa'), 'alpha');
      expect(AttendanceItem.normalizeStatus(' ALPHA '), 'alpha');
      expect(AttendanceItem.normalizeStatus('Hadir'), 'hadir');
      expect(
          AttendanceItem.fromMap(_absen(id: 1, status: 'alpa')).status, 'alpha');
    });
  });

  group('AttendanceSummary', () {
    test('tanpa data → 0%, hasData false, tidak memenuhi syarat', () {
      final s = AttendanceSummary.fromList([]);
      expect(s.hasData, isFalse);
      expect(s.attendancePercentage, 0);
      expect(s.meetsMinimum, isFalse);
    });

    test('menghitung per status dan persentase', () {
      final s = AttendanceSummary.fromList([
        for (var i = 0; i < 8; i++) AttendanceItem.fromMap(_absen(id: i)),
        AttendanceItem.fromMap(_absen(id: 20, status: 'izin')),
        AttendanceItem.fromMap(_absen(id: 21, status: 'alpa')),
      ]);
      expect(s.totalPresent, 8);
      expect(s.totalPermission, 1);
      expect(s.totalAbsent, 1);
      expect(s.attendancePercentage, 80);
      expect(s.meetsMinimum, isTrue);
    });
  });

  group('AttendanceRekap', () {
    final payload = {
      'summary': {
        'total_hadir': 18,
        'total_izin': 1,
        'total_sakit': 1,
        'total_alpha': 0,
        'total_sesi': 20,
        'persentase_hadir': 90.0,
        'syarat_persentase': 80,
        'status_kelayakan': 'Memenuhi Syarat Sertifikasi',
        'memenuhi_syarat': true,
      },
    };

    test('fromMap mengikuti kontrak /absen/rekap', () {
      final r = AttendanceRekap.fromMap(payload);
      expect(r.memenuhiSyarat, isTrue);
      expect(r.persentase, 90);
      expect(r.minimalPersentase, 80);
      expect(r.statusKelayakan, 'Memenuhi Syarat Sertifikasi');
      expect(r.totalHadir, 18);
    });

    test('toSummary memakai angka server; null bila tak ada hitungan', () {
      final s = AttendanceRekap.fromMap(payload).toSummary()!;
      expect(s.totalPresent, 18);
      expect(s.totalPermission, 1);
      expect(s.attendancePercentage, 90);
      expect(const AttendanceRekap(memenuhiSyarat: true).toSummary(), isNull);
    });
  });

  group('AttendanceStatusStyle', () {
    test('memetakan status, selain dikenal dianggap alpha', () {
      expect(AttendanceStatusStyle.of('hadir').label, 'Hadir');
      expect(AttendanceStatusStyle.of('IZIN').todayLabel, 'Izin Tercatat');
      expect(AttendanceStatusStyle.of('sakit').todayLabel, 'Sakit Tercatat');
      expect(AttendanceStatusStyle.of('alpha').label, 'Alpa');
      expect(AttendanceStatusStyle.of('???').label, 'Alpa');
    });
  });

  group('LocationService', () {
    test('hitungJarak: titik sama = 0, 1° lintang ≈ 111 km', () {
      expect(
          LocationService.hitungJarak(lat1: 1, lng1: 2, lat2: 1, lng2: 2), 0);
      final d = LocationService.hitungJarak(lat1: 0, lng1: 0, lat2: 1, lng2: 0);
      expect(d, closeTo(111195, 100));
    });

    test('cekLokasiValid: di dalam & di luar radius', () {
      final inside = LocationService.cekLokasiValid(position: _position());
      expect(inside.isValid, isTrue);
      expect(inside.jarakMeter, lessThan(1));

      // ± 0.002° lintang ≈ 222 m > radius default 100 m
      final outside = LocationService.cekLokasiValid(
          position: _position(lat: LocationService.defaultLat + 0.002));
      expect(outside.isValid, isFalse);
      expect(outside.jarakLabel, endsWith(' m'));
    });

    test('jarakLabel memakai km untuk ≥ 1000 m', () {
      const r = LocationCheckResult(
          jarakMeter: 1500,
          radiusMeter: 100,
          isValid: false,
          latitude: 0,
          longitude: 0);
      expect(r.jarakLabel, '1.5 km');
    });

    test('AttendanceTarget.fromSchedule: pakai jadwal, fallback default', () {
      final custom = AttendanceTarget.fromSchedule(
          latitude: -7.5,
          longitude: 112.1,
          radiusMeter: 50,
          label: 'Workshop A');
      expect(custom.latitude, -7.5);
      expect(custom.radiusMeter, 50);
      expect(custom.label, 'Workshop A');

      final fallback = AttendanceTarget.fromSchedule(radiusMeter: 0, label: ' ');
      expect(fallback.latitude, LocationService.defaultLat);
      expect(fallback.radiusMeter, LocationService.defaultRadius);
      expect(fallback.label, LocationService.defaultLokasiLabel);

      // Hanya satu koordinat terisi → tidak dipakai setengah-setengah
      final partial = AttendanceTarget.fromSchedule(latitude: -7.5);
      expect(partial.latitude, LocationService.defaultLat);
    });
  });

  group('TrainingClassModel koordinat jadwal', () {
    test('membaca lokasi_latitude/lokasi_longitude/radius_meter', () {
      final c = TrainingClassModel.fromMap({
        'id_kelas': 1,
        'id_jadwal': 9,
        'status': 'berlangsung',
        'jadwal': {
          'id_jadwal': 9,
          'lokasi_latitude': '-8.1600000',
          'lokasi_longitude': 113.72,
          'radius_meter': 75,
        },
      });
      expect(c.jadwalId, '9');
      expect(c.latitude, -8.16);
      expect(c.longitude, 113.72);
      expect(c.radiusMeter, 75);
    });

    test('tanpa koordinat → null (UI memakai default)', () {
      final c = TrainingClassModel.fromMap(
          {'id_kelas': 1, 'jadwal': <String, dynamic>{}});
      expect(c.latitude, isNull);
      expect(c.radiusMeter, isNull);
    });
  });

  group('AttendanceService', () {
    test('getAttendancePage: parse data + meta paginasi', () async {
      late Uri requested;
      final svc = _service((req) async {
        requested = req.url;
        return _json({
          'data': [_absen(id: 1), _absen(id: 2)],
          'meta': {'current_page': 1, 'last_page': 3},
        });
      });
      final page = await svc.getAttendancePage(page: 1, token: 't');
      expect(requested.queryParameters['page'], '1');
      expect(page.items, hasLength(2));
      expect(page.hasMore, isTrue);
    });

    test('halaman terakhir → hasMore false; 404 → kosong', () async {
      final last = await _service((_) async => _json({
            'data': [_absen(id: 1)],
            'meta': {'current_page': 3, 'last_page': 3},
          })).getAttendancePage(page: 3);
      expect(last.hasMore, isFalse);

      final empty =
          await _service((_) async => _json({}, 404)).getAttendancePage();
      expect(empty.items, isEmpty);
      expect(empty.hasMore, isFalse);
    });

    test('401 → unauthorized, 500 → server, bukan list kosong', () async {
      await expectLater(
        _service((_) async => _json({}, 401)).getAttendancePage(),
        throwsA(isA<AttendanceException>().having(
            (e) => e.type, 'type', AttendanceErrorType.unauthorized)),
      );
      await expectLater(
        _service((_) async => _json({}, 500)).getAttendancePage(),
        throwsA(isA<AttendanceException>()
            .having((e) => e.type, 'type', AttendanceErrorType.server)),
      );
    });

    test('kegagalan jaringan → AttendanceException(network)', () async {
      await expectLater(
        _service((_) async => throw const SocketException('down'))
            .getTodayAttendance(),
        throwsA(isA<AttendanceException>()
            .having((e) => e.type, 'type', AttendanceErrorType.network)),
      );
    });

    test('getTodayAttendance: data null (200) → null; ada data → item', () async {
      expect(
          await _service((_) async =>
                  _json({'message': 'Belum ada data', 'data': null}))
              .getTodayAttendance(),
          isNull);

      final item = await _service((_) async => _json({'data': _absen(id: 5)}))
          .getTodayAttendance();
      expect(item?.id, '5');
    });

    test('getAttendanceSummaryReport mem-parse rekap', () async {
      final rekap = await _service((_) async => _json({
            'data': {
              'summary': {
                'total_hadir': 2,
                'persentase_hadir': 100,
                'memenuhi_syarat': true,
              },
            },
          })).getAttendanceSummaryReport();
      expect(rekap?.totalHadir, 2);
      expect(rekap?.memenuhiSyarat, isTrue);
    });

    test('submitAttendance: sukses 201; gagal memakai pesan server', () async {
      final request = AttendanceSubmitRequest(
        jadwalId: '1',
        pesertaId: '7',
        tanggal: '2026-11-24',
        jamHadir: '08:00',
        status: 'hadir',
        latitude: -8.1,
        longitude: 113.7,
      );

      late Map<String, dynamic> sentBody;
      final ok = await _service((req) async {
        sentBody = json.decode(req.body) as Map<String, dynamic>;
        return _json({'data': _absen(id: 9)}, 201);
      }).submitAttendance(request, 'tok');
      expect(ok.items.single.id, '9');
      expect(sentBody['status_kehadiran'], 'hadir');
      expect(sentBody['latitude'], -8.1);

      await expectLater(
        _service((_) async => _json(
            {'message': 'Anda berada 250 meter dari lokasi pelatihan.'},
            403)).submitAttendance(request),
        throwsA(isA<AttendanceException>().having((e) => e.message, 'message',
            contains('250 meter'))),
      );
    });
  });

  group('AttendanceProvider', () {
    late FakeAttendanceRepository repo;
    late AttendanceProvider provider;

    setUp(() {
      repo = FakeAttendanceRepository();
      provider = AttendanceProvider(
        repository: repo,
        now: () => DateTime(2026, 11, 24, 9),
      );
    });

    test('fetch sukses mengisi riwayat, today, rekap', () async {
      repo.onPage = (_) async => AttendancePage(
          items: [AttendanceItem.fromMap(_absen(id: 1))], hasMore: true);
      repo.onToday = () async => AttendanceItem.fromMap(_absen(id: 1));
      repo.onRekap = () async => AttendanceRekap.fromMap({
            'summary': {'total_hadir': 18, 'total_sesi': 20, 'persentase_hadir': 90}
          });

      await provider.fetchAttendanceData('t');

      expect(provider.errorMessage, isNull);
      expect(provider.historyLoaded, isTrue);
      expect(provider.todayLoaded, isTrue);
      expect(provider.hasMore, isTrue);
      // Statistik memakai angka server, bukan hanya 1 item di halaman pertama
      expect(provider.summary.totalPresent, 18);
      expect(provider.attendancePercentage, 90);
    });

    test('gagal memuat → errorMessage terisi, today TIDAK dianggap dimuat',
        () async {
      repo.onToday = () async => throw const AttendanceException(
          'Koneksi timeout.', AttendanceErrorType.timeout);

      await provider.fetchAttendanceData();

      expect(provider.errorMessage, 'Koneksi timeout.');
      expect(provider.todayLoaded, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('rekap gagal tidak menggagalkan fetch (fallback hitungan lokal)',
        () async {
      repo.onPage = (_) async => AttendancePage(
          items: [AttendanceItem.fromMap(_absen(id: 1))], hasMore: false);
      repo.onRekap = () async =>
          throw const AttendanceException('x', AttendanceErrorType.server);

      await provider.fetchAttendanceData();

      expect(provider.errorMessage, isNull);
      expect(provider.summary.totalPresent, 1);
    });

    test('data lama dipertahankan saat refresh gagal', () async {
      repo.onPage = (_) async => AttendancePage(
          items: [AttendanceItem.fromMap(_absen(id: 1))], hasMore: false);
      await provider.fetchAttendanceData();

      repo.onPage = (_) async => throw const AttendanceException(
          'offline', AttendanceErrorType.network);
      await provider.fetchAttendanceData();

      expect(provider.errorMessage, 'offline');
      expect(provider.allAttendanceList, hasLength(1));
    });

    test('tanpa data: hasAttendanceData false, memenuhiSyarat null', () async {
      await provider.fetchAttendanceData();
      expect(provider.hasAttendanceData, isFalse);
      expect(provider.memenuhiSyarat, isNull);
    });

    test('memenuhiSyarat: server menang; fallback ambang minimal', () async {
      repo.onPage = (_) async => AttendancePage(items: [
            for (var i = 0; i < 4; i++) AttendanceItem.fromMap(_absen(id: i)),
            AttendanceItem.fromMap(_absen(id: 9, status: 'alpha')),
          ], hasMore: false);
      await provider.fetchAttendanceData();
      expect(provider.attendancePercentage, 80);
      expect(provider.memenuhiSyarat, isTrue);

      repo.onRekap = () async => AttendanceRekap.fromMap({
            'summary': {
              'total_hadir': 4,
              'total_alpha': 1,
              'memenuhi_syarat': false,
              'syarat_persentase': 90,
            }
          });
      await provider.fetchAttendanceData();
      expect(provider.memenuhiSyarat, isFalse);
      expect(provider.minimumPercentage, 90);
    });

    test('loadMore menambah halaman berikutnya; gagal → loadMoreFailed',
        () async {
      repo.onPage = (page) async => AttendancePage(
            items: [AttendanceItem.fromMap(_absen(id: page))],
            hasMore: page < 2,
          );
      await provider.fetchAttendanceData();
      expect(provider.allAttendanceList.map((e) => e.id), ['1']);

      await provider.loadMore();
      expect(provider.allAttendanceList.map((e) => e.id), ['1', '2']);
      expect(provider.hasMore, isFalse);

      // tidak ada halaman lagi → tidak memanggil repository
      var called = false;
      repo.onPage = (_) async {
        called = true;
        return const AttendancePage(items: [], hasMore: false);
      };
      await provider.loadMore();
      expect(called, isFalse);
    });

    test('loadMore gagal menandai loadMoreFailed dan bisa diulang', () async {
      repo.onPage = (page) async {
        if (page == 2) throw const AttendanceException('x', AttendanceErrorType.network);
        return AttendancePage(
            items: [AttendanceItem.fromMap(_absen(id: 1))], hasMore: true);
      };
      await provider.fetchAttendanceData();
      await provider.loadMore();
      expect(provider.loadMoreFailed, isTrue);
      expect(provider.allAttendanceList, hasLength(1));
    });

    test('filter hanya menampilkan status terpilih (alpha mencakup alpa)',
        () async {
      repo.onPage = (_) async => AttendancePage(items: [
            AttendanceItem.fromMap(_absen(id: 1)),
            AttendanceItem.fromMap(_absen(id: 2, status: 'alpa')),
            AttendanceItem.fromMap(_absen(id: 3, status: 'izin')),
          ], hasMore: false);
      await provider.fetchAttendanceData();

      provider.setFilter('alpha');
      expect(provider.attendanceList.map((e) => e.id), ['2']);
      provider.setFilter('Semua');
      expect(provider.attendanceList, hasLength(3));
    });

    test('todayRecordFor: per jadwal & hanya tanggal hari ini', () async {
      repo.onPage = (_) async => AttendancePage(items: [
            AttendanceItem.fromMap(_absen(id: 1, jadwal: 1)),
            AttendanceItem.fromMap(_absen(id: 2, jadwal: 2, tanggal: '2026-11-23')),
          ], hasMore: false);
      await provider.fetchAttendanceData();

      expect(provider.todayRecordFor('1')?.id, '1');
      expect(provider.todayRecordFor('2'), isNull); // kemarin
      expect(provider.todayRecordFor('3'), isNull);
    });

    test('submit sukses menambah riwayat & menandai today', () async {
      repo.onSubmit =
          (_) async => _result([AttendanceItem.fromMap(_absen(id: 50))]);
      await provider.submitAttendance(_request());

      expect(provider.todayAttendance?.id, '50');
      expect(provider.allAttendanceList.first.id, '50');
      expect(provider.todayLoaded, isTrue);
      expect(provider.isSubmitting, isFalse);
    });

    test('submit gagal melempar error & melepas flag isSubmitting', () async {
      repo.onSubmit = (_) async => throw const AttendanceException(
          'Sudah tercatat', AttendanceErrorType.validation, 422);

      await expectLater(
        provider.submitAttendance(_request()),
        throwsA(isA<AttendanceException>()),
      );
      expect(provider.isSubmitting, isFalse);
      expect(provider.allAttendanceList, isEmpty);
    });

    test('submit rentang menambah semua catatan (terbaru di atas) & today', () async {
      repo.onSubmit = (_) async => _result([
            AttendanceItem.fromMap(_absen(id: 1, tanggal: '2026-11-23', status: 'izin')),
            AttendanceItem.fromMap(_absen(id: 2, tanggal: '2026-11-24', status: 'izin')),
            AttendanceItem.fromMap(_absen(id: 3, tanggal: '2026-11-26', status: 'izin')),
          ], skipped: ['2026-11-25'], message: '3 hari presensi berhasil dicatat.');

      final result = await provider.submitAttendance(
          _request(status: 'izin', tanggal: '2026-11-23', tanggalSelesai: '2026-11-26'));

      expect(provider.allAttendanceList.map((e) => e.id), ['3', '2', '1']);
      expect(provider.todayAttendance?.id, '2'); // 24 Nov = hari ini (clock palsu)
      expect(result.skippedDates, ['2026-11-25']);
    });

    test('submit kedua saat yang pertama berjalan ditolak (anti ganda)', () async {
      final gate = Completer<AttendanceSubmitResult>();
      repo.onSubmit = (_) => gate.future;

      final first = provider.submitAttendance(_request());
      await expectLater(
        provider.submitAttendance(_request()),
        throwsA(isA<AttendanceException>()),
      );

      gate.complete(_result([AttendanceItem.fromMap(_absen(id: 1))]));
      await first;
      expect(repo.submitCalls, 1);
    });

    test('clockOut memperbarui catatan di riwayat & today', () async {
      repo.onPage = (_) async => AttendancePage(
          items: [AttendanceItem.fromMap(_absen(id: 5))], hasMore: false);
      repo.onToday = () async => AttendanceItem.fromMap(_absen(id: 5));
      await provider.fetchAttendanceData();
      expect(provider.todayAttendance!.canClockOut, isTrue);

      repo.onClockOut = (_) async => AttendanceItem.fromMap(
          {..._absen(id: 5), 'jam_keluar': '16:00:00', 'jarak_keluar_meter': 12.5});

      await provider.clockOut(absenId: '5', latitude: -8.1, longitude: 113.7);

      expect(provider.todayAttendance!.clockOutTime, '16:00:00');
      expect(provider.todayAttendance!.canClockOut, isFalse);
      expect(provider.allAttendanceList.single.jarakKeluarMeter, 12.5);
      // data presensi masuk tidak berubah
      expect(provider.allAttendanceList.single.clockInTime, '08:00');
      expect(provider.isSubmitting, isFalse);
    });

    test('clockOut gagal: state tidak berubah & error diteruskan', () async {
      repo.onPage = (_) async => AttendancePage(
          items: [AttendanceItem.fromMap(_absen(id: 5))], hasMore: false);
      await provider.fetchAttendanceData();

      repo.onClockOut = (_) async => throw const AttendanceException(
          'Anda berada 250 meter dari lokasi.', AttendanceErrorType.validation, 403);

      await expectLater(
        provider.clockOut(absenId: '5', latitude: 0, longitude: 0),
        throwsA(isA<AttendanceException>()),
      );
      expect(provider.allAttendanceList.single.hasClockedOut, isFalse);
      expect(provider.isSubmitting, isFalse);
    });
  });

  group('Presensi pulang, lampiran, rentang (model)', () {
    test('fromMap membaca jam_keluar, jarak_keluar_meter, lampiran_url', () {
      final item = AttendanceItem.fromMap({
        ..._absen(id: 1),
        'jam_keluar': '16:00:00',
        'jarak_keluar_meter': '18.25',
        'lampiran_url': 'http://x/storage/absen-lampiran/a.jpg',
      });
      expect(item.hasClockedOut, isTrue);
      expect(item.canClockOut, isFalse);
      expect(item.jarakKeluarMeter, 18.25);
      expect(item.attachmentUrl, 'http://x/storage/absen-lampiran/a.jpg');
    });

    test('canClockOut hanya untuk hadir yang belum pulang; lampiran kosong → null', () {
      expect(AttendanceItem.fromMap(_absen(id: 1)).canClockOut, isTrue);
      expect(AttendanceItem.fromMap(_absen(id: 1, status: 'izin')).canClockOut, isFalse);
      expect(AttendanceItem.fromMap({..._absen(id: 1), 'lampiran_url': ''}).attachmentUrl, isNull);
    });

    test('toMap menyertakan tanggal_selesai hanya bila ada', () {
      expect(_request(tanggalSelesai: '2026-11-26').toMap()['tanggal_selesai'], '2026-11-26');
      expect(_request().toMap().containsKey('tanggal_selesai'), isFalse);
    });

    test('formatApiTimeLabel & formatDateRangeLabel', () {
      expect(formatApiTimeLabel('08:05:00'), '08:05');
      expect(formatApiTimeLabel('08:05'), '08:05');
      expect(formatApiTimeLabel('-'), '-');
      expect(formatDateRangeLabel(DateTime(2026, 11, 24), DateTime(2026, 11, 24)),
          '24 November 2026');
      expect(formatDateRangeLabel(DateTime(2026, 11, 24), DateTime(2026, 11, 26)),
          '24 November 2026 – 26 November 2026');
    });
  });

  group('AttendanceService pulang, lampiran, rentang', () {
    test('submit rentang: parse daftar catatan + dilewati + pesan', () async {
      final result = await _service((_) async => _json({
            'data': [
              _absen(id: 1, tanggal: '2026-11-23', status: 'izin'),
              _absen(id: 2, tanggal: '2026-11-26', status: 'izin'),
            ],
            'message': '2 hari presensi berhasil dicatat.',
            'dilewati': ['2026-11-24'],
          }, 201))
          .submitAttendance(_request(status: 'izin', tanggalSelesai: '2026-11-26'));

      expect(result.items.map((e) => e.id), ['1', '2']);
      expect(result.skippedDates, ['2026-11-24']);
      expect(result.message, contains('2 hari'));
    });

    test('submit dengan lampiran dikirim sebagai multipart + field rentang', () async {
      final dir = Directory.systemTemp.createTempSync('absen_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/surat.jpg')..writeAsBytesSync([1, 2, 3, 4]);

      late http.BaseRequest sent;
      late String body;
      final result = await _service((req) async {
        sent = req;
        body = req.body;
        return _json({'data': _absen(id: 9, status: 'sakit')}, 201);
      }).submitAttendance(
        _request(
            status: 'sakit',
            tanggalSelesai: '2026-11-26',
            attachmentPath: file.path),
        'tok',
      );

      expect(sent.headers['content-type'], startsWith('multipart/form-data'));
      expect(sent.headers['Authorization'], 'Bearer tok');
      expect(body, contains('name="lampiran"'));
      expect(body, contains('filename="surat.jpg"'));
      expect(body, contains('name="tanggal_selesai"'));
      expect(body, contains('2026-11-26'));
      expect(result.items.single.status, 'sakit');
    });

    test('lampiran yang hilang → AttendanceException, tanpa request', () async {
      var called = false;
      await expectLater(
        _service((_) async {
          called = true;
          return _json({});
        }).submitAttendance(_request(
            status: 'izin', attachmentPath: '/tidak/ada/surat.jpg')),
        throwsA(isA<AttendanceException>().having(
            (e) => e.message, 'message', contains('Berkas lampiran'))),
      );
      expect(called, isFalse);
    });

    test('clockOut: POST /absen/{id}/pulang dengan koordinat, parse hasil', () async {
      late Uri url;
      late Map<String, dynamic> sentBody;
      final item = await _service((req) async {
        url = req.url;
        sentBody = json.decode(req.body) as Map<String, dynamic>;
        return _json({
          'data': {..._absen(id: 5), 'jam_keluar': '16:00:00'}
        });
      }).clockOut(absenId: '5', latitude: -8.1, longitude: 113.7, token: 't');

      expect(url.path, endsWith('/absen/5/pulang'));
      expect(sentBody, {'latitude': -8.1, 'longitude': 113.7});
      expect(item.clockOutTime, '16:00:00');
    });

    test('clockOut: 403 (di luar radius) & 422 memakai pesan server', () async {
      await expectLater(
        _service((_) async => _json(
                {'message': 'Anda berada 250 meter dari lokasi pelatihan.'}, 403))
            .clockOut(absenId: '5', latitude: 0, longitude: 0),
        throwsA(isA<AttendanceException>()
            .having((e) => e.message, 'message', contains('250 meter'))
            .having((e) => e.type, 'type', AttendanceErrorType.validation)),
      );
      await expectLater(
        _service((_) async => _json({'message': 'Presensi pulang sudah tercatat.'}, 422))
            .clockOut(absenId: '5', latitude: 0, longitude: 0),
        throwsA(isA<AttendanceException>()
            .having((e) => e.message, 'message', 'Presensi pulang sudah tercatat.')),
      );
    });

    test('clockOut: 401 → unauthorized', () async {
      await expectLater(
        _service((_) async => _json({}, 401))
            .clockOut(absenId: '5', latitude: 0, longitude: 0),
        throwsA(isA<AttendanceException>()
            .having((e) => e.type, 'type', AttendanceErrorType.unauthorized)),
      );
    });
  });

  group('AttendanceSubmitRequest', () {
    test('toMap menyertakan koordinat & keterangan hanya bila ada', () {
      final withAll = AttendanceSubmitRequest(
        jadwalId: '1',
        pesertaId: '7',
        tanggal: '2026-11-24',
        jamHadir: '08:00',
        status: 'hadir',
        notes: 'tepat waktu',
        latitude: -8.1,
        longitude: 113.7,
      ).toMap();
      expect(withAll['keterangan'], 'tepat waktu');
      expect(withAll['latitude'], -8.1);

      final minimal = AttendanceSubmitRequest(
        jadwalId: '1',
        pesertaId: '7',
        tanggal: '2026-11-24',
        jamHadir: '08:00',
        status: 'izin',
        notes: '',
      ).toMap();
      expect(minimal.containsKey('keterangan'), isFalse);
      expect(minimal.containsKey('latitude'), isFalse);
    });
  });
}
