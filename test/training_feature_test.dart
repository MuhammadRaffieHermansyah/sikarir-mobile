import 'package:flutter_test/flutter_test.dart';
import 'package:sikarir/features/training/data/models/training_catalog_model.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';
import 'package:sikarir/features/training/data/models/training_schedule_model.dart';
import 'package:sikarir/features/training/data/repositories/training_class_repository.dart';
import 'package:sikarir/features/training/data/services/training_class_service.dart';
import 'package:sikarir/features/training/presentation/providers/training_class_provider.dart';

// Mock Service for Unit Testing
class MockTrainingClassService extends TrainingClassService {
  bool enrollCalled = false;
  String? lastEnrolledJadwalId;

  @override
  Future<List<TrainingCatalogModel>> getCatalog([String? token]) async {
    return [
      TrainingCatalogModel(
        id: '1',
        jadwalId: '10',
        title: 'Desain Grafis & Motion Advertising',
        description: 'Kuasai visual branding',
        category: 'TIK & INFORMATIKA',
        skkniCode: 'SKKNI No. M.74100.001.02',
        badge: 'BNSP Level 3',
        duration: '40 JP',
        location: 'BLK Jember',
        quota: 20,
        enrolledCount: 16,
        remainingQuota: 4,
        instructor: 'Dimas Wicaksono',
        startDate: '2026-09-01',
        endDate: '2026-10-30',
        imageUrl: 'https://example.com/image.jpg',
      ),
      TrainingCatalogModel(
        id: '2',
        jadwalId: '20',
        title: 'Teknik Las Industri 3G/4G SMAW',
        description: 'Spesialisasi pengelasan',
        category: 'MANUFAKTUR & LAS',
        skkniCode: 'SKKNI No. C.25920.001.01',
        badge: 'Sertifikasi Migas',
        duration: '320 JP',
        location: 'BBVP Serang',
        quota: 16,
        enrolledCount: 16,
        remainingQuota: 0,
        instructor: 'Bambang Sugiarto',
        startDate: '2026-09-15',
        endDate: '2026-11-10',
        imageUrl: 'https://example.com/welding.jpg',
      ),
    ];
  }

  @override
  Future<List<TrainingClassModel>> getMyClasses([String? token]) async {
    return [
      TrainingClassModel(
        id: 'c1',
        pelatihanId: '1',
        jadwalId: '10',
        title: 'Desain Grafis & Motion Advertising',
        code: 'BLK-JBR-DG01',
        category: 'TIK & INFORMATIKA',
        instructor: 'Dimas Wicaksono',
        room: 'Lab Komputer 02',
        startDate: '2026-09-01',
        endDate: '2026-10-30',
        totalSessions: 24,
        completedSessions: 16,
        progress: 0.68,
        status: 'berlangsung',
        description: 'Kelas aktif',
      ),
    ];
  }

  @override
  Future<bool> enrollTraining({
    required String jadwalId,
    String? pesertaId,
    String? token,
  }) async {
    enrollCalled = true;
    lastEnrolledJadwalId = jadwalId;
    return true;
  }
}

// Error Mock Service
class ErrorTrainingClassService extends TrainingClassService {
  @override
  Future<List<TrainingCatalogModel>> getCatalog([String? token]) async {
    throw Exception('Tidak dapat terhubung ke server. Silakan coba lagi beberapa saat.');
  }

  @override
  Future<List<TrainingClassModel>> getMyClasses([String? token]) async {
    throw Exception('Gagal memuat kelas pelatihan saya.');
  }
}

void main() {
  group('Training Feature Unit Tests', () {
    test('TrainingCatalogModel parses JSON correctly', () {
      final jsonMap = {
        'id_pelatihan': 5,
        'nama_pelatihan': 'Pemrograman Flutter & Android',
        'deskripsi_pelatihan': 'Membangun aplikasi mobile profesional',
        'kuota': 25,
        'durasi': {'hari': 30, 'jam': 180},
        'jadwal': [
          {
            'id_jadwal': 99,
            'tempat': 'Workshop Informatika BLK',
            'tanggal_mulai': '2026-10-01',
            'tanggal_selesai': '2026-11-15',
            'status': 'tersedia',
            'instruktur': {
              'user': {'name': 'Rian Hidayat'}
            }
          }
        ],
      };

      final model = TrainingCatalogModel.fromMap(jsonMap);

      expect(model.id, '5');
      expect(model.jadwalId, '99');
      expect(model.title, 'Pemrograman Flutter & Android');
      expect(model.category, 'TIK & INFORMATIKA');
      expect(model.duration, '30 Hari (180 JP)');
      expect(model.location, 'Workshop Informatika BLK');
      expect(model.instructor, 'Rian Hidayat');
      expect(model.quota, 25);
    });

    test('TrainingClassModel parses JSON with materials and progress', () {
      final jsonMap = {
        'id_kelas': 101,
        'pelatihan_id': 5,
        'id_jadwal': 99,
        'nama_kelas': 'Flutter Specialist',
        'kode_kelas': 'BLK-FLT-01',
        'kategori': 'TIK',
        'instruktur': 'Rian Hidayat',
        'ruangan': 'Lab 1',
        'tanggal_mulai': '2026-10-01',
        'tanggal_selesai': '2026-11-15',
        'total_sesi': 20,
        'sesi_selesai': 10,
        'status': 'berlangsung',
        'deskripsi': 'Belajar flutter',
        'materi': [
          {
            'id': 'm1',
            'judul': 'Widget Dasar',
            'tipe': 'pdf',
            'durasi': '45 Menit',
            'is_completed': true,
          }
        ]
      };

      final model = TrainingClassModel.fromMap(jsonMap);

      expect(model.id, '101');
      expect(model.pelatihanId, '5');
      expect(model.jadwalId, '99');
      expect(model.progress, 0.5);
      expect(model.materials.length, 1);
      expect(model.materials.first.title, 'Widget Dasar');
      expect(model.materials.first.isCompleted, true);
    });

    test('TrainingScheduleModel parses session and attendance open status', () {
      final jsonMap = {
        'id_jadwal': 44,
        'id_pelatihan': 1,
        'sesi_ke': 3,
        'judul_sesi': 'Praktik Desain Figma',
        'tempat': 'Lab 02 BLK',
        'absen_dibuka': true,
        'status': 'berlangsung',
      };

      final model = TrainingScheduleModel.fromMap(jsonMap);

      expect(model.id, '44');
      expect(model.sessionNumber, 3);
      expect(model.title, 'Praktik Desain Figma');
      expect(model.isAttendanceOpen, true);
    });

    test('TrainingClassProvider fetches catalog, filters, and detects enrollment', () async {
      final mockService = MockTrainingClassService();
      final repository = TrainingClassRepository(service: mockService);
      final provider = TrainingClassProvider(repository: repository);

      // 1. Fetch classes & catalog
      await provider.fetchClasses('test-token');
      await provider.fetchCatalog('test-token');

      expect(provider.allClasses.length, 1);
      expect(provider.allCatalog.length, 2);

      // Item 1 should have isEnrolled == true because user is enrolled in pelatihanId '1'
      final catalogItems = provider.catalog;
      final item1 = catalogItems.firstWhere((c) => c.id == '1');
      expect(item1.isEnrolled, true);

      final item2 = catalogItems.firstWhere((c) => c.id == '2');
      expect(item2.isEnrolled, false);

      // 2. Search query filter
      provider.setSearchQuery('Las');
      expect(provider.catalog.length, 1);
      expect(provider.catalog.first.id, '2');

      provider.setSearchQuery('');
      expect(provider.catalog.length, 2);

      // 3. Category filter
      provider.setCatalogFilter('MANUFAKTUR & LAS');
      expect(provider.catalog.length, 1);
      expect(provider.catalog.first.id, '2');

      provider.setCatalogFilter('Semua');
      expect(provider.catalog.length, 2);

      // 4. Enroll Training
      final enrollSuccess = await provider.enrollTraining(
        jadwalId: '20',
        token: 'test-token',
      );
      expect(enrollSuccess, true);
      expect(mockService.enrollCalled, true);
      expect(mockService.lastEnrolledJadwalId, '20');
    });

    test('TrainingClassProvider handles API error and empty response properly', () async {
      final errorService = ErrorTrainingClassService();
      final repository = TrainingClassRepository(service: errorService);
      final provider = TrainingClassProvider(repository: repository);

      await provider.fetchCatalog('test-token');
      expect(provider.catalogError, contains('Tidak dapat terhubung ke server'));
      expect(provider.catalog.isEmpty, true);

      await provider.fetchClasses('test-token');
      expect(provider.errorMessage, contains('Gagal memuat kelas'));
      expect(provider.classes.isEmpty, true);
    });
  });
}
