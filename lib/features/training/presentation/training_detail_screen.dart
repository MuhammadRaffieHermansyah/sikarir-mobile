import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/profile/presentation/pages/complete_profile_screen.dart';
import 'package:sikarir/features/profile/presentation/providers/peserta_provider.dart';
import 'package:sikarir/features/training/data/models/training_catalog_model.dart';
import 'package:sikarir/features/training/presentation/pages/my_classes_screen.dart';
import 'package:sikarir/features/training/presentation/providers/training_class_provider.dart';

class TrainingDetailScreen extends StatefulWidget {
  final TrainingCatalogModel? model;
  final String? id;
  final String? jadwalId;
  final String title;
  final String skkniCode;
  final String duration;
  final String quota;
  final String location;
  final String certification;
  final String imageUrl;

  const TrainingDetailScreen({
    super.key,
    this.model,
    this.id,
    this.jadwalId,
    this.title = 'Desain Grafis & Visual Communication',
    this.skkniCode = 'SKKNI No. M.74100.001.02 • Lisensi BNSP Level 3',
    this.duration = '40 JP',
    this.quota = '16/20 Peserta',
    this.location = 'Lab Multimedia',
    this.certification = 'BNSP Desainer',
    this.imageUrl =
        'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&auto=format&fit=crop&q=80',
  });

  @override
  State<TrainingDetailScreen> createState() => _TrainingDetailScreenState();
}

class _TrainingDetailScreenState extends State<TrainingDetailScreen> {
  final List<bool> _expandedModules = [false, false, false, false, false];

  String get title => widget.model?.title ?? widget.title;
  String get skkniCode => widget.model?.skkniCode ?? widget.skkniCode;
  String get duration => widget.model?.duration ?? widget.duration;
  String get quota => widget.model != null
      ? '${widget.model!.enrolledCount}/${widget.model!.quota} Peserta'
      : widget.quota;
  String get location => widget.model?.location ?? widget.location;
  String get certification => widget.model?.badge ?? widget.certification;
  String get imageUrl => widget.model?.imageUrl ?? widget.imageUrl;
  String get instructor => widget.model?.instructor ?? 'Dimas Wicaksono, M.Ds.';
  String get description => widget.model?.description ?? 'Pelatihan berbasis kompetensi industri berstandar SKKNI & BNSP.';
  String get startDate => widget.model?.startDate ?? '01 September 2026';
  String get endDate => widget.model?.endDate ?? '30 Oktober 2026';
  String get targetJadwalId =>
      (widget.model?.jadwalId != null && widget.model!.jadwalId!.isNotEmpty)
          ? widget.model!.jadwalId!
          : (widget.jadwalId ?? widget.id ?? widget.model?.id ?? '1');
  String get targetPelatihanId => widget.model?.id ?? widget.id ?? '1';

  final List<Map<String, String>> _curriculums = [
    {
      'num': '01',
      'title': 'Prinsip Tata Letak & Grid System',
      'subtitle': '✓ Terbuka • Pengantar Standar SKKNI',
    },
    {
      'num': '02',
      'title': 'Adobe Illustrator & Vektor Branding',
      'subtitle': 'Praktik Laboratorium Terpandu',
    },
    {
      'num': '03',
      'title': 'UI/UX Wireframing & Design System',
      'subtitle': 'Figma & Prototyping Interaktif',
    },
    {
      'num': '04',
      'title': 'Portofolio Proyek Industri Nyata',
      'subtitle': 'Brief Langsung dari UMKM & Startup Mitra',
    },
    {
      'num': '05',
      'title': 'Uji Kompetensi Asesor BNSP',
      'subtitle': 'Sertifikasi Akhir Kelulusan Resmi',
    },
  ];

  Future<void> _handleDaftarPelatihan() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu untuk mendaftar pelatihan.'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    final trainingProvider = context.read<TrainingClassProvider>();
    final isEnrolled = widget.model?.isEnrolled ??
        trainingProvider.isUserEnrolled(targetPelatihanId, targetJadwalId);
    if (isEnrolled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda sudah terdaftar di pelatihan ini.'),
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: 'Buka Kelas',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyClassesScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    if (widget.model != null && widget.model!.remainingQuota <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maaf, kuota pelatihan ini sudah penuh.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pesertaProvider = context.read<PesertaProvider>();
    final token = authProvider.user?.token;

    if (pesertaProvider.profile == null) {
      await pesertaProvider.fetchProfile(token);
      if (!mounted) return;
    }

    if (!pesertaProvider.isProfileComplete) {
      _showIncompleteProfileSheet();
      return;
    }

    _showConfirmEnrollmentSheet();
  }

  void _showIncompleteProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.orangeLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_late_rounded,
                color: AppColors.orangeText,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lengkapi Data Diri Terlebih Dahulu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Untuk dapat mendaftar pelatihan "$title", Anda wajib melengkapi data diri resmi (No. KK, WhatsApp, Alamat, dan Pendidikan Terakhir).',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompleteProfileScreen(
                        onCompleted: () {
                          // Setelah profil dilengkapi dan CompleteProfileScreen ditutup,
                          // langsung jalankan kembali alur pendaftaran
                          if (mounted) _handleDaftarPelatihan();
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text(
                  'Lengkapi Data Diri Sekarang',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text(
                'Nanti Saja',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmEnrollmentSheet() {
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
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
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konfirmasi Pendaftaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Pelatihan Vokasi BLK Komprehensif',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(duration, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(width: 12),
                          const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(quota, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            final token = context.read<AuthProvider>().user?.token;
                            final peserta = context.read<PesertaProvider>().profile;
                            await context.read<TrainingClassProvider>().enrollTraining(
                              jadwalId: targetJadwalId,
                              pesertaId: peserta?.idPeserta,
                              token: token,
                            );
                            if (mounted) {
                              Navigator.pop(ctx);
                              _showRegistrationSuccess();
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Konfirmasi & Kirim Berkas',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRegistrationSuccess() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.mintDark,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pendaftaran Berhasil!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data pendaftaran Anda telah tercatat dan Anda resmi terdaftar pada kelas "$title". Silakan pantau perkembangan pembelajaran di menu Kelas Saya.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyClassesScreen()),
                  );
                },
                icon: const Icon(Icons.school_outlined, size: 20),
                label: const Text(
                  'Buka Kelas Pelatihan Saya',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detail Pelatihan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tautan informasi $title siap dibagikan.')),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image with Overlays
            _buildHeroBanner(),
            const SizedBox(height: 18),

            // Title & Accreditation
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  color: AppColors.mintDark,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    skkniCode,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mintDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            // 2x2 Quick Info Grid
            _buildQuickInfoGrid(),
            const SizedBox(height: 16),

            // Schedule Card
            _buildScheduleCard(),
            const SizedBox(height: 20),

            // Instructor Section
            const Text(
              'INSTRUKTUR UTAMA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            _buildInstructorCard(),
            const SizedBox(height: 22),

            // Curriculum Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'KURIKULUM PELATIHAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '5 Modul Berjenjang',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mintDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCurriculumList(),
            const SizedBox(height: 22),

            // Facilities Section
            const Text(
              'FASILITAS PESERTA (GRATIS)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildFacilitiesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            SizedBox(
              height: 190,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.mintBg,
                  child: const Center(
                    child: Icon(Icons.school, size: 48, color: AppColors.primary),
                  ),
                ),
              ),
            ),
            // Gradient dark overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            // Badges row
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.mintDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'PENDAFTARAN DIBUKA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mintDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.peachBg.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium, size: 12, color: AppColors.peachText),
                        SizedBox(width: 4),
                        Text(
                          'BEASISWA APBN 100%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.peachText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoGrid() {
    final remaining = widget.model?.remainingQuota ?? 4;
    final total = widget.model?.quota ?? 20;
    final filled = widget.model?.enrolledCount ?? 16;
    final progress = total > 0 ? (filled / total).clamp(0.0, 1.0) : 0.8;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoBox(
                icon: Icons.timer_outlined,
                iconColor: AppColors.mintDark,
                iconBg: AppColors.mintBg,
                label: 'DURASI KURSUS',
                value: duration,
                subvalue: 'Intensif Standar SKKNI',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoBox(
                icon: Icons.groups_outlined,
                iconColor: AppColors.orangeText,
                iconBg: AppColors.orangeLight,
                label: 'KUOTA TERISI',
                tag: 'Sisa $remaining',
                value: quota,
                progress: progress,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoBox(
                icon: Icons.location_on_outlined,
                iconColor: AppColors.primary,
                iconBg: AppColors.mintBg,
                label: 'LOKASI BENGKEL',
                value: location.split(',').first,
                subvalue: location.contains(',') ? location.split(',').last.trim() : 'BLK Resmi',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoBox(
                icon: Icons.military_tech_outlined,
                iconColor: AppColors.mintDark,
                iconBg: AppColors.mintBg,
                label: 'SERTIFIKASI',
                value: certification,
                subvalue: 'Standar Industri',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    String? subvalue,
    String? tag,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mintDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subvalue != null) ...[
            const SizedBox(height: 2),
            Text(
              subvalue,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.cardBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JADWAL KELAS TATAP MUKA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  endDate.isNotEmpty ? '$startDate – $endDate' : startDate,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Senin - Jumat • 08:00 - 15:30 WIB',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.info_outline,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.mintBg,
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.person, color: AppColors.primary, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        instructor,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Instruktur Terverifikasi Asosiasi Kejuruan & BNSP',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumList() {
    return Column(
      children: _curriculums.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isExpanded = _expandedModules[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isExpanded,
              onExpansionChanged: (val) {
                setState(() {
                  _expandedModules[index] = val;
                });
              },
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isExpanded ? AppColors.mintDark : AppColors.mintBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    item['num']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isExpanded ? Colors.white : AppColors.mintDark,
                    ),
                  ),
                ),
              ),
              title: Text(
                item['title']!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                item['subtitle']!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Text(
                    'Materi ini mencakup standar kompetensi kerja nasional, sesi praktikum laboratorium terarah, serta evaluasi berbasis asesmen instruktur industri.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFacilitiesCard() {
    final facilities = [
      'Uang saku harian selama pelatihan',
      'Modul belajar resmi & toolkit praktikum',
      'Seragam pelatihan & perlengkapan safety (APD)',
      'Sertifikat pelatihan Kemnaker RI & uji BNSP',
      'Peluang penyaluran kerja ke mitra industri',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: facilities.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.mintDark, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    f,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final trainingProvider = context.watch<TrainingClassProvider>();
    final isEnrolled = widget.model?.isEnrolled ??
        trainingProvider.isUserEnrolled(targetPelatihanId, targetJadwalId);
    final isFull = (widget.model != null && widget.model!.remainingQuota <= 0);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BIAYA KURSUS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '100% GRATIS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.mintDark,
                ),
              ),
              Text(
                'Disubsidi APBN',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isEnrolled
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyClassesScreen()),
                        );
                      }
                    : (isFull ? null : _handleDaftarPelatihan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnrolled
                      ? AppColors.mintDark
                      : (isFull ? Colors.grey.shade400 : AppColors.primary),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEnrolled
                          ? Icons.check_circle_rounded
                          : (isFull ? Icons.block_rounded : Icons.app_registration_rounded),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEnrolled
                          ? 'Sudah Terdaftar (Lihat Kelas)'
                          : (isFull ? 'Kuota Penuh' : 'Daftar Sekarang'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
