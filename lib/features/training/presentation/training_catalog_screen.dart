import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/core/widgets/blk_header.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/training/data/models/training_catalog_model.dart';
import 'package:sikarir/features/training/presentation/pages/my_classes_screen.dart';
import 'package:sikarir/features/training/presentation/pages/training_schedule_screen.dart';
import 'package:sikarir/features/training/presentation/providers/training_class_provider.dart';
import 'package:sikarir/features/training/presentation/training_detail_screen.dart';

class TrainingCatalogScreen extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const TrainingCatalogScreen({
    super.key,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  State<TrainingCatalogScreen> createState() => _TrainingCatalogScreenState();
}

class _TrainingCatalogScreenState extends State<TrainingCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'TIK & INFORMATIKA',
    'MANUFAKTUR & LAS',
    'OTOMOTIF MODERN',
    'BISNIS & MANAJEMEN',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final token = context.read<AuthProvider>().user?.token;
    context.read<TrainingClassProvider>().fetchCatalog(token);
    context.read<TrainingClassProvider>().fetchClasses(token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetail(TrainingCatalogModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingDetailScreen(model: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainingClassProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BlkHeader(
              sectionTitle: 'Pelatihan',
              onNotificationTap: widget.onNotificationTap,
              onProfileTap: widget.onProfileTap,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  final token = context.read<AuthProvider>().user?.token;
                  await Future.wait([
                    provider.fetchCatalog(token),
                    provider.fetchClasses(token),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Title & Batch Tag
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Katalog Pelatihan Vokasi',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Tersertifikasi BNSP & Disubsidi Penuh Kemnaker RI',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                'Batch Aktif',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.mintDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick Navigation Buttons: Kelas Saya & Jadwal Pelatihan
                    _buildQuickActionButtons(provider),
                    const SizedBox(height: 14),

                    // Search Bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 13),
                              onChanged: (val) {
                                provider.setSearchQuery(val);
                              },
                              decoration: InputDecoration(
                                hintText: 'Cari kejuruan, kode SKKNI, topik...',
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          provider.setSearchQuery('');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected =
                              provider.catalogCategoryFilter.toLowerCase() == cat.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) {
                                provider.setCatalogFilter(cat);
                              },
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Official Kemnaker Guarantee sub-banner
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.mintDark,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Terdaftar Resmi Kemnaker RI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mintDark,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Text(
                            'Tahun Anggaran 2026',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Content State Handling
                    if (provider.isLoadingCatalog && provider.allCatalog.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else if (provider.catalogError != null && provider.allCatalog.isEmpty)
                      _buildErrorCard(provider)
                    else if (provider.catalog.isEmpty)
                      _buildEmptyState(provider)
                    else
                      ...provider.catalog.map((item) => _buildTrainingCard(item)),

                    const SizedBox(height: 10),

                    // Selection Announcement Box (Gelombang II 2026 Segera Ditutup)
                    _buildSelectionAnnouncementBanner(),
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

  Widget _buildQuickActionButtons(TrainingClassProvider provider) {
    final classCount = provider.allClasses.length;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyClassesScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.mintBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: AppColors.mintDark,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kelas Saya',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          classCount > 0 ? '$classCount Kelas Aktif' : 'Lihat Kelas',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrainingScheduleScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.peachBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event_note_outlined,
                      color: AppColors.peachText,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadwal Pelatihan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Cek Sesi Kelas',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(TrainingClassProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Gagal Memuat Data Pelatihan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            provider.catalogError ??
                'Terjadi kesalahan atau koneksi terputus. Silakan coba lagi beberapa saat.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi Beberapa Saat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TrainingClassProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Pelatihan Tidak Ditemukan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tidak ada pelatihan yang cocok dengan filter atau kata kunci pencarian Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
              provider.setSearchQuery('');
              provider.setCatalogFilter('Semua');
            },
            child: const Text('Reset Pencarian & Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingCard(TrainingCatalogModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Overlays
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.mintBg,
                      child: const Center(
                        child: Icon(Icons.school, size: 40, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
              // Top Badges
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mintDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, size: 10, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        item.badge,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Badges: Quota & Enrolled Indicator
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: item.remainingQuota > 0 ? AppColors.orange : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.remainingQuota > 0
                                ? 'Sisa Kuota: ${item.remainingQuota} Peserta'
                                : 'Kuota Penuh',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (item.isEnrolled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mintDark,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Terdaftar',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location & Duration Row
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        item.location,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(width: 6),
                    const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(
                      item.duration,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Course Title
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Benefit Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.mint),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.credit_card_outlined,
                          size: 14,
                          color: AppColors.mintDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.benefitTitle,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.mintDark,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              item.benefitDesc,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.mintDark,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Buka',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Full Width Button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _navigateToDetail(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.isEnrolled ? AppColors.mintDark : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.isEnrolled ? 'Lihat Detail (Terdaftar)' : 'Lihat Detail Pelatihan',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionAnnouncementBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.event_note, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'PEMBERITAHUAN SELEKSI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mint,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 11, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      '12 Hari Lagi',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Gelombang II 2026 Segera Ditutup',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pendaftaran tes online dan wawancara serentak di 19 Balai Pelatihan Vokasi dan Produktivitas (BPVP) berakhir pada 28 Maret 2026. Pastikan NIK terverifikasi di SIAPkerja.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Row(
                children: [
                  _buildCityAvatar('JKT'),
                  Transform.translate(
                    offset: const Offset(-8, 0),
                    child: _buildCityAvatar('BDG'),
                  ),
                  Transform.translate(
                    offset: const Offset(-16, 0),
                    child: _buildCityAvatar('+17'),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Membuka kalender seleksi...')),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Kalender Seleksi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCityAvatar(String label) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.mint,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryDark, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.mintDark,
          ),
        ),
      ),
    );
  }
}
