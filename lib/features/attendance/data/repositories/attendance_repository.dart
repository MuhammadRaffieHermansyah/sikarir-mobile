import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/data/services/attendance_service.dart';

class AttendanceRepository {
  final AttendanceService service;

  AttendanceRepository({AttendanceService? service})
      : service = service ?? AttendanceService();

  Future<List<AttendanceItem>> getAttendanceList([String? token]) async {
    return await service.getAttendanceList(token);
  }

  Future<AttendanceItem?> getTodayAttendance([String? token]) async {
    return await service.getTodayAttendance(token);
  }

  Future<AttendanceItem> submitAttendance(
    AttendanceSubmitRequest request, [
    String? token,
  ]) async {
    return await service.submitAttendance(request, token);
  }

  Future<AttendanceItem> submitClockOut(
    String attendanceId, [
    String? token,
  ]) async {
    return await service.submitClockOut(attendanceId, token);
  }
}
