import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/core/widgets/blk_header.dart';
import 'package:sikarir/features/attendance/attendance.dart';
import 'package:sikarir/features/auth/auth.dart';
import 'package:sikarir/features/certificate/certificate.dart';
import 'package:sikarir/features/job/job.dart';
import 'package:sikarir/features/profile/presentation/pages/complete_profile_screen.dart';
import 'package:sikarir/features/profile/presentation/providers/peserta_provider.dart';
import 'package:sikarir/features/training/training.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final Function(int)? onSwitchTab;

  const HomePage({
    super.key,
    this.onNotificationTap,
    this.onProfileTap,
    this.onSwitchTab,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  /// Memuat seluruh data beranda dari API secara paralel
  Future<void> _refreshAllData() async {
    final token = context.read<AuthProvider>().user?.token;
    await Future.wait([
      context.read<PesertaProvider>().fetchProfile(token),
      context.read<AttendanceProvider>().fetchAttendanceData(token),
      context.read<TrainingClassProvider>().fetchClasses(token),
      context.read<TrainingClassProvider>().fetchCatalog(token),
      context.read<TrainingScheduleProvider>().fetchSchedules(token),
      context.read<JobProvider>().fetchJobs(token),
      context.read<CertificateProvider>().fetchCertificates(token),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BlkHeader(
              sectionTitle: 'Beranda',
              onNotificationTap: widget.onNotificationTap,
              onProfileTap: widget.onProfileTap,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshAllData,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 4),

                    // Greeting Section (Dibersihkan dari duplikasi ikon lonceng notifikasi)
                    _buildGreetingSection(),
                    const SizedBox(height: 12),

                    // Banner Lengkapi Data Diri (tampil jika data diri belum lengkap)
                    _buildProfileCompletionBanner(),

                    // Ringkasan Statistik Cepat (4 metrik live dari API)
                    _buildStatsRow(),
                    const SizedBox(height: 20),

                    // Section: Pelatihan Saya (Data live kelas aktif atau ajakan mendaftar)
                    _buildMyTrainingSection(),
                    const SizedBox(height: 20),

                    // Section: Jadwal Pelatihan Terdekat
                    _buildNextScheduleSection(),
                    const SizedBox(height: 20),

                    // Section: Rekomendasi Pelatihan (Katalog dari API)
                    _buildRecommendedTrainingsSection(),
                    const SizedBox(height: 20),

                    // Section: Peluang Kerja Untukmu (Lowongan dari API)
                    _buildJobOpportunitiesSection(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Banner pengingat kelengkapan profil jika belum 100%
  Widget _buildProfileCompletionBanner() {
    return Consumer<PesertaProvider>(
      builder: (context, provider, _) {
        if (provider.profile == null || provider.isProfileComplete) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFEDD5)),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_late_rounded,
                  color: Color(0xFFEA580C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Lengkapi Data Diri',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Wajib dilengkapi sebelum mendaftar pelatihan.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CompleteProfileScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Lengkapi',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Greeting section yang ringkas dan bersih tanpa duplikasi tombol notifikasi
  Widget _buildGreetingSection() {
    final authProvider = context.watch<AuthProvider>();
    final pesertaProvider = context.watch<PesertaProvider>();

    final profileName = pesertaProvider.profile?.nama?.trim();
    final authName = authProvider.user?.name.trim();

    final userName = (profileName != null && profileName.isNotEmpty)
        ? profileName
        : ((authName != null && authName.isNotEmpty)
            ? authName
            : 'Peserta SIKARIR');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat datang,',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
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
                      'Peserta Aktif BLK Jember',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mintDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 4 Statistik ringkas dengan angka aktual dari API Providers
  Widget _buildStatsRow() {
    final trainingClassProvider = context.watch<TrainingClassProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final certificateProvider = context.watch<CertificateProvider>();
    final jobProvider = context.watch<JobProvider>();

    final myClassesCount = trainingClassProvider.allClasses.length;
    final certCount = certificateProvider.certificates.length;
    final jobsCount = jobProvider.allJobs.length;

    // Presensi persentase dihitung dari data aktual summary
    final attendancePct = attendanceProvider.allAttendanceList.isNotEmpty
        ? '${attendanceProvider.summary.attendancePercentage.toStringAsFixed(0)}%'
        : '0%';

    final stats = [
      {
        'val': myClassesCount.toString().padLeft(2, '0'),
        'label': 'Pelatihan\nDiikuti',
        'color': AppColors.primary,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyClassesScreen()),
        ),
      },
      {
        'val': attendancePct,
        'label': 'Presensi\nKelas',
        'color': AppColors.mintDark,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AttendanceScreen()),
        ),
      },
      {
        'val': certCount.toString().padLeft(2, '0'),
        'label': 'Sertifikat\nResmi',
        'color': AppColors.primary,
        'onTap': () => widget.onSwitchTab?.call(3),
      },
      {
        'val': jobsCount.toString().padLeft(2, '0'),
        'label': 'Peluang\nKerja',
        'color': AppColors.orange,
        'onTap': () => widget.onSwitchTab?.call(2),
      },
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: InkWell(
            onTap: s['onTap'] as VoidCallback?,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Text(
                    s['val'] as String,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: s['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Section Pelatihan Saya: Menampilkan kelas aktif pengguna atau CTA daftar pelatihan
  Widget _buildMyTrainingSection() {
    final trainingProvider = context.watch<TrainingClassProvider>();
    final classes = trainingProvider.allClasses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                SizedBox(width: 6),
                Text(
                  'Pelatihan Saya',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyClassesScreen()),
                );
              },
              child: Text(
                classes.isNotEmpty ? 'Lihat Semua (${classes.length})' : 'Semua Kelas',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mintDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (trainingProvider.isLoading && classes.isEmpty)
          Container(
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const CircularProgressIndicator(color: AppColors.primary),
          )
        else if (classes.isNotEmpty)
          _buildActiveClassCard(classes.first)
        else
          _buildEmptyTrainingCard(),
      ],
    );
  }

  /// Kartu kelas aktif saat ini yang diambil dari API
  Widget _buildActiveClassCard(TrainingClassModel activeClass) {
    final progressPercent = (activeClass.progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: activeClass.status == 'berlangsung'
                      ? AppColors.mint
                      : AppColors.peachBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  activeClass.status == 'berlangsung'
                      ? 'Sedang Berlangsung'
                      : activeClass.status == 'selesai'
                          ? 'Selesai'
                          : 'Akan Datang',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: activeClass.status == 'berlangsung'
                        ? AppColors.mintDark
                        : AppColors.peachText,
                  ),
                ),
              ),
              Text(
                activeClass.code,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            activeClass.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            activeClass.category,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sesi Selesai (${activeClass.completedSessions}/${activeClass.totalSessions})',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$progressPercent%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: activeClass.progress,
              backgroundColor: AppColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${activeClass.startDate} - ${activeClass.endDate}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.room_preferences_outlined,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  activeClass.room,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassDetailScreen(trainingClass: activeClass),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Detail Kelas',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttendanceScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fingerprint_rounded, size: 16),
                  label: const Text(
                    'Presensi',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tampilan ramah dan rapi jika peserta belum terdaftar di kelas manapun
  Widget _buildEmptyTrainingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mintBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_outlined,
              color: AppColors.mintDark,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Belum Ada Pelatihan Aktif',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tingkatkan keahlian kerja bersertifikasi BNSP dengan mendaftar pelatihan kejuruan di BLK Jember.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              widget.onSwitchTab?.call(1); // Pindah ke tab Pelatihan
            },
            icon: const Icon(Icons.search_rounded, size: 15),
            label: const Text(
              'Jelajahi Pelatihan',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Jadwal Pelatihan terdekat yang diambil dari TrainingScheduleProvider
  Widget _buildNextScheduleSection() {
    final scheduleProvider = context.watch<TrainingScheduleProvider>();
    final schedules = scheduleProvider.allSchedules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
                SizedBox(width: 6),
                Text(
                  'Jadwal Pelatihan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TrainingScheduleScreen(),
                  ),
                );
              },
              child: const Text(
                'Semua Jadwal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mintDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (schedules.isNotEmpty)
          _buildScheduleItemCard(schedules.first)
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.event_available_outlined,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tidak ada sesi pelatihan dalam waktu dekat.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Kartu jadwal sesi pelatihan dengan format tanggal & jam yang dinamis
  Widget _buildScheduleItemCard(TrainingScheduleModel schedule) {
    final dateParts = _parseDateParts(schedule.date);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingScheduleScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            // Date badge
            Container(
              width: 50,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.peachBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dateParts['day'] ?? '01',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.peachText,
                    ),
                  ),
                  Text(
                    dateParts['month'] ?? 'SESI',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.peachText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.peachBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 10,
                          color: AppColors.peachText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${schedule.startTime} - ${schedule.endTime} WIB',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.peachText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedule.className.isNotEmpty ? schedule.className : schedule.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${schedule.room} • ${schedule.instructor}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section Rekomendasi Pelatihan: Mengambil data katalog live dari TrainingClassProvider
  Widget _buildRecommendedTrainingsSection() {
    final trainingProvider = context.watch<TrainingClassProvider>();
    final catalogList = trainingProvider.allCatalog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.star_border_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                SizedBox(width: 6),
                Text(
                  'Pelatihan yang Mungkin Kamu Suka',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                widget.onSwitchTab?.call(1);
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mintDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (trainingProvider.isLoadingCatalog && catalogList.isEmpty)
          Container(
            height: 200,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const CircularProgressIndicator(color: AppColors.primary),
          )
        else if (catalogList.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Center(
              child: Text(
                'Belum ada rekomendasi pelatihan saat ini.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          SizedBox(
            height: 234,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: catalogList.length > 5 ? 5 : catalogList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = catalogList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrainingDetailScreen(model: item),
                      ),
                    );
                  },
                  child: Container(
                    width: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: SizedBox(
                                height: 110,
                                width: double.infinity,
                                child: Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: AppColors.mintBg,
                                    child: const Center(
                                      child: Icon(
                                        Icons.school_outlined,
                                        color: AppColors.mintDark,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.duration,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mint,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Sisa Kuota: ${item.remainingQuota}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.mintDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.description,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mintBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  item.badge.isNotEmpty ? item.badge : 'Subsidi Penuh',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mintDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// Section Peluang Kerja: Mengambil data lowongan live dari JobProvider
  Widget _buildJobOpportunitiesSection() {
    final jobProvider = context.watch<JobProvider>();
    final jobs = jobProvider.allJobs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.work_outline_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                SizedBox(width: 6),
                Text(
                  'Peluang Kerja Untukmu',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                widget.onSwitchTab?.call(2); // Pindah ke tab Lowongan
              },
              child: const Text(
                'Pusat Karir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mintDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (jobProvider.isLoading && jobs.isEmpty)
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const CircularProgressIndicator(color: AppColors.primary),
          )
        else if (jobs.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Center(
              child: Text(
                'Belum ada peluang kerja saat ini.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...jobs.take(2).map((job) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            job.companyLogo,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.business_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              job.companyName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mintBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          job.type,
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
                    job.salary,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mintDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.hourglass_bottom_rounded,
                            size: 12,
                            color: AppColors.orangeText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.deadline.startsWith('Tenggat')
                                ? job.deadline
                                : 'Tenggat: ${job.deadline}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.orangeText,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onSwitchTab?.call(2); // Buka di tab Lowongan
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Lihat Detail',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  /// Helper untuk memparsing tanggal dinamis menjadi day dan month singkat
  Map<String, String> _parseDateParts(String dateStr) {
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        const months = [
          'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
          'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'
        ];
        final day = parsed.day.toString().padLeft(2, '0');
        final month = months[parsed.month - 1];
        return {'day': day, 'month': month};
      }
    } catch (_) {}

    final parts = dateStr.trim().split(RegExp(r'[\s\-/]+'));
    if (parts.length >= 2) {
      String day = parts[0];
      String month = parts[1].toUpperCase();
      if (int.tryParse(parts[0]) != null && parts[0].length == 4) {
        day = parts.length >= 3 ? parts[2] : '01';
        final mIdx = int.tryParse(parts[1]);
        if (mIdx != null && mIdx >= 1 && mIdx <= 12) {
          const months = [
            'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
            'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'
          ];
          month = months[mIdx - 1];
        }
      } else if (month.length > 3) {
        month = month.substring(0, 3);
      }
      return {'day': day.padLeft(2, '0'), 'month': month};
    }

    final now = DateTime.now();
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
      'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'
    ];
    return {
      'day': now.day.toString().padLeft(2, '0'),
      'month': months[now.month - 1]
    };
  }
}
