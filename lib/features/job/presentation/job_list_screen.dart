import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/core/widgets/blk_header.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/job/data/models/job_model.dart';
import 'package:sikarir/features/job/presentation/providers/job_provider.dart';

class JobListScreen extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNavigateToCertificate;

  /// Pembuka tautan WhatsApp perusahaan. Bisa diganti saat pengujian.
  final Future<bool> Function(Uri uri)? openUrl;

  const JobListScreen({
    super.key,
    this.onNotificationTap,
    this.onProfileTap,
    this.onNavigateToCertificate,
    this.openUrl,
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

  /// Nomor telepon Indonesia → format wa.me (0812… → 62812…).
  static String _whatsappNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('0') ? '62${digits.substring(1)}' : digits;
  }

  Future<void> _contactCompany(JobVacancyModel job) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse('https://wa.me/${_whatsappNumber(job.contactPhone)}');
    var opened = false;
    try {
      opened = await (widget.openUrl ?? _openExternally)(uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text('WhatsApp tidak dapat dibuka. Hubungi ${job.contactPhone}.')),
      );
    }
  }

  static Future<bool> _openExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  /// Lowongan hanya informasi: tampilkan detail dan kontak perusahaan, tanpa proses lamaran.
  void _showJobDetail(JobVacancyModel job) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewPadding.bottom + 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              job.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              job.companyName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.location_on_outlined, 'Lokasi', job.location),
            _detailRow(Icons.work_outline, 'Tipe', job.type),
            _detailRow(Icons.payments_outlined, 'Gaji', job.salary),
            _detailRow(Icons.calendar_month_outlined, 'Batas', job.deadline),
            const SizedBox(height: 12),
            const Text(
              'Kualifikasi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(job.qualification, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
            const SizedBox(height: 12),
            const Text(
              'Deskripsi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(job.description, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Lowongan ini bersifat informasi. Hubungi perusahaan langsung melalui kontak di bawah.',
                style: TextStyle(fontSize: 12, color: AppColors.mintDark, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            if (job.contactPhone.isNotEmpty)
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _contactCompany(job),
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: Text('Hubungi ${job.contactPhone}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else
              const Text(
                'Kontak perusahaan belum dicantumkan.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
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
                              context.read<JobProvider>().setCategory(_filters[index]);
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

                    // Banner offline (API tidak tersedia, tampil data demo)
                    if (!provider.isLoading && provider.isOffline)
                      _buildOfflineBanner(),

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

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFFF57F17)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tidak terhubung ke server. Menampilkan data contoh.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              final token = context.read<AuthProvider>().user?.token;
              context.read<JobProvider>().fetchJobs(token);
            },
            child: const Text(
              'Coba lagi',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFF57F17),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
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
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: job.companyLogo.isNotEmpty
                      ? Image.network(
                          job.companyLogo,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.business, color: AppColors.textSecondary, size: 20),
                        )
                      : const Icon(Icons.business, color: AppColors.textSecondary, size: 20),
                ),
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
                  onPressed: () => _showJobDetail(job),
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
                    children: [
                      Text(
                        'Lihat Detail',
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
