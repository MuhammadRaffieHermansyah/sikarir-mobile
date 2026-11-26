import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/data/services/location_service.dart';
import 'package:sikarir/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_cards.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_class_card.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_clock_card.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_stat_row.dart';
import 'package:sikarir/features/attendance/presentation/widgets/izin_sakit_sheet.dart';
import 'package:sikarir/features/attendance/presentation/widgets/location_check_sheet.dart';
import 'package:sikarir/features/attendance/utils/attendance_formatters.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/instructor/data/models/attendance_session_model.dart';
import 'package:sikarir/features/profile/presentation/providers/peserta_provider.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';
import 'package:sikarir/features/training/presentation/providers/training_class_provider.dart';

/// Target presensi untuk sebuah kelas: koordinat/radius jadwal bila ada,
/// selain itu default BLK.
/// Titik & radius dari sesi yang dibuka instruktur diutamakan.
AttendanceTarget _targetFor(TrainingClassModel c, [AttendanceSession? s]) =>
    AttendanceTarget.fromSchedule(
      latitude: s?.latitude ?? c.latitude,
      longitude: s?.longitude ?? c.longitude,
      radiusMeter: s?.radiusMeter ?? c.radiusMeter,
      label: c.room == 'Workshop BLK' ? null : c.room,
    );

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().user?.token;
      context.read<AttendanceProvider>().fetchAttendanceData(token);
      context.read<PesertaProvider>().fetchProfile(token);
      _loadClassesAndSessions(token);
    });
  }

  /// Muat kelas, lalu periksa sesi presensi yang dibuka instruktur per kelas.
  Future<void> _loadClassesAndSessions(String? token) async {
    final classProvider = context.read<TrainingClassProvider>();
    final attendance = context.read<AttendanceProvider>();
    await classProvider.fetchClasses(token);
    if (!mounted) return;
    await attendance.fetchOpenSessions(
      _activeClasses(classProvider).map((c) => c.id),
      token,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Jadwal aktif ───────────────────────────────────────────────────────

  /// Kelas yang sedang berlangsung dan punya id jadwal.
  List<TrainingClassModel> _activeClasses(TrainingClassProvider p) => p
      .allClasses
      .where((c) => c.jadwalId.isNotEmpty && c.status == 'berlangsung')
      .toList();

  String? get _token => context.read<AuthProvider>().user?.token;

  Future<void> _refresh() async {
    final token = _token;
    await Future.wait([
      context.read<AttendanceProvider>().fetchAttendanceData(token),
      _loadClassesAndSessions(token),
    ]);
  }

  String _resolvePesertaId() {
    final profile = context.read<PesertaProvider>().profile;
    return (profile?.idPeserta.isNotEmpty == true)
        ? profile!.idPeserta
        : (context.read<AuthProvider>().user?.userId ?? '');
  }

  // ─── Aksi presensi ──────────────────────────────────────────────────────

  Future<void> _handlePresensiHadir(
      BuildContext ctx, TrainingClassModel kelas) async {
    final provider = ctx.read<AttendanceProvider>();
    final token = _token;
    final pesertaId = _resolvePesertaId();
    final session = provider.openSessionFor(kelas.id);

    await showModalBottomSheet(
      context: ctx,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationCheckSheet(
        provider: provider,
        token: token,
        pesertaId: pesertaId,
        jadwalId: kelas.jadwalId,
        sessionId: session?.id,
        target: _targetFor(kelas, session),
      ),
    );
    if (mounted) provider.fetchAttendanceData(token);
  }

  Future<void> _handleIzinSakit(
      BuildContext ctx, String type, TrainingClassModel kelas) async {
    final provider = ctx.read<AttendanceProvider>();
    final token = _token;
    final pesertaId = _resolvePesertaId();

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IzinSakitSheet(
        type: type,
        provider: provider,
        token: token,
        pesertaId: pesertaId,
        jadwalId: kelas.jadwalId,
      ),
    );
    if (mounted) provider.fetchAttendanceData(token);
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Presensi Peserta',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Presensi Hari Ini'),
            Tab(text: 'Riwayat Kehadiran'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ─── Tab 1: Hari Ini ────────────────────────────────────────────────────

  Widget _buildTodayTab() {
    return Consumer2<AttendanceProvider, TrainingClassProvider>(
      builder: (context, provider, classProvider, _) {
        final active = _activeClasses(classProvider);

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AttendanceClockCard(),
                const SizedBox(height: 14),
                AttendanceStatRow(
                  summary: provider.summary,
                  percentage: provider.attendancePercentage,
                ),
                const SizedBox(height: 14),
                if (provider.errorMessage != null) ...[
                  AttendanceErrorCard(
                      message: provider.errorMessage!, onRetry: _refresh),
                  const SizedBox(height: 14),
                ],
                _buildSectionTitle(active.length),
                const SizedBox(height: 10),
                ..._buildClassCards(context, provider, classProvider, active),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(int count) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Presensi Pelatihan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (count > 0)
          Text(
            '$count kelas berlangsung',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
      ],
    );
  }

  /// Satu kartu presensi per kelas pelatihan yang sedang berlangsung.
  List<Widget> _buildClassCards(
    BuildContext context,
    AttendanceProvider provider,
    TrainingClassProvider classProvider,
    List<TrainingClassModel> active,
  ) {
    if (active.isEmpty) {
      if (classProvider.isLoading) return const [_spinner];
      final today = provider.todayAttendance;
      return [
        if (today != null) ...[
          AttendanceTodayStatusCard(today: today),
          const SizedBox(height: 12),
        ],
        const AttendanceInfoNote(
          icon: Icons.event_busy_rounded,
          text: 'Belum ada kelas pelatihan yang sedang berlangsung, '
              'sehingga presensi belum dapat dilakukan.',
        ),
      ];
    }

    final cards = <Widget>[];
    for (final kelas in active) {
      final session = provider.openSessionFor(kelas.id);
      final today = provider.todayRecordFor(kelas.jadwalId);
      final target = _targetFor(kelas, session);
      if (cards.isNotEmpty) cards.add(const SizedBox(height: 12));
      cards.add(AttendanceClassCard(
        kelas: kelas,
        session: session,
        sessionChecked: provider.sessionChecked(kelas.id),
        today: today,
        locationLabel: target.label,
        radiusMeter: target.radiusMeter,
        actions: _actionsFor(context, provider, kelas, today),
      ));
    }
    return cards;
  }

  /// Aksi presensi di dalam kartu sebuah kelas.
  List<Widget> _actionsFor(
    BuildContext context,
    AttendanceProvider provider,
    TrainingClassModel kelas,
    AttendanceItem? today,
  ) {
    // Sudah presensi hari ini → status tampil di kartu, tidak ada aksi lagi.
    if (today != null) return const [];

    // Status hari ini belum diketahui (loading / gagal) → jangan izinkan absen.
    if (!provider.todayLoaded) {
      if (provider.isLoading) return const [_spinner];
      return const [
        _CardNote(
          icon: Icons.cloud_off_rounded,
          text: 'Status presensi hari ini belum dapat diperiksa. '
              'Tarik layar ke bawah untuk mencoba lagi.',
        ),
      ];
    }

    // Presensi masuk dikontrol instruktur: hanya saat sesi dibuka.
    final Widget masuk;
    if (!provider.sessionChecked(kelas.id)) {
      masuk = const _CardNote(
        icon: Icons.cloud_off_rounded,
        text: 'Status sesi presensi belum dapat diperiksa. '
            'Tarik layar ke bawah untuk mencoba lagi.',
      );
    } else if (provider.openSessionFor(kelas.id) == null) {
      masuk = const _CardNote(
        icon: Icons.lock_clock_rounded,
        text: 'Presensi belum dibuka oleh instruktur.',
      );
    } else {
      masuk = _primaryButton(
        icon: Icons.fingerprint_rounded,
        label: 'Presensi Masuk',
        onPressed: () => _handlePresensiHadir(context, kelas),
      );
    }

    return [
      masuk,
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _izinSakitButton(context, 'izin', kelas)),
          const SizedBox(width: 10),
          Expanded(child: _izinSakitButton(context, 'sakit', kelas)),
        ],
      ),
    ];
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }

  Widget _izinSakitButton(
      BuildContext context, String type, TrainingClassModel kelas) {
    final isIzin = type == 'izin';
    final color = isIzin ? AppColors.orangeText : Colors.blue.shade700;
    return OutlinedButton.icon(
      onPressed: () => _handleIzinSakit(context, type, kelas),
      icon: Icon(isIzin ? Icons.mail_outline_rounded : Icons.healing_rounded,
          size: 18),
      label: Text(isIzin ? 'Izin' : 'Sakit',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Tab 2: Riwayat ──────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !provider.historyLoaded) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        // Gagal memuat & belum pernah ada data → error + retry,
        // bukan "Belum ada riwayat".
        if (!provider.historyLoaded && provider.errorMessage != null) {
          return _buildHistoryError(provider.errorMessage!);
        }

        return Column(
          children: [
            _buildEligibilityCard(provider),
            _buildFilterChips(provider),
            Expanded(child: _buildHistoryList(provider)),
          ],
        );
      },
    );
  }

  Widget _buildHistoryError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibilityCard(AttendanceProvider provider) {
    final hasData = provider.hasAttendanceData;
    final pct = provider.attendancePercentage;
    final isMemenuhi = provider.memenuhiSyarat == true;
    final minPct = provider.minimumPercentage.toStringAsFixed(0);

    final title = !hasData
        ? 'Belum Ada Data Kehadiran'
        : (provider.statusKelayakan?.isNotEmpty == true
            ? '${provider.statusKelayakan} (${pct.toStringAsFixed(0)}%)'
            : (isMemenuhi
                ? 'Memenuhi Syarat Sertifikasi (${pct.toStringAsFixed(0)}%)'
                : 'Kehadiran Belum Memenuhi (${pct.toStringAsFixed(0)}%)'));
    final desc = !hasData
        ? 'Status kelayakan akan tampil setelah ada catatan presensi. Syarat minimal kehadiran adalah $minPct%.'
        : (isMemenuhi
            ? 'Tingkat kehadiran Anda memenuhi syarat minimal $minPct% untuk kelulusan dan uji kompetensi BNSP.'
            : 'Syarat minimal kehadiran adalah $minPct% untuk dapat mengikuti ujian sertifikasi.');

    const warnBg = Color(0xFFFFF7ED);
    const warnBorder = Color(0xFFFFEDD5);
    const warnIcon = Color(0xFFEA580C);
    const warnTitle = Color(0xFF9A3412);
    const warnDesc = Color(0xFFC2410C);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMemenuhi ? AppColors.mintBg : warnBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMemenuhi ? AppColors.mint : warnBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMemenuhi ? Colors.white : warnBorder,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMemenuhi ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
              color: isMemenuhi ? AppColors.mintDark : warnIcon,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isMemenuhi ? AppColors.mintDark : warnTitle,
                    )),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMemenuhi
                          ? AppColors.mintDark.withValues(alpha: 0.8)
                          : warnDesc,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AttendanceProvider provider) {
    const filters = ['Semua', 'hadir', 'izin', 'sakit', 'alpha'];
    const labels = {
      'Semua': 'Semua',
      'hadir': 'Hadir',
      'izin': 'Izin',
      'sakit': 'Sakit',
      'alpha': 'Alpa',
    };

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = provider.selectedFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => provider.setFilter(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : const Color(0xFFF0F4F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    labels[f] ?? f,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Daftar riwayat dikelompokkan per bulan, dengan muat-lebih-banyak.
  Widget _buildHistoryList(AttendanceProvider provider) {
    final items = provider.attendanceList;

    // Susun entri: header bulan (String) + item presensi.
    final entries = <Object>[];
    String? lastMonth;
    for (final item in items) {
      final d = tryParseApiDate(item.date);
      if (d != null) {
        final month = formatMonthYear(d);
        if (month != lastMonth) {
          entries.add(month);
          lastMonth = month;
        }
      }
      entries.add(item);
    }
    final showFooter = provider.hasMore || provider.isLoadingMore;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
            provider.loadMore(_token);
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: (entries.isEmpty ? 1 : entries.length) + (showFooter ? 1 : 0),
          itemBuilder: (_, i) {
            if (entries.isEmpty && i == 0) {
              return const Padding(
                padding: EdgeInsets.only(top: 64),
                child: Center(
                  child: Text('Belum ada riwayat presensi.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ),
              );
            }
            if (i >= entries.length) return _buildLoadMoreFooter(provider);

            final e = entries[i];
            if (e is String) {
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                child: Text(e,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary)),
              );
            }
            return AttendanceHistoryCard(item: e as AttendanceItem);
          },
        ),
      ),
    );
  }

  Widget _buildLoadMoreFooter(AttendanceProvider provider) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.primary),
          ),
        ),
      );
    }
    return Center(
      child: TextButton(
        onPressed: () => provider.loadMore(_token),
        child: Text(
          provider.loadMoreFailed
              ? 'Gagal memuat. Ketuk untuk coba lagi'
              : 'Muat riwayat lebih lama',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

const _spinner = Center(
  child: Padding(
    padding: EdgeInsets.all(12),
    child: CircularProgressIndicator(color: AppColors.primary),
  ),
);

/// Catatan ringkas di dalam kartu presensi kelas.
class _CardNote extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CardNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.orangeText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orangeText)),
          ),
        ],
      ),
    );
  }
}
