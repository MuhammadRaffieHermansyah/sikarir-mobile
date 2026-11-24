import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/data/services/attendance_service.dart';

class AttendanceRepository {
  final AttendanceService service;

  AttendanceRepository({AttendanceService? service})
      : service = service ?? AttendanceService();

  Future<AttendancePage> getAttendancePage({int page = 1, String? token}) {
    return service.getAttendancePage(page: page, token: token);
  }

  Future<AttendanceItem?> getTodayAttendance([String? token]) {
    return service.getTodayAttendance(token);
  }

  Future<AttendanceRekap?> getAttendanceSummaryReport([String? token]) {
    return service.getAttendanceSummaryReport(token);
  }

  Future<AttendanceSubmitResult> submitAttendance(
    AttendanceSubmitRequest request, [
    String? token,
  ]) {
    return service.submitAttendance(request, token);
  }

  Future<AttendanceItem> clockOut({
    required String absenId,
    required double latitude,
    required double longitude,
    String? token,
  }) {
    return service.clockOut(
      absenId: absenId,
      latitude: latitude,
      longitude: longitude,
      token: token,
    );
  }
}
