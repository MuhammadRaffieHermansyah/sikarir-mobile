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

  /// Rekap status peserta pada sesi (dari API sejak rekap instruktur P9).
  final int excusedCount;
  final int sickCount;
  final int absentCount;
  final int pendingCount;
  final int participantCount;

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
    this.excusedCount = 0,
    this.sickCount = 0,
    this.absentCount = 0,
    this.pendingCount = 0,
    this.participantCount = 0,
  });

  static int _int(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;

  /// Ringkasan untuk kartu sesi, mis. "Hadir 3 · Izin 1 · Sakit 0 · Alpha 1".
  String get summaryLabel {
    final parts = [
      'Hadir $presentCount',
      'Izin $excusedCount',
      'Sakit $sickCount',
      if (pendingCount > 0) 'Belum $pendingCount' else 'Alpha $absentCount',
    ];
    return parts.join(' · ');
  }

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
      excusedCount: _int(map['jumlah_izin']),
      sickCount: _int(map['jumlah_sakit']),
      absentCount: _int(map['jumlah_alpha']),
      pendingCount: _int(map['jumlah_belum']),
      participantCount: _int(map['jumlah_peserta']),
    );
  }
}

/// Status satu peserta pada sebuah sesi presensi (rekap instruktur).
class SessionParticipant {
  final String id;
  final String name;

  /// `hadir`, `izin`, `sakit`, `alpha`, atau `belum` (sesi masih berjalan).
  final String status;
  final String? checkInTime;
  final String? note;

  const SessionParticipant({
    required this.id,
    required this.name,
    required this.status,
    this.checkInTime,
    this.note,
  });

  factory SessionParticipant.fromMap(Map<String, dynamic> map) {
    final time = map['jam_hadir']?.toString();
    final note = map['keterangan']?.toString();
    return SessionParticipant(
      id: (map['id_peserta'] ?? '').toString(),
      name: (map['nama'] ?? 'Peserta').toString(),
      status: (map['status'] ?? 'belum').toString(),
      checkInTime: time == null || time.isEmpty ? null : time,
      note: note == null || note.isEmpty ? null : note,
    );
  }

  String get statusLabel => switch (status) {
    'hadir' => 'Hadir',
    'izin' => 'Izin',
    'sakit' => 'Sakit',
    'alpha' => 'Alpha',
    _ => 'Belum presensi',
  };
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
