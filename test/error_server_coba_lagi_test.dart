import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/job/data/repositories/job_repository.dart';
import 'package:sikarir/features/job/data/services/job_service.dart';
import 'package:sikarir/features/job/presentation/providers/job_provider.dart';
import 'package:sikarir/features/partner/data/services/partner_service.dart';
import 'package:sikarir/features/training/data/repositories/training_schedule_repository.dart';
import 'package:sikarir/features/training/data/services/training_schedule_service.dart';
import 'package:sikarir/features/training/presentation/pages/training_schedule_screen.dart';
import 'package:sikarir/features/training/presentation/providers/training_schedule_provider.dart';

/// Klien yang selalu gagal terhubung (server mati).
MockClient _serverMati() => MockClient((_) async => throw http.ClientException('Connection refused'));

MockClient _respons(int status, String body) => MockClient((_) async => http.Response(body, status));

void main() {
  group('Lowongan tanpa data contoh', () {
    test('server mati → provider menyimpan pesan error, bukan lowongan contoh', () async {
      final provider = JobProvider(
        repository: JobRepository(service: JobService(client: _serverMati())),
      );

      await provider.fetchJobs('token');

      expect(provider.errorMessage, isNotNull);
      expect(provider.allJobs, isEmpty);
      expect(provider.isOffline, isFalse);
    });
  });

  group('Mitra tanpa data contoh', () {
    test('server mati → PartnerApiException', () async {
      final service = PartnerService(client: _serverMati());

      expect(service.getPartners('token'), throwsA(isA<PartnerApiException>()));
    });

    test('status bukan 200 → PartnerApiException', () async {
      final service = PartnerService(client: _respons(500, '{}'));

      expect(service.getPartners('token'), throwsA(isA<PartnerApiException>()));
    });

    test('daftar kosong dari server → list kosong, bukan mitra contoh', () async {
      final service = PartnerService(client: _respons(200, '{"data": []}'));

      expect(await service.getPartners('token'), isEmpty);
    });
  });

  group('Jadwal tanpa data contoh', () {
    test('server mati → Exception, daftar kosong → list kosong', () async {
      expect(
        TrainingScheduleService(client: _serverMati()).getSchedules('token'),
        throwsA(isA<Exception>()),
      );
      expect(
        await TrainingScheduleService(client: _respons(200, '{"data": []}')).getSchedules('token'),
        isEmpty,
      );
    });

    testWidgets('layar Semua Jadwal menampilkan pesan error dan Coba lagi', (tester) async {
      var panggil = 0;
      final client = MockClient((_) async {
        panggil++;
        if (panggil == 1) throw http.ClientException('Connection refused');
        return http.Response('{"data": []}', 200);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(
              create: (_) => TrainingScheduleProvider(
                repository: TrainingScheduleRepository(service: TrainingScheduleService(client: client)),
              ),
            ),
          ],
          child: const MaterialApp(home: TrainingScheduleScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Tidak dapat terhubung ke server BLK'), findsOneWidget);
      expect(find.text('Desain Grafis & UI/UX'), findsNothing);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada jadwal pelatihan pada kategori ini.'), findsOneWidget);
    });
  });
}
