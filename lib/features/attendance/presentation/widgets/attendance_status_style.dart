import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';

/// Satu-satunya tempat pemetaan status presensi → warna, ikon, dan label.
/// Status yang dikenal: hadir, izin, sakit, alpha (selain itu dianggap alpha).
class AttendanceStatusStyle {
  final String label; // label singkat (badge/statistik)
  final String todayLabel; // label kartu status hari ini
  final Color fg;
  final Color bg;
  final Color badgeBg;
  final IconData icon; // ikon solid (kartu hari ini)
  final IconData outlineIcon; // ikon outline (statistik)

  const AttendanceStatusStyle({
    required this.label,
    required this.todayLabel,
    required this.fg,
    required this.bg,
    required this.badgeBg,
    required this.icon,
    required this.outlineIcon,
  });

  static final AttendanceStatusStyle hadir = const AttendanceStatusStyle(
    label: 'Hadir',
    todayLabel: 'Sudah Hadir',
    fg: AppColors.mintDark,
    bg: AppColors.mintBg,
    badgeBg: AppColors.mint,
    icon: Icons.check_circle_rounded,
    outlineIcon: Icons.check_circle_outline_rounded,
  );

  static final AttendanceStatusStyle izin = const AttendanceStatusStyle(
    label: 'Izin',
    todayLabel: 'Izin Tercatat',
    fg: AppColors.orangeText,
    bg: AppColors.orangeLight,
    badgeBg: AppColors.peachBg,
    icon: Icons.mail_rounded,
    outlineIcon: Icons.mail_outline_rounded,
  );

  static final AttendanceStatusStyle sakit = AttendanceStatusStyle(
    label: 'Sakit',
    todayLabel: 'Sakit Tercatat',
    fg: Colors.blue.shade700,
    bg: Colors.blue.shade50,
    badgeBg: Colors.blue.shade50,
    icon: Icons.healing_rounded,
    outlineIcon: Icons.healing_rounded,
  );

  static final AttendanceStatusStyle alpha = AttendanceStatusStyle(
    label: 'Alpa',
    todayLabel: 'Tidak Hadir',
    fg: Colors.red.shade700,
    bg: Colors.red.shade50,
    badgeBg: Colors.red.shade50,
    icon: Icons.cancel_rounded,
    outlineIcon: Icons.cancel_outlined,
  );

  /// Gaya untuk status API (sudah/ belum dinormalisasi).
  static AttendanceStatusStyle of(String status) {
    switch (status.trim().toLowerCase()) {
      case 'hadir':
        return hadir;
      case 'izin':
        return izin;
      case 'sakit':
        return sakit;
      default:
        return alpha;
    }
  }
}
