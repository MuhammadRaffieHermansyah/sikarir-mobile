import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/data/repositories/attendance_repository.dart';
import 'package:sikarir/features/attendance/data/services/location_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository repository;

  AttendanceProvider({AttendanceRepository? repository})
      : repository = repository ?? AttendanceRepository();

  // ─── State ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isCheckingLocation = false;
  List<AttendanceItem> _attendanceList = [];
  AttendanceItem? _todayAttendance;
  AttendanceSummary? _summary;
  String? _errorMessage;
  String _selectedFilter = 'Semua';

  // Lokasi GPS
  Position? _currentPosition;
  LocationCheckResult? _locationCheck;
  String? _locationError;
  LocationExceptionType? _locationErrorType;

  // Laporan Rekapitulasi Kehadiran
  Map<String, dynamic>? _rekapData;

  // ─── Getters ─────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isCheckingLocation => _isCheckingLocation;

  Map<String, dynamic>? get rekapData => _rekapData;
  Map<String, dynamic>? get rekapSummary => _rekapData?['summary'] as Map<String, dynamic>?;
  String get statusKelayakan =>
      rekapSummary?['status_kelayakan']?.toString() ?? 'Memenuhi Syarat Sertifikasi';
  bool get memenuhiSyarat => rekapSummary?['memenuhi_syarat'] == true;

  List<AttendanceItem> get attendanceList {
    if (_selectedFilter == 'Semua') return _attendanceList;
    return _attendanceList
        .where((item) => item.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  List<AttendanceItem> get allAttendanceList => _attendanceList;
  AttendanceItem? get todayAttendance => _todayAttendance;
  AttendanceSummary get summary =>
      _summary ?? AttendanceSummary.fromList(_attendanceList);
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;

  Position? get currentPosition => _currentPosition;
  LocationCheckResult? get locationCheck => _locationCheck;
  String? get locationError => _locationError;
  LocationExceptionType? get locationErrorType => _locationErrorType;

  bool get isInsideRadius => _locationCheck?.isValid ?? false;
  bool get hasLocation => _currentPosition != null;

  // ─── Actions ─────────────────────────────────────────────────────────────

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> fetchAttendanceData([String? token]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ambil riwayat, presensi hari ini, dan rekapitulasi secara paralel
      final results = await Future.wait([
        repository.getAttendanceList(token),
        repository.getTodayAttendance(token),
        repository.getAttendanceSummaryReport(token),
      ]);

      _attendanceList = results[0] as List<AttendanceItem>;
      _todayAttendance = results[1] as AttendanceItem?;
      _rekapData = results[2] as Map<String, dynamic>?;
      _summary = AttendanceSummary.fromList(_attendanceList);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ambil koordinat GPS saat ini dan validasi terhadap lokasi pelatihan.
  Future<bool> checkCurrentLocation({
    double targetLat = LocationService.defaultLat,
    double targetLng = LocationService.defaultLng,
    int radiusMeter = LocationService.defaultRadius,
  }) async {
    _isCheckingLocation = true;
    _locationError = null;
    _locationErrorType = null;
    _currentPosition = null;
    _locationCheck = null;
    notifyListeners();

    try {
      final position = await LocationService.getCurrentPosition();
      _currentPosition = position;
      _locationCheck = LocationService.cekLokasiValid(
        position: position,
        targetLat: targetLat,
        targetLng: targetLng,
        radiusMeter: radiusMeter,
      );
      return _locationCheck!.isValid;
    } on LocationException catch (e) {
      _locationError = e.message;
      _locationErrorType = e.type;
      return false;
    } catch (e) {
      _locationError = 'Gagal mendapatkan lokasi: ${e.toString()}';
      _locationErrorType = LocationExceptionType.unknown;
      return false;
    } finally {
      _isCheckingLocation = false;
      notifyListeners();
    }
  }

  /// Submit presensi hadir dengan validasi GPS
  Future<void> submitAttendance(
    AttendanceSubmitRequest request, [
    String? token,
  ]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.submitAttendance(request, token);
      _todayAttendance = result;
      _attendanceList.insert(0, result);
      _summary = AttendanceSummary.fromList(_attendanceList);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearLocationState() {
    _currentPosition = null;
    _locationCheck = null;
    _locationError = null;
    _locationErrorType = null;
    notifyListeners();
  }
}
