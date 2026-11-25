/// Sesi presensi yang dibuat instruktur untuk satu pertemuan kelas.
class AttendanceSession {
  final String id;
  final String classId;
  final int meetingNumber;
  final String date; // yyyy-MM-dd
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final double? latitude;
  final double? longitude;
  final int radiusMeter;
  final bool isOpen;
  final int presentCount;

  const AttendanceSession({
    required this.id,
    required this.classId,
    required this.meetingNumber,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.latitude,
    this.longitude,
    required this.radiusMeter,
    required this.isOpen,
    this.presentCount = 0,
  });

  static double? _num(dynamic v) => v == null
      ? null
      : (v is num ? v.toDouble() : double.tryParse(v.toString()));

  static String _hm(dynamic v, String fallback) {
    final s = v?.toString() ?? '';
    return s.length >= 5 ? s.substring(0, 5) : fallback;
  }

  static bool _bool(dynamic v) =>
      v == true || v == 1 || v == '1' || v == 'dibuka';

  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    return AttendanceSession(
      id: (map['id_sesi'] ?? map['id'] ?? '').toString(),
      classId: (map['id_kelas'] ?? '').toString(),
      meetingNumber:
          int.tryParse('${map['pertemuan_ke'] ?? map['sesi_ke'] ?? 1}') ?? 1,
      date: (map['tanggal'] ?? '').toString().split('T').first,
      startTime: _hm(map['jam_mulai'], '08:00'),
      endTime: _hm(map['jam_selesai'], '15:00'),
      latitude: _num(map['lokasi_latitude'] ?? map['latitude']),
      longitude: _num(map['lokasi_longitude'] ?? map['longitude']),
      radiusMeter: int.tryParse('${map['radius_meter'] ?? 100}') ?? 100,
      isOpen: _bool(map['absen_dibuka'] ?? map['dibuka'] ?? map['status']),
      presentCount:
          int.tryParse('${map['jumlah_hadir'] ?? map['hadir_count'] ?? 0}') ??
          0,
    );
  }
}

/// Input pembuatan sesi presensi.
class AttendanceSessionInput {
  final int meetingNumber;
  final String date;
  final String startTime;
  final String endTime;
  final double? latitude;
  final double? longitude;
  final int radiusMeter;

  const AttendanceSessionInput({
    required this.meetingNumber,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.latitude,
    this.longitude,
    required this.radiusMeter,
  });

  Map<String, dynamic> toMap() => {
    'pertemuan_ke': meetingNumber,
    'tanggal': date,
    'jam_mulai': startTime,
    'jam_selesai': endTime,
    if (latitude != null) 'lokasi_latitude': latitude,
    if (longitude != null) 'lokasi_longitude': longitude,
    'radius_meter': radiusMeter,
  };
}
