import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/instructor/data/models/attendance_session_model.dart';
import 'package:sikarir/features/instructor/presentation/providers/instructor_provider.dart';
import 'package:sikarir/features/instructor/presentation/widgets/attendance_session_form_sheet.dart';
import 'package:sikarir/features/instructor/presentation/widgets/instructor_ui.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';

/// Kelola sesi presensi sebuah kelas: buat, buka/tutup, dan hapus.
class InstructorAttendanceScreen extends StatefulWidget {
  final TrainingClassModel trainingClass;

  const InstructorAttendanceScreen({super.key, required this.trainingClass});

  @override
  State<InstructorAttendanceScreen> createState() =>
      _InstructorAttendanceScreenState();
}

class _InstructorAttendanceScreenState
    extends State<InstructorAttendanceScreen> {
  String get _classId => widget.trainingClass.id;
  String? get _token => context.read<AuthProvider>().token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() {
    if (!mounted) return Future.value();
    return context.read<InstructorProvider>().fetchSessions(_classId, _token);
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade700 : null,
        ),
      );
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      _toast(success);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _create() async {
    final provider = context.read<InstructorProvider>();
    final item = widget.trainingClass;
    final existing = provider.sessionsOf(_classId);
    final used = existing.map((s) => s.meetingNumber).toSet();
    final maxMeeting = existing.fold<int>(
      item.totalSessions,
      (m, s) => s.meetingNumber > m ? s.meetingNumber : m,
    );
    var next = 1;
    while (used.contains(next) && next < maxMeeting) {
      next++;
    }

    final input = await showAttendanceSessionFormSheet(
      context,
      meetingCount: maxMeeting < 1 ? 1 : maxMeeting,
      initialMeeting: next,
      defaultLatitude: item.latitude,
      defaultLongitude: item.longitude,
      defaultRadius: item.radiusMeter,
    );
    if (input == null) return;
    await _run(
      () => provider.createSession(_classId, input, _token),
      'Sesi presensi dibuat',
    );
  }

  Future<void> _toggle(AttendanceSession s) => _run(
    () => context.read<InstructorProvider>().setSessionOpen(
      _classId,
      s.id,
      !s.isOpen,
      _token,
    ),
    s.isOpen ? 'Presensi ditutup' : 'Presensi dibuka',
  );

  Future<void> _delete(AttendanceSession s) async {
    final provider = context.read<InstructorProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus sesi presensi?'),
        content: Text('Sesi pertemuan ${s.meetingNumber} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => provider.deleteSession(_classId, s.id, _token),
      'Sesi presensi dihapus',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorProvider>();
    final sessions = provider.sessionsOf(_classId);
    final loadingFirst =
        provider.isLoadingSessions(_classId) &&
        !provider.hasLoadedSessions(_classId);
    final error = provider.sessionError(_classId);

    Widget body;
    if (loadingFirst) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    } else if (error != null && sessions.isEmpty) {
      body = InstructorMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Gagal Memuat Sesi',
        message: error,
        onRetry: _load,
        error: true,
      );
    } else if (sessions.isEmpty) {
      body = const InstructorMessage(
        icon: Icons.how_to_reg_outlined,
        title: 'Belum Ada Sesi Presensi',
        message: 'Buat sesi agar peserta dapat melakukan presensi pada pertemuan kelas.',
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: sessions.length,
        itemBuilder: (_, i) => _SessionCard(
          session: sessions[i],
          busy: provider.isSaving,
          onToggle: () => _toggle(sessions[i]),
          onDelete: () => _delete(sessions[i]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: InstructorAppBar(
        title: 'Kelola Presensi',
        subtitle: widget.trainingClass.title,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isSaving ? null : _create,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Sesi'),
      ),
      body: Column(
        children: [
          if (provider.isSaving) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AttendanceSession session;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.busy,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final open = session.isOpen;
    Widget info(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );

    return InstructorCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.mintBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${session.meetingNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pertemuan ${session.meetingNumber}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              InstructorChip(
                label: open ? 'Dibuka' : 'Ditutup',
                background: open ? AppColors.mint : AppColors.blueGray,
                foreground: open ? AppColors.mintDark : AppColors.blueGrayText,
                icon: open
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 8),
          info(Icons.event_rounded, session.date),
          info(
            Icons.schedule_rounded,
            '${session.startTime}–${session.endTime}  •  radius ${session.radiusMeter} m',
          ),
          info(Icons.groups_rounded, '${session.presentCount} peserta hadir'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: busy ? null : onToggle,
                  icon: Icon(
                    open ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                    size: 18,
                  ),
                  label: Text(
                    open ? 'Tutup Presensi' : 'Buka Presensi',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: open
                        ? AppColors.orange
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: busy ? null : onDelete,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade700,
                ),
                tooltip: 'Hapus sesi',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
