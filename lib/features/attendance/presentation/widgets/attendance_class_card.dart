import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_status_style.dart';
import 'package:sikarir/features/attendance/utils/attendance_formatters.dart';
import 'package:sikarir/features/instructor/data/models/attendance_session_model.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';

/// Kartu presensi untuk satu kelas pelatihan yang diikuti peserta:
/// nama kelas, pertemuan, jam, lokasi, status presensi hari ini, dan aksi.
class AttendanceClassCard extends StatelessWidget {
  final TrainingClassModel kelas;

  /// Sesi yang sedang dibuka instruktur; `null` bila belum dibuka.
  final AttendanceSession? session;

  /// false bila status sesi gagal diperiksa ke server.
  final bool sessionChecked;

  /// Catatan presensi hari ini untuk kelas ini, bila ada.
  final AttendanceItem? today;

  /// Label lokasi & radius yang dipakai untuk presensi.
  final String locationLabel;
  final int radiusMeter;

  /// Tombol/aksi di bagian bawah kartu.
  final List<Widget> actions;

  const AttendanceClassCard({
    super.key,
    required this.kelas,
    required this.session,
    required this.sessionChecked,
    required this.today,
    required this.locationLabel,
    required this.radiusMeter,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final s = session;
    final jam = s != null
        ? '${s.startTime} – ${s.endTime}'
        : (kelas.scheduleStart.isNotEmpty
            ? '${kelas.scheduleStart} – ${kelas.scheduleEnd}'
            : '-');
    final tanggal = s != null ? tryParseApiDate(s.date) : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: s != null && today == null
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kelas.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kelas.instructor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  session: s,
                  sessionChecked: sessionChecked,
                  today: today,
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.event_note_rounded,
                        label: 'Pertemuan',
                        value: s != null ? 'Ke-${s.meetingNumber}' : '-',
                      ),
                    ),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.schedule_rounded,
                        label: s != null ? 'Jam Presensi' : 'Jam Pelatihan',
                        value: jam,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'Tanggal',
                        value: tanggal != null
                            ? formatLongDate(tanggal)
                            : formatLongDate(DateTime.now()),
                      ),
                    ),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.location_on_rounded,
                        label: 'Lokasi · $radiusMeter m',
                        value: locationLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (today != null) _TodayRecordRow(today: today!),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: actions,
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.textSecondary)),
              const SizedBox(height: 1),
              Text(value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AttendanceSession? session;
  final bool sessionChecked;
  final AttendanceItem? today;

  const _StatusChip({
    required this.session,
    required this.sessionChecked,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color fg;
    final Color bg;

    final t = today;
    if (t != null) {
      final style = AttendanceStatusStyle.of(t.status);
      label = style.label;
      fg = style.fg;
      bg = style.badgeBg;
    } else if (!sessionChecked) {
      label = 'Belum Diperiksa';
      fg = AppColors.textSecondary;
      bg = const Color(0xFFEEF1F4);
    } else if (session != null) {
      label = 'Dibuka';
      fg = AppColors.primary;
      bg = AppColors.mintBg;
    } else {
      label = 'Belum Dibuka';
      fg = AppColors.orangeText;
      bg = const Color(0xFFFFF3E0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

class _TodayRecordRow extends StatelessWidget {
  final AttendanceItem today;

  const _TodayRecordRow({required this.today});

  @override
  Widget build(BuildContext context) {
    final s = AttendanceStatusStyle.of(today.status);
    final parts = <String>[
      if (today.clockInTime != null)
        'Masuk ${formatApiTimeLabel(today.clockInTime!)}',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(s.icon, color: s.fg, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              parts.isEmpty ? s.todayLabel : '${s.todayLabel} · ${parts.join(' · ')}',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: s.fg),
            ),
          ),
        ],
      ),
    );
  }
}
