import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/data/services/attendance_service.dart';
import 'package:sikarir/features/instructor/data/models/attendance_session_model.dart';

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

  Future<AttendanceSession?> getOpenSession(String classId, [String? token]) {
    return service.getOpenSession(classId, token);
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

}
