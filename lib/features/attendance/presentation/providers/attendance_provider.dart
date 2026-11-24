import 'package:flutter/foundation.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/data/repositories/attendance_repository.dart';
import 'package:sikarir/features/attendance/data/services/attendance_service.dart';
import 'package:sikarir/features/attendance/utils/attendance_formatters.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository repository;
  final DateTime Function() _now;

  AttendanceProvider({
    AttendanceRepository? repository,
    DateTime Function()? now,
  })  : repository = repository ?? AttendanceRepository(),
        _now = now ?? DateTime.now;

  // ─── State ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  // true hanya jika data terkait berhasil diperiksa ke server.
  bool _todayLoaded = false;
  bool _historyLoaded = false;
  bool _loadMoreFailed = false;
  bool _hasMore = false;
  int _page = 1;

  List<AttendanceItem> _attendanceList = [];
  AttendanceItem? _todayAttendance;
  AttendanceRekap? _rekap;
  String? _errorMessage;
  String _selectedFilter = 'Semua';

  // ─── Getters ─────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  bool get todayLoaded => _todayLoaded;
  bool get historyLoaded => _historyLoaded;
  bool get hasMore => _hasMore;
  bool get loadMoreFailed => _loadMoreFailed;

  AttendanceRekap? get rekap => _rekap;

  List<AttendanceItem> get attendanceList {
    if (_selectedFilter == 'Semua') return _attendanceList;
    return _attendanceList
        .where((item) => item.status == _selectedFilter)
        .toList();
  }

  List<AttendanceItem> get allAttendanceList => _attendanceList;
  AttendanceItem? get todayAttendance => _todayAttendance;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;

  /// Ringkasan: utamakan angka server (mencakup seluruh riwayat); fallback
  /// ke hitungan dari data yang sudah dimuat.
  AttendanceSummary get summary =>
      _rekap?.toSummary() ?? AttendanceSummary.fromList(_attendanceList);

  double get attendancePercentage => summary.attendancePercentage;

  /// Apakah ada catatan kehadiran sama sekali.
  bool get hasAttendanceData => summary.hasData;

  double get minimumPercentage =>
      _rekap?.minimalPersentase ?? AttendanceSummary.minimumPercentage;

  /// Status kelayakan: utamakan server, fallback ambang minimal.
  /// `null` bila belum ada data sama sekali.
  bool? get memenuhiSyarat {
    if (!hasAttendanceData) return null;
    return _rekap?.memenuhiSyarat ?? attendancePercentage >= minimumPercentage;
  }

  String? get statusKelayakan => _rekap?.statusKelayakan;

  /// Catatan presensi hari ini untuk jadwal tertentu (backend mengizinkan satu
  /// presensi per jadwal per hari). `null` bila belum ada.
  AttendanceItem? todayRecordFor(String jadwalId) {
    final today = formatApiDate(_now());
    for (final item in _attendanceList) {
      if (item.classId == jadwalId && item.date.startsWith(today)) return item;
    }
    final t = _todayAttendance;
    if (t != null && t.classId == jadwalId) return t;
    return null;
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> fetchAttendanceData([String? token]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Ambil riwayat, presensi hari ini, dan rekapitulasi secara paralel.
    // Tiap request ditangani sendiri agar satu kegagalan tidak menimpa data
    // lain, dan data lama tetap tampil saat refresh gagal.
    String? error;

    Future<void> run(Future<void> Function() job) async {
      try {
        await job();
      } catch (e) {
        error ??= e.toString().replaceFirst('Exception: ', '');
      }
    }

    await Future.wait([
      run(() async {
        final page = await repository.getAttendancePage(page: 1, token: token);
        _attendanceList = page.items;
        _page = 1;
        _hasMore = page.hasMore;
        _loadMoreFailed = false;
        _historyLoaded = true;
      }),
      run(() async {
        _todayAttendance = await repository.getTodayAttendance(token);
        _todayLoaded = true;
      }),
      // Rekap bersifat pelengkap: gagal → fallback ke hitungan lokal.
      () async {
        try {
          _rekap = await repository.getAttendanceSummaryReport(token);
        } catch (e) {
          if (kDebugMode) debugPrint('Rekap error: $e');
        }
      }(),
    ]);

    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Muat halaman riwayat berikutnya.
  Future<void> loadMore([String? token]) async {
    if (_isLoadingMore || _isLoading || !_hasMore) return;
    _isLoadingMore = true;
    _loadMoreFailed = false;
    notifyListeners();

    try {
      final next = _page + 1;
      final page = await repository.getAttendancePage(page: next, token: token);
      _attendanceList = [..._attendanceList, ...page.items];
      _page = next;
      _hasMore = page.hasMore;
    } catch (e) {
      _loadMoreFailed = true;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Submit presensi (hadir / izin / sakit). Melempar error ke pemanggil.
  /// Rentang izin/sakit menambahkan beberapa catatan sekaligus.
  Future<AttendanceSubmitResult> submitAttendance(
    AttendanceSubmitRequest request, [
    String? token,
  ]) async {
    if (_isSubmitting) {
      throw const AttendanceException(
        'Presensi sedang diproses. Mohon tunggu.',
        AttendanceErrorType.validation,
      );
    }
    _isSubmitting = true;
    notifyListeners();

    try {
      final result = await repository.submitAttendance(request, token);
      final today = formatApiDate(_now());
      for (final item in result.items) {
        if (item.date.startsWith(today)) _todayAttendance = item;
      }
      _todayLoaded = true;
      _attendanceList = [...result.items.reversed, ..._attendanceList];
      return result;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Presensi pulang untuk catatan [absenId]; memperbarui catatan di state.
  Future<AttendanceItem> clockOut({
    required String absenId,
    required double latitude,
    required double longitude,
    String? token,
  }) async {
    if (_isSubmitting) {
      throw const AttendanceException(
        'Presensi sedang diproses. Mohon tunggu.',
        AttendanceErrorType.validation,
      );
    }
    _isSubmitting = true;
    notifyListeners();

    try {
      final updated = await repository.clockOut(
        absenId: absenId,
        latitude: latitude,
        longitude: longitude,
        token: token,
      );
      _attendanceList = [
        for (final item in _attendanceList)
          item.id == absenId ? item.copyWithClockOut(updated) : item,
      ];
      if (_todayAttendance?.id == absenId) {
        _todayAttendance = _todayAttendance!.copyWithClockOut(updated);
      }
      return updated;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
