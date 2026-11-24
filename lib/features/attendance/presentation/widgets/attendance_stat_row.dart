import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_status_style.dart';

/// Empat kartu statistik + baris persentase kehadiran.
class AttendanceStatRow extends StatelessWidget {
  final AttendanceSummary summary;
  final double percentage;

  const AttendanceStatRow({
    super.key,
    required this.summary,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final pctText =
        summary.hasData ? '${percentage.toStringAsFixed(1)}%' : '-';

    return Column(
      children: [
        Row(
          children: [
            _StatCard(AttendanceStatusStyle.hadir, summary.totalPresent),
            _StatCard(AttendanceStatusStyle.izin, summary.totalPermission),
            _StatCard(AttendanceStatusStyle.sakit, summary.totalSick),
            _StatCard(AttendanceStatusStyle.alpha, summary.totalAbsent),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Text('Persentase Kehadiran',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const Spacer(),
              Text(pctText,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final AttendanceStatusStyle style;
  final int value;

  const _StatCard(this.style, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
            color: style.bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(style.outlineIcon, size: 18, color: style.fg),
            const SizedBox(height: 4),
            Text('$value',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, color: style.fg)),
            const SizedBox(height: 2),
            Text(style.label,
                style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w600, color: style.fg)),
          ],
        ),
      ),
    );
  }
}
