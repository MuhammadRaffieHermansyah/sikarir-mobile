import 'package:sikarir/core/constants/api_constants.dart';

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
      status: normalizeStatus(map['status_kehadiran'] ?? map['status'] ?? 'hadir'),
      notes: map['keterangan']?.toString() ?? map['notes']?.toString(),
      location: map['lokasi']?.toString() ?? map['location']?.toString(),
      photoUrl: (() {
        final rawPhoto = map['foto']?.toString() ?? map['photo_url']?.toString();
        if (rawPhoto != null && rawPhoto.isNotEmpty) {
          return ApiConstants.fullImageUrl(rawPhoto);
        }
        return null;
      })(),
      roomName: _resolveRoomName(map),
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      jarakMeter: _toDouble(map['jarak_meter']),
    );
  }

  /// Samakan penulisan status dari API ('alpa' / 'alpha' / huruf besar) ke
  /// satu bentuk baku: hadir, izin, sakit, alpha.
  static String normalizeStatus(Object? raw) {
    final s = raw.toString().trim().toLowerCase();
    return s == 'alpa' ? 'alpha' : s;
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
  /// Batas minimal kehadiran (%) untuk mengikuti uji kompetensi (fallback
  /// jika server tidak mengirim `memenuhi_syarat`).
  static const double minimumPercentage = 80;

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

  int get totalRecords =>
      totalPresent + totalPermission + totalSick + totalAbsent;

  /// `false` bila belum ada satu pun catatan presensi.
  bool get hasData => totalRecords > 0;

  bool get meetsMinimum =>
      hasData && attendancePercentage >= minimumPercentage;

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
    // Tanpa data → 0%, bukan 100% (agar tidak tampak "memenuhi syarat").
    final pct = totalDays > 0 ? (present / totalDays) * 100 : 0.0;

    return AttendanceSummary(
      totalPresent: present,
      totalPermission: permission,
      totalSick: sick,
      totalAbsent: absent,
      attendancePercentage: pct,
    );
  }
}

/// Rekapitulasi kehadiran & status kelayakan dari endpoint `/absen/rekap`.
class AttendanceRekap {
  final bool? memenuhiSyarat;
  final String? statusKelayakan;
  final double? persentase;
  final double? minimalPersentase;
  final int? totalHadir;
  final int? totalIzin;
  final int? totalSakit;
  final int? totalAlpha;

  const AttendanceRekap({
    this.memenuhiSyarat,
    this.statusKelayakan,
    this.persentase,
    this.minimalPersentase,
    this.totalHadir,
    this.totalIzin,
    this.totalSakit,
    this.totalAlpha,
  });

  /// Kontrak backend (`GET /absen/rekap` → `data.summary`):
  /// total_hadir, total_izin, total_sakit, total_alpha, total_sesi,
  /// persentase_hadir, syarat_persentase, status_kelayakan, memenuhi_syarat.
  factory AttendanceRekap.fromMap(Map<String, dynamic> data) {
    final summary = data['summary'] is Map<String, dynamic>
        ? data['summary'] as Map<String, dynamic>
        : data;
    final memenuhi = summary['memenuhi_syarat'];
    return AttendanceRekap(
      memenuhiSyarat: memenuhi is bool
          ? memenuhi
          : (memenuhi == null
              ? null
              : (memenuhi.toString() == '1' || memenuhi.toString() == 'true')),
      statusKelayakan: summary['status_kelayakan']?.toString(),
      persentase: AttendanceItem._toDouble(
          summary['persentase_hadir'] ?? summary['persentase_kehadiran'] ?? summary['persentase']),
      minimalPersentase: AttendanceItem._toDouble(summary['syarat_persentase'] ??
          summary['minimal_persentase'] ??
          summary['minimal_kehadiran']),
      totalHadir: _toInt(summary['total_hadir']),
      totalIzin: _toInt(summary['total_izin']),
      totalSakit: _toInt(summary['total_sakit']),
      totalAlpha: _toInt(summary['total_alpha']),
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Ringkasan dari angka server (mencakup SEMUA riwayat, bukan hanya
  /// halaman pertama). `null` bila server tidak mengirim hitungan.
  AttendanceSummary? toSummary() {
    if (totalHadir == null &&
        totalIzin == null &&
        totalSakit == null &&
        totalAlpha == null) {
      return null;
    }
    final hadir = totalHadir ?? 0;
    final izin = totalIzin ?? 0;
    final sakit = totalSakit ?? 0;
    final alpha = totalAlpha ?? 0;
    final total = hadir + izin + sakit + alpha;
    return AttendanceSummary(
      totalPresent: hadir,
      totalPermission: izin,
      totalSick: sakit,
      totalAbsent: alpha,
      attendancePercentage:
          persentase ?? (total > 0 ? hadir / total * 100 : 0.0),
    );
  }
}

/// Satu halaman riwayat presensi (backend: `paginate(15)`).
class AttendancePage {
  final List<AttendanceItem> items;
  final bool hasMore;

  const AttendancePage({required this.items, required this.hasMore});
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
