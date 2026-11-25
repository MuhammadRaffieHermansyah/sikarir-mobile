import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/instructor/data/models/attendance_session_model.dart';
import 'package:sikarir/features/instructor/presentation/providers/instructor_provider.dart';
import 'package:sikarir/features/instructor/presentation/widgets/attendance_session_form_sheet.dart';
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
      body = ListView(
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.cloud_off_rounded, size: 40, color: Colors.red),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(error, textAlign: TextAlign.center),
          ),
          Center(
            child: TextButton(onPressed: _load, child: const Text('Coba lagi')),
          ),
        ],
      );
    } else if (sessions.isEmpty) {
      body = ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.how_to_reg_outlined, size: 48, color: AppColors.textMuted),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Belum ada sesi presensi. Buat sesi agar peserta dapat melakukan presensi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
        ],
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
      appBar: AppBar(
        title: Text(
          'Presensi • ${widget.trainingClass.title}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isSaving ? null : _create,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Sesi'),
      ),
      body: Column(
        children: [
          if (provider.isSaving) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: RefreshIndicator(onRefresh: _load, child: body),
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
    final color = open ? Colors.green.shade700 : AppColors.textSecondary;
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
            children: [
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  open ? 'Dibuka' : 'Ditutup',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${session.date} • ${session.startTime}–${session.endTime} • radius ${session.radiusMeter} m',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            '${session.presentCount} peserta hadir',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: busy ? null : onToggle,
                  icon: Icon(
                    open ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                    size: 18,
                  ),
                  label: Text(open ? 'Tutup Presensi' : 'Buka Presensi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: open
                        ? Colors.orange.shade700
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: busy ? null : onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700),
                tooltip: 'Hapus sesi',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
