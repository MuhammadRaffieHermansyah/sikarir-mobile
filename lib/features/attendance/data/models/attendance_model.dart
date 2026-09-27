class AttendanceItem {
  final String id;
  final String userId;
  final String classId;
  final String className;
  final String date;
  final String? clockInTime;
  final String? clockOutTime;
  final String status; // 'hadir', 'izin', 'sakit', 'alpa'
  final String? notes;
  final String? location;
  final String? photoUrl;
  final String? roomName;

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
  });

  factory AttendanceItem.fromMap(Map<String, dynamic> map) {
    return AttendanceItem(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
      classId: (map['kelas_pelatihan_id'] ?? map['class_id'] ?? map['classId'] ?? '').toString(),
      className: (map['nama_kelas'] ?? map['kelas_nama'] ?? map['class_name'] ?? 'Kelas Pelatihan').toString(),
      date: (map['tanggal'] ?? map['date'] ?? '').toString(),
      clockInTime: map['jam_masuk']?.toString() ?? map['clock_in']?.toString(),
      clockOutTime: map['jam_keluar']?.toString() ?? map['clock_out']?.toString(),
      status: (map['status'] ?? 'hadir').toString().toLowerCase(),
      notes: map['keterangan']?.toString() ?? map['notes']?.toString(),
      location: map['lokasi']?.toString() ?? map['location']?.toString(),
      photoUrl: map['foto']?.toString() ?? map['photo_url']?.toString(),
      roomName: map['ruangan']?.toString() ?? map['room_name']?.toString() ?? 'Lab Komputer 02',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'kelas_pelatihan_id': classId,
      'nama_kelas': className,
      'tanggal': date,
      'jam_masuk': clockInTime,
      'jam_keluar': clockOutTime,
      'status': status,
      'keterangan': notes,
      'lokasi': location,
      'foto': photoUrl,
      'ruangan': roomName,
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
  final String classId;
  final String status; // 'hadir', 'izin', 'sakit'
  final String? notes;
  final String? location;
  final String? photoBase64;

  AttendanceSubmitRequest({
    required this.classId,
    required this.status,
    this.notes,
    this.location,
    this.photoBase64,
  });

  Map<String, dynamic> toMap() {
    return {
      'kelas_pelatihan_id': classId,
      'status': status,
      if (notes != null) 'keterangan': notes,
      if (location != null) 'lokasi': location,
      if (photoBase64 != null) 'foto': photoBase64,
    };
  }
}
