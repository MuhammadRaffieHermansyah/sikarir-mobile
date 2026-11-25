import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/instructor/data/models/class_module_model.dart';
import 'package:sikarir/features/instructor/presentation/pages/instructor_attendance_screen.dart';
import 'package:sikarir/features/instructor/presentation/providers/instructor_provider.dart';
import 'package:sikarir/features/instructor/presentation/widgets/meeting_module_list.dart';
import 'package:sikarir/features/instructor/presentation/widgets/module_form_sheets.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';

/// Kelola modul & materi per pertemuan untuk satu kelas yang diampu instruktur.
class InstructorClassDetailScreen extends StatefulWidget {
  final TrainingClassModel trainingClass;

  const InstructorClassDetailScreen({super.key, required this.trainingClass});

  @override
  State<InstructorClassDetailScreen> createState() =>
      _InstructorClassDetailScreenState();
}

class _InstructorClassDetailScreenState
    extends State<InstructorClassDetailScreen> {
  String get _classId => widget.trainingClass.id;
  String? get _token => context.read<AuthProvider>().token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() {
    if (!mounted) return Future.value();
    return context.read<InstructorProvider>().fetchModules(_classId, _token);
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

  int _meetingCount(InstructorProvider provider) {
    final maxModule = provider
        .modulesOf(_classId)
        .fold<int>(0, (m, e) => e.meetingNumber > m ? e.meetingNumber : m);
    final total = widget.trainingClass.totalSessions;
    return total > maxModule ? total : maxModule;
  }

  Future<void> _addModule(int meeting) async {
    final provider = context.read<InstructorProvider>();
    final input = await showModuleFormSheet(
      context,
      meetingCount: _meetingCount(provider),
      initialMeeting: meeting,
    );
    if (input == null) return;
    await _run(
      () => provider.addModule(
        classId: _classId,
        title: input.title,
        description: input.description,
        meetingNumber: input.meetingNumber,
        token: _token,
      ),
      'Modul berhasil ditambahkan',
    );
  }

  Future<void> _addMaterial(ClassModule module) async {
    final provider = context.read<InstructorProvider>();
    final input = await showMaterialFormSheet(context);
    if (input == null) return;
    await _run(
      () => provider.addMaterial(
        classId: _classId,
        moduleId: module.id,
        title: input.title,
        kind: input.kind,
        url: input.url,
        content: input.content,
        filePath: input.filePath,
        token: _token,
      ),
      'Materi berhasil ditambahkan',
    );
  }

  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
    return ok ?? false;
  }

  Future<void> _deleteModule(ClassModule module) async {
    final provider = context.read<InstructorProvider>();
    if (!await _confirm(
      'Hapus modul?',
      'Modul "${module.title}" beserta seluruh materinya akan dihapus.',
    )) {
      return;
    }
    await _run(
      () => provider.deleteModule(_classId, module.id, _token),
      'Modul dihapus',
    );
  }

  Future<void> _deleteMaterial(
    ClassModule module,
    ModuleMaterial material,
  ) async {
    final provider = context.read<InstructorProvider>();
    if (!await _confirm(
      'Hapus materi?',
      'Materi "${material.title}" akan dihapus.',
    )) {
      return;
    }
    await _run(
      () => provider.deleteMaterial(_classId, material.id, _token),
      'Materi dihapus',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorProvider>();
    final item = widget.trainingClass;
    final modules = provider.modulesOf(_classId);
    final loadingFirst =
        provider.isLoadingModules(_classId) &&
        !provider.hasLoadedModules(_classId);
    final error = provider.moduleError(_classId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          item.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Kelola Presensi',
            icon: const Icon(Icons.how_to_reg_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    InstructorAttendanceScreen(trainingClass: item),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isSaving ? null : () => _addModule(1),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Modul'),
      ),
      body: Column(
        children: [
          if (provider.isSaving) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: loadingFirst
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children: [
                        Text(
                          '${item.code} • ${item.category}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Modul & materi tiap pertemuan dapat diakses peserta kapan saja.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (error != null && modules.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.cloud_off_rounded,
                                  size: 40,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 8),
                                Text(error, textAlign: TextAlign.center),
                                TextButton(
                                  onPressed: _load,
                                  child: const Text('Coba lagi'),
                                ),
                              ],
                            ),
                          )
                        else
                          MeetingModuleList(
                            modules: modules,
                            totalSessions: item.totalSessions,
                            editable: true,
                            onAddModule: _addModule,
                            onAddMaterial: _addMaterial,
                            onDeleteModule: _deleteModule,
                            onDeleteMaterial: _deleteMaterial,
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
