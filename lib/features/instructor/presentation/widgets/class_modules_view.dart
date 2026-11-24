import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/instructor/presentation/providers/instructor_provider.dart';
import 'package:sikarir/features/instructor/presentation/widgets/meeting_module_list.dart';

/// Tampilan baca-saja modul & materi sebuah kelas untuk peserta.
/// Jika kelas belum punya modul, menampilkan [fallback].
class ClassModulesView extends StatefulWidget {
  final String classId;
  final Widget fallback;

  const ClassModulesView({
    super.key,
    required this.classId,
    required this.fallback,
  });

  @override
  State<ClassModulesView> createState() => _ClassModulesViewState();
}

class _ClassModulesViewState extends State<ClassModulesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() {
    if (!mounted) return Future.value();
    final token = context.read<AuthProvider>().token;
    return context.read<InstructorProvider>().fetchModules(
      widget.classId,
      token,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorProvider>();
    final id = widget.classId;
    final modules = provider.modulesOf(id);

    if (provider.isLoadingModules(id) && !provider.hasLoadedModules(id)) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (modules.isEmpty) {
      final error = provider.moduleError(id);
      return RefreshIndicator(
        onRefresh: _load,
        child: Stack(
          children: [
            // Scrollable agar pull-to-refresh tetap bekerja pada state kosong.
            ListView(),
            widget.fallback,
            if (error != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Colors.red.shade700),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [MeetingModuleList(modules: modules)],
      ),
    );
  }
}
