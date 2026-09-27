import 'package:flutter/foundation.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/data/repositories/attendance_repository.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository repository;

  AttendanceProvider({AttendanceRepository? repository})
      : repository = repository ?? AttendanceRepository();

  bool _isLoading = false;
  List<AttendanceItem> _attendanceList = [];
  AttendanceItem? _todayAttendance;
  AttendanceSummary? _summary;
  String? _errorMessage;
  String _selectedFilter = 'Semua'; // 'Semua', 'hadir', 'izin', 'sakit'

  bool get isLoading => _isLoading;
  List<AttendanceItem> get attendanceList {
    if (_selectedFilter == 'Semua') {
      return _attendanceList;
    }
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

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> fetchAttendanceData([String? token]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await repository.getAttendanceList(token);
      _attendanceList = list;
      _summary = AttendanceSummary.fromList(list);

      // Check if today already checked in
      if (_todayAttendance == null && list.isNotEmpty) {
        final nowStr = '${DateTime.now().day}';
        final match = list.where((item) => item.date.contains(nowStr));
        if (match.isNotEmpty) {
          _todayAttendance = match.first;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<void> clockOut([String? token]) async {
    if (_todayAttendance == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await repository.submitClockOut(_todayAttendance!.id, token);
      _todayAttendance = updated;
      final index = _attendanceList.indexWhere((e) => e.id == updated.id);
      if (index != -1) {
        _attendanceList[index] = updated;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
