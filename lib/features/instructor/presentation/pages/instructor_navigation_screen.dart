import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/instructor/presentation/pages/instructor_class_detail_screen.dart';
import 'package:sikarir/features/instructor/presentation/pages/instructor_profile_tab.dart';
import 'package:sikarir/features/instructor/presentation/providers/instructor_provider.dart';
import 'package:sikarir/features/instructor/presentation/widgets/instructor_ui.dart';
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
      bottomNavigationBar: InstructorBottomNav(
        currentIndex: _index,
        onSelected: (i) => setState(() => _index = i),
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
      body = InstructorMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Gagal Memuat Kelas',
        message: provider.classesError!,
        onRetry: _load,
        error: true,
      );
    } else if (provider.classes.isEmpty) {
      // Kelas instruktur diambil dari pendaftaran peserta, jadi jadwal yang
      // belum punya peserta belum tampil di sini (P6).
      body = InstructorMessage(
        icon: Icons.school_outlined,
        title: 'Belum Ada Kelas',
        message: 'Kelas akan muncul setelah ada peserta yang terdaftar pada jadwal yang Anda ampu. '
            'Jika belum ditugaskan, hubungi admin BLK.',
        onRetry: _load,
      );
    } else {
      body = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: provider.classes.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return _Greeting(name: name);
          return _ClassCard(item: provider.classes[i - 1]);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            InstructorTabHeader(sectionTitle: 'Kelas Saya', name: name),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isNotEmpty ? 'Halo, $name 👋' : 'Halo, Instruktur 👋',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Kelola modul, materi, dan presensi kelas yang Anda ampu.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final TrainingClassModel item;
  const _ClassCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InstructorCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InstructorClassDetailScreen(trainingClass: item),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.mintBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              InstructorChip(
                label: item.category,
                background: AppColors.blueGray,
                foreground: AppColors.blueGrayText,
                icon: Icons.category_outlined,
              ),
              InstructorChip(
                label: '${item.totalSessions} pertemuan',
                background: AppColors.mintBg,
                foreground: AppColors.mintDark,
                icon: Icons.event_note_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.cardBorder),
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
    );
  }
}
