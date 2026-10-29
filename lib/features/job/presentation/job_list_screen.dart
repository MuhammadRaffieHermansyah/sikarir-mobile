import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/core/widgets/blk_header.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/job/data/models/job_model.dart';
import 'package:sikarir/features/job/presentation/providers/job_provider.dart';

class JobListScreen extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNavigateToCertificate;

  const JobListScreen({
    super.key,
    this.onNotificationTap,
    this.onProfileTap,
    this.onNavigateToCertificate,
  });

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'Semua Jurusan',
    '📍 DKI & Jawa Barat',
    '⏱ Full-Time',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().user?.token;
      context.read<JobProvider>().fetchJobs(token);
    });

    _searchController.addListener(() {
      context.read<JobProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _applyJob(JobVacancyModel job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Lamar Posisi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Kirim berkas portofolio & sertifikat BLK Anda ke ${job.companyName} untuk posisi ${job.title}?',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kirim Lamaran'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().user?.token;
    final result = await context.read<JobProvider>().applyJob(job.id, token);

    if (!mounted) return;

    if (result['need_profile_completion'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lengkapi data diri terlebih dahulu sebelum melamar.'),
          backgroundColor: AppColors.peachText,
          action: SnackBarAction(
            label: 'Lengkapi',
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/complete-profile'),
          ),
        ),
      );
    } else if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lamaran untuk ${job.title} berhasil diajukan!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Gagal mengajukan lamaran.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobProvider>();
    final jobs = provider.jobs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BlkHeader(
              sectionTitle: 'Lowongan',
              onNotificationTap: widget.onNotificationTap,
              onProfileTap: widget.onProfileTap,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final token = context.read<AuthProvider>().user?.token;
                  await context.read<JobProvider>().fetchJobs(token);
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Title Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'PELUANG KARIER VOKASI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.mintDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Bursa Kerja Mitra',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Akses langsung jalur prioritas penempatan kerja bagi lulusan dan talenta bersertifikat BLK.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Icon(
                            Icons.business_center_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search Field
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Cari posisi, keahlian, nama mitra HR...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick Filter Chips
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedFilterIndex;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilterIndex = index;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                                ),
                              ),
                              child: Text(
                                _filters[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Recruitment Guarantee Dark Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'GARANSI REKRUTMEN •',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.mint,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text.rich(
                                  TextSpan(
                                    text: 'Terhubung otomatis dengan ',
                                    style: TextStyle(fontSize: 11, color: Colors.white),
                                    children: [
                                      TextSpan(
                                        text: '320+ HRD Mitra Industri',
                                        style: TextStyle(
                                          color: AppColors.mint,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: ' Terverifikasi'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header of list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.isLoading
                              ? 'MEMUAT LOKER...'
                              : 'DITEMUKAN ${jobs.length} LOKER REKOMENDASI',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.4,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pilihan pengurutan loker')),
                            );
                          },
                          child: Row(
                            children: const [
                              Text(
                                'Urutkan',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mintDark,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: AppColors.mintDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Loading / Error / Empty / Job cards
                    if (provider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else if (provider.errorMessage != null)
                      _buildErrorState(provider.errorMessage!)
                    else if (jobs.isEmpty)
                      _buildEmptyState()
                    else
                      ...jobs.map((job) => _buildJobCard(job)),

                    const SizedBox(height: 10),

                    // Verification CTA Banner
                    _buildVerificationBanner(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final token = context.read<AuthProvider>().user?.token;
              context.read<JobProvider>().fetchJobs(token);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.work_off_outlined, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Belum ada lowongan tersedia saat ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobVacancyModel job) {
    final isBookmarked = job.isBookmarked;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company row + bookmark
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                  image: job.companyLogo.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(job.companyLogo),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: job.companyLogo.isEmpty
                    ? const Icon(Icons.business, color: AppColors.textSecondary, size: 20)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  job.companyName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.read<JobProvider>().toggleBookmark(job.id),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                    color: isBookmarked ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            job.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.location,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Badges
          if (job.badges.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: job.badges.asMap().entries.map((e) {
                final colors = [
                  [AppColors.peachBg, AppColors.peachText],
                  [AppColors.mintBg, AppColors.mintDark],
                  [AppColors.blueGray, AppColors.blueGrayText],
                ];
                final pair = colors[e.key % colors.length];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pair[0],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: pair[1],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),

          // Salary & Qualifications Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.mintBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.mint.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ESTIMASI GAJI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      job.salary,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mintDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  job.qualification,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Deadline and Apply Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Batas: ${job.deadline}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: context.read<JobProvider>().isApplying ? null : () => _applyJob(job),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: context.watch<JobProvider>().isApplying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          children: [
                            Text(
                              'Detail & Lamar',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 13),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mint),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.upload_file_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Verifikasi Portofolio Sertifikatmu Langsung ke HRD?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sinkronkan lencana BNSP & Pelatihan Anda sekarang.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: widget.onNavigateToCertificate ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Membuka menu verifikasi sertifikat...')),
                      );
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cek Menu Sertifikat',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14),
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
