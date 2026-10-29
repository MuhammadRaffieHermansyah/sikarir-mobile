class AttendanceItem {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String date;
  final String? clockInTime;
  final String? clockOutTime;
  final String status; // 'hadir', 'izin', 'sakit', 'alpha'
  final String? notes;
  final String? location;
  final String? photoUrl;
  final String? roomName;
  // GPS fields
  final double? latitude;
  final double? longitude;
  final double? jarakMeter;

  AttendanceItem({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.date,
    this.clockInTime,
    this.clockOutTime,
    required this.status,
    this.notes,
    this.location,
    this.photoUrl,
    this.roomName,
    this.latitude,
    this.longitude,
    this.jarakMeter,
  });

  factory AttendanceItem.fromMap(Map<String, dynamic> map) {
    return AttendanceItem(
      id: (map['id_absen'] ?? map['id'] ?? map['_id'] ?? '').toString(),
      userId: (map['id_peserta'] ?? map['user_id'] ?? map['userId'] ?? '').toString(),
      classId: (map['id_jadwal'] ?? map['kelas_pelatihan_id'] ?? map['class_id'] ?? map['classId'] ?? '').toString(),
      className: _resolveClassName(map),
      date: (map['tanggal'] ?? map['date'] ?? '').toString(),
      clockInTime: map['jam_hadir']?.toString() ?? map['jam_masuk']?.toString() ?? map['clock_in']?.toString(),
      clockOutTime: map['jam_keluar']?.toString() ?? map['clock_out']?.toString(),
      status: (map['status_kehadiran'] ?? map['status'] ?? 'hadir').toString().toLowerCase(),
      notes: map['keterangan']?.toString() ?? map['notes']?.toString(),
      location: map['lokasi']?.toString() ?? map['location']?.toString(),
      photoUrl: map['foto']?.toString() ?? map['photo_url']?.toString(),
      roomName: _resolveRoomName(map),
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      jarakMeter: _toDouble(map['jarak_meter']),
    );
  }

  static String _resolveClassName(Map<String, dynamic> map) {
    final jadwal = map['jadwal'];
    if (jadwal is Map<String, dynamic>) {
      final pelatihan = jadwal['pelatihan'];
      if (pelatihan is Map<String, dynamic>) {
        return pelatihan['nama_pelatihan']?.toString() ?? 'Kelas Pelatihan';
      }
    }
    return (map['nama_kelas'] ?? map['kelas_nama'] ?? map['class_name'] ?? 'Kelas Pelatihan').toString();
  }

  static String? _resolveRoomName(Map<String, dynamic> map) {
    final jadwal = map['jadwal'];
    if (jadwal is Map<String, dynamic>) {
      final ruangan = jadwal['ruangan_workshop'];
      if (ruangan is Map<String, dynamic>) {
        return ruangan['nama_ruangan']?.toString();
      }
      return jadwal['tempat']?.toString();
    }
    return map['ruangan']?.toString() ?? map['room_name']?.toString();
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Map<String, dynamic> toMap() {
    return {
      'id_absen': id,
      'id_peserta': userId,
      'id_jadwal': classId,
      'tanggal': date,
      'jam_hadir': clockInTime,
      'status_kehadiran': status,
      'keterangan': notes,
      'lokasi': location,
      'foto': photoUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (jarakMeter != null) 'jarak_meter': jarakMeter,
    };
  }
}

class AttendanceSummary {
  final int totalPresent;
  final int totalPermission;
  final int totalSick;
  final int totalAbsent;
  final double attendancePercentage;

  AttendanceSummary({
    required this.totalPresent,
    required this.totalPermission,
    required this.totalSick,
    required this.totalAbsent,
    required this.attendancePercentage,
  });

  factory AttendanceSummary.fromList(List<AttendanceItem> list) {
    int present = 0;
    int permission = 0;
    int sick = 0;
    int absent = 0;

    for (final item in list) {
      final s = item.status.toLowerCase();
      if (s == 'hadir') {
        present++;
      } else if (s == 'izin') {
        permission++;
      } else if (s == 'sakit') {
        sick++;
      } else if (s == 'alpa' || s == 'alpha') {
        absent++;
      }
    }

    final totalDays = present + permission + sick + absent;
    final pct = totalDays > 0 ? (present / totalDays) * 100 : 100.0;

    return AttendanceSummary(
      totalPresent: present,
      totalPermission: permission,
      totalSick: sick,
      totalAbsent: absent,
      attendancePercentage: pct,
    );
  }
}

class AttendanceSubmitRequest {
  final String jadwalId;
  final String pesertaId;
  final String tanggal;
  final String jamHadir;
  final String status; // 'hadir', 'izin', 'sakit', 'alpha'
  final String? notes;
  final double? latitude;
  final double? longitude;

  AttendanceSubmitRequest({
    required this.jadwalId,
    required this.pesertaId,
    required this.tanggal,
    required this.jamHadir,
    required this.status,
    this.notes,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_jadwal': jadwalId,
      'id_peserta': pesertaId,
      'tanggal': tanggal,
      'jam_hadir': jamHadir,
      'status_kehadiran': status,
      if (notes != null && notes!.isNotEmpty) 'keterangan': notes,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
