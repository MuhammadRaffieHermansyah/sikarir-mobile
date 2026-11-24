import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/instructor/presentation/pages/instructor_class_detail_screen.dart';
import 'package:sikarir/features/instructor/presentation/pages/instructor_profile_tab.dart';
import 'package:sikarir/features/instructor/presentation/providers/instructor_provider.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';

/// Shell navigasi untuk pengguna dengan role instruktur.
class InstructorNavigationScreen extends StatefulWidget {
  const InstructorNavigationScreen({super.key});

  @override
  State<InstructorNavigationScreen> createState() =>
      _InstructorNavigationScreenState();
}

class _InstructorNavigationScreenState
    extends State<InstructorNavigationScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [_TeachingClassesTab(), InstructorProfileTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_rounded),
            label: 'Kelas Saya',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _TeachingClassesTab extends StatefulWidget {
  const _TeachingClassesTab();

  @override
  State<_TeachingClassesTab> createState() => _TeachingClassesTabState();
}

class _TeachingClassesTabState extends State<_TeachingClassesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() {
    if (!mounted) return Future.value();
    return context.read<InstructorProvider>().fetchTeachingClasses(
      context.read<AuthProvider>().token,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorProvider>();
    final name = context.watch<AuthProvider>().user?.name ?? '';

    Widget body;
    if (provider.isLoadingClasses && provider.classes.isEmpty) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    } else if (provider.classesError != null && provider.classes.isEmpty) {
      body = _Message(
        icon: Icons.cloud_off_rounded,
        title: 'Gagal Memuat Kelas',
        message: provider.classesError!,
        onRetry: _load,
      );
    } else if (provider.classes.isEmpty) {
      body = const _Message(
        icon: Icons.school_outlined,
        title: 'Belum Ada Kelas',
        message: 'Anda belum ditugaskan mengampu kelas pelatihan mana pun.',
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.classes.length,
        itemBuilder: (_, i) => _ClassCard(item: provider.classes[i]),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelas yang Saya Ampu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (name.isNotEmpty)
              Text(
                'Halo, $name',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
      body: RefreshIndicator(onRefresh: _load, child: body),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // ListView agar pull-to-refresh tetap bisa dipakai.
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (onRetry != null)
          Center(
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  final TrainingClassModel item;
  const _ClassCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InstructorClassDetailScreen(trainingClass: item),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.code,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.category} • ${item.totalSessions} pertemuan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Kelola Modul & Materi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

