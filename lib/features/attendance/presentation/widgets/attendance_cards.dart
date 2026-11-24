import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/data/services/location_service.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_status_style.dart';
import 'package:sikarir/features/attendance/utils/attendance_formatters.dart';

/// Kartu error dengan tombol Coba Lagi.
class AttendanceErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AttendanceErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Kartu informasi netral (ikon + teks).
class AttendanceInfoNote extends StatelessWidget {
  final IconData icon;
  final String text;

  const AttendanceInfoNote({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

/// Info lokasi pelatihan & radius presensi.
class AttendanceLocationCard extends StatelessWidget {
  final AttendanceTarget target;

  const AttendanceLocationCard({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mintBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lokasi Pelatihan',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(target.label,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Radius presensi: ${target.radiusMeter} meter',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Status presensi hari ini.
class AttendanceTodayStatusCard extends StatelessWidget {
  final AttendanceItem today;

  const AttendanceTodayStatusCard({super.key, required this.today});

  @override
  Widget build(BuildContext context) {
    final s = AttendanceStatusStyle.of(today.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(s.icon, color: s.fg, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.todayLabel,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: s.fg)),
                if (today.clockInTime != null)
                  Text('Jam masuk: ${formatApiTimeLabel(today.clockInTime!)}',
                      style: TextStyle(
                          fontSize: 12, color: s.fg.withValues(alpha: 0.8))),
                if (today.hasClockedOut)
                  Text('Jam pulang: ${formatApiTimeLabel(today.clockOutTime!)}',
                      style: TextStyle(
                          fontSize: 12, color: s.fg.withValues(alpha: 0.8))),
                if (today.jarakMeter != null)
                  Text('Jarak saat absen: ${today.jarakMeter!.toStringAsFixed(0)} m',
                      style: TextStyle(
                          fontSize: 11, color: s.fg.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pratinjau lampiran: gambar ditampilkan; berkas lain menampilkan tautannya.
Future<void> showAttendanceAttachment(BuildContext context, String url) {
  final isImage = RegExp(r'\.(jpe?g|png|webp)$', caseSensitive: false)
      .hasMatch(Uri.tryParse(url)?.path ?? url);

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Lampiran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: isImage
          ? InteractiveViewer(
              child: Image.network(
                url,
                errorBuilder: (_, _, _) =>
                    const Text('Lampiran tidak dapat dimuat.'),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Berkas ini tidak dapat dipratinjau. Alamat berkas:',
                    style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                SelectableText(url, style: const TextStyle(fontSize: 12)),
              ],
            ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
      ],
    ),
  );
}

/// Satu baris riwayat presensi.
class AttendanceHistoryCard extends StatelessWidget {
  final AttendanceItem item;

  const AttendanceHistoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final s = AttendanceStatusStyle.of(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(formatApiDateLabel(item.date),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: s.badgeBg, borderRadius: BorderRadius.circular(8)),
                child: Text(s.label,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: s.fg)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.className,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Masuk: ${item.clockInTime != null ? formatApiTimeLabel(item.clockInTime!) : '-'}'
                '${item.hasClockedOut ? '  •  Pulang: ${formatApiTimeLabel(item.clockOutTime!)}' : ''}',
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (item.attachmentUrl != null) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () => showAttendanceAttachment(context, item.attachmentUrl!),
              child: const Row(
                children: [
                  Icon(Icons.attach_file_rounded,
                      size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Lihat lampiran',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ],
          if (item.jarakMeter != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Jarak: ${item.jarakMeter!.toStringAsFixed(0)} m dari lokasi',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.notes!,
                style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
