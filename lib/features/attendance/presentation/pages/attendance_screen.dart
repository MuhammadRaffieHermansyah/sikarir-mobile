import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/data/services/attendance_service.dart';
import 'package:sikarir/features/attendance/data/services/location_service.dart';
import 'package:sikarir/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/profile/presentation/providers/peserta_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  final _svc = AttendanceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().user?.token;
      context.read<AttendanceProvider>().fetchAttendanceData(token);
      context.read<PesertaProvider>().fetchProfile(token);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer.cancel();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  String _pad(int n) => n.toString().padLeft(2, '0');

  String get _timeString =>
      '${_pad(_currentTime.hour)}:${_pad(_currentTime.minute)}:${_pad(_currentTime.second)}';

  String get _dateString {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final d = _currentTime;
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ─── Location Check + Presensi ──────────────────────────────────────────

  Future<void> _handlePresensiHadir(BuildContext ctx) async {
    final provider = ctx.read<AttendanceProvider>();
    final authProvider = ctx.read<AuthProvider>();
    final token = authProvider.user?.token;
    final pesertaProvider = ctx.read<PesertaProvider>();
    final pesertaId = (pesertaProvider.profile?.idPeserta.isNotEmpty == true) ? pesertaProvider.profile!.idPeserta : (authProvider.user?.userId ?? '');

    // Tampilkan bottom sheet proses cek lokasi
    if (!mounted) return;
    await showModalBottomSheet(
      context: ctx,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationCheckSheet(
        provider: provider,
        token: token,
        pesertaId: pesertaId,
        svc: _svc,
        currentTime: _currentTime,
      ),
    );
    // Refresh setelah modal ditutup
    if (mounted) provider.fetchAttendanceData(token);
  }

  Future<void> _handleIzinSakit(BuildContext ctx, String type) async {
    final provider = ctx.read<AttendanceProvider>();
    final authProvider = ctx.read<AuthProvider>();
    final token = authProvider.user?.token;
    final pesertaProvider = ctx.read<PesertaProvider>();
    final pesertaId = (pesertaProvider.profile?.idPeserta.isNotEmpty == true) ? pesertaProvider.profile!.idPeserta : (authProvider.user?.userId ?? '');

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IzinSakitSheet(
        type: type,
        provider: provider,
        token: token,
        pesertaId: pesertaId,
        svc: _svc,
        currentTime: _currentTime,
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
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        final today = provider.todayAttendance;
        final sudahAbsen = today != null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Jam digital
              _buildClockCard(),
              const SizedBox(height: 14),

              // Statistik
              _buildStatRow(provider.summary),
              const SizedBox(height: 14),

              // Status hari ini
              if (sudahAbsen) ...[
                _buildTodayStatusCard(today),
                const SizedBox(height: 14),
              ],

              // Lokasi (info card)
              _buildLokasiInfoCard(),
              const SizedBox(height: 20),

              // Tombol Presensi
              if (!sudahAbsen) ...[
                _buildPresensiButton(context),
                const SizedBox(height: 10),
                _buildIzinSakitRow(context),
              ] else ...[
                _buildSudahAbsenInfo(today),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildClockCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1A7A5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            _timeString,
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _dateString,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(AttendanceSummary summary) {
    final total = summary.totalPresent +
        summary.totalPermission +
        summary.totalSick +
        summary.totalAbsent;
    final pct = total > 0 ? (summary.totalPresent / total) * 100 : 100.0;

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Hadir', summary.totalPresent.toString(),
                AppColors.mintDark, AppColors.mintBg, Icons.check_circle_outline_rounded),
            _buildStatCard('Izin', summary.totalPermission.toString(),
                AppColors.orangeText, AppColors.orangeLight, Icons.mail_outline_rounded),
            _buildStatCard('Sakit', summary.totalSick.toString(),
                Colors.blue.shade700, Colors.blue.shade50, Icons.healing_rounded),
            _buildStatCard('Alpa', summary.totalAbsent.toString(),
                Colors.red.shade700, Colors.red.shade50, Icons.cancel_outlined),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Text('Persentase Kehadiran',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const Spacer(),
              Text('${pct.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLokasiInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mintBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lokasi Pelatihan',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary)),
                SizedBox(height: 2),
                Text(LocationService.defaultLokasiLabel,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('Radius presensi: ${LocationService.defaultRadius} meter',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresensiButton(BuildContext ctx) {
    return ElevatedButton.icon(
      onPressed: () => _handlePresensiHadir(ctx),
      icon: const Icon(Icons.fingerprint_rounded, size: 22),
      label: const Text(
        'Presensi Masuk',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }

  Widget _buildIzinSakitRow(BuildContext ctx) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleIzinSakit(ctx, 'izin'),
            icon: const Icon(Icons.mail_outline_rounded, size: 18),
            label: const Text('Pengajuan Izin',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.orangeText,
              side: const BorderSide(color: AppColors.orangeText),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleIzinSakit(ctx, 'sakit'),
            icon: const Icon(Icons.healing_rounded, size: 18),
            label: const Text('Laporan Sakit',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade700,
              side: BorderSide(color: Colors.blue.shade700),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStatusCard(AttendanceItem today) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (today.status.toLowerCase()) {
      case 'hadir':
        bg = AppColors.mintBg; fg = AppColors.mintDark;
        icon = Icons.check_circle_rounded; label = 'Sudah Hadir';
        break;
      case 'izin':
        bg = AppColors.orangeLight; fg = AppColors.orangeText;
        icon = Icons.mail_rounded; label = 'Izin Disetujui';
        break;
      case 'sakit':
        bg = Colors.blue.shade50; fg = Colors.blue.shade700;
        icon = Icons.healing_rounded; label = 'Keterangan Sakit';
        break;
      default:
        bg = Colors.red.shade50; fg = Colors.red.shade700;
        icon = Icons.cancel_rounded; label = 'Tidak Hadir';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                if (today.clockInTime != null)
                  Text('Jam masuk: ${today.clockInTime}',
                      style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.8))),
                if (today.jarakMeter != null)
                  Text('Jarak saat absen: ${today.jarakMeter!.toStringAsFixed(0)} m',
                      style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSudahAbsenInfo(AttendanceItem today) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Anda sudah melakukan presensi hari ini.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 2: Riwayat ──────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final pct = provider.summary.attendancePercentage;
        final isMemenuhi = pct >= 80;

        return Column(
          children: [
            // Card Rekap Kelayakan Kelulusan
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMemenuhi ? AppColors.mintBg : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isMemenuhi ? AppColors.mint : const Color(0xFFFFEDD5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMemenuhi ? Colors.white : const Color(0xFFFFEDD5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMemenuhi ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                      color: isMemenuhi ? AppColors.mintDark : const Color(0xFFEA580C),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMemenuhi
                              ? 'Memenuhi Syarat Sertifikasi (${pct.toStringAsFixed(0)}%)'
                              : 'Kehadiran Belum Memenuhi (${pct.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isMemenuhi ? AppColors.mintDark : const Color(0xFF9A3412),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMemenuhi
                              ? 'Tingkat kehadiran Anda memenuhi syarat minimal 80% untuk kelulusan dan uji kompetensi BNSP.'
                              : 'Syarat minimal kehadiran adalah 80% untuk dapat mengikuti ujian sertifikasi.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isMemenuhi ? AppColors.mintDark.withOpacity(0.8) : const Color(0xFFC2410C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips
            _buildFilterChips(provider),
            // List
            Expanded(
              child: provider.attendanceList.isEmpty
                  ? const Center(
                      child: Text('Belum ada riwayat presensi.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.attendanceList.length,
                      itemBuilder: (_, i) =>
                          _buildHistoryCard(provider.attendanceList[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips(AttendanceProvider provider) {
    const filters = ['Semua', 'hadir', 'izin', 'sakit', 'alpha'];
    const labels = {'Semua': 'Semua', 'hadir': 'Hadir', 'izin': 'Izin', 'sakit': 'Sakit', 'alpha': 'Alpa'};

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

  Widget _buildHistoryCard(AttendanceItem item) {
    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    switch (item.status.toLowerCase()) {
      case 'hadir':
        badgeBg = AppColors.mint; badgeText = AppColors.mintDark; badgeLabel = 'Hadir';
        break;
      case 'izin':
        badgeBg = AppColors.peachBg; badgeText = AppColors.orangeText; badgeLabel = 'Izin';
        break;
      case 'sakit':
        badgeBg = Colors.blue.shade50; badgeText = Colors.blue.shade700; badgeLabel = 'Sakit';
        break;
      default:
        badgeBg = Colors.red.shade50; badgeText = Colors.red.shade700; badgeLabel = 'Alpa';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Text(item.date,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: badgeBg, borderRadius: BorderRadius.circular(8)),
                child: Text(badgeLabel,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: badgeText)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.className,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Masuk: ${item.clockInTime ?? '-'}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (item.jarakMeter != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Jarak: ${item.jarakMeter!.toStringAsFixed(0)} m dari lokasi',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.notes!,
                style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color textColor, Color bgColor, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, color: textColor)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w600, color: textColor)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bottom Sheet: Cek Lokasi + Konfirmasi Presensi Hadir
// ═══════════════════════════════════════════════════════════════════════════════

class _LocationCheckSheet extends StatefulWidget {
  final AttendanceProvider provider;
  final String? token;
  final String pesertaId;
  final AttendanceService svc;
  final DateTime currentTime;

  const _LocationCheckSheet({
    required this.provider,
    required this.token,
    required this.pesertaId,
    required this.svc,
    required this.currentTime,
  });

  @override
  State<_LocationCheckSheet> createState() => _LocationCheckSheetState();
}

class _LocationCheckSheetState extends State<_LocationCheckSheet> {
  // State: 'checking' | 'valid' | 'invalid' | 'error' | 'submitting' | 'success'
  String _step = 'checking';
  LocationCheckResult? _result;
  String? _errorMsg;
  final _notesController = TextEditingController();

  // ID jadwal yang peserta ikuti (idealnya diambil dari API kelas peserta)
  // Sementara pakai '1' sebagai default — nanti bisa diubah ke selector
  final String _selectedJadwalId = '1';

  @override
  void initState() {
    super.initState();
    _doCheckLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _doCheckLocation() async {
    setState(() => _step = 'checking');
    try {
      final pos = await LocationService.getCurrentPosition();
      final check = LocationService.cekLokasiValid(position: pos);
      if (!mounted) return;
      setState(() {
        _result = check;
        _step = check.isValid ? 'valid' : 'invalid';
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _step = 'error';
        _errorMsg = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = 'error';
        _errorMsg = 'Gagal mendapatkan lokasi GPS.';
      });
    }
  }

  Future<void> _doSubmit() async {
    setState(() => _step = 'submitting');
    try {
      final now = widget.currentTime;
      final jamHadir =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final tanggal =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final request = AttendanceSubmitRequest(
        jadwalId: _selectedJadwalId,
        pesertaId: widget.pesertaId,
        tanggal: tanggal,
        jamHadir: jamHadir,
        status: 'hadir',
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        latitude: _result?.latitude,
        longitude: _result?.longitude,
      );

      await widget.provider.submitAttendance(request, widget.token);
      if (!mounted) return;
      setState(() => _step = 'success');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = 'valid'; // kembali ke valid agar bisa coba lagi
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMsg ?? 'Gagal presensi'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case 'checking':
        return _buildChecking();
      case 'valid':
        return _buildValid();
      case 'invalid':
        return _buildInvalid();
      case 'error':
        return _buildError();
      case 'submitting':
        return _buildSubmitting();
      case 'success':
        return _buildSuccess();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChecking() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 16),
        const Text('Memeriksa lokasi GPS...',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('Pastikan GPS aktif dan Anda mengizinkan akses lokasi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildValid() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.mintBg, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.fingerprint_rounded,
                color: AppColors.mintDark, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Konfirmasi Presensi Masuk',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 14),

        // Lokasi valid
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.mintBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.mint)),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.mintDark, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lokasi Valid ✓',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.mintDark)),
                  Text('Jarak Anda: ${r.jarakLabel} dari lokasi pelatihan',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.mintDark)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // Keterangan
        const Text('Keterangan (opsional)',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Tambah catatan...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF7FAF8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: _doSubmit,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Konfirmasi Presensi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildInvalid() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.location_off_rounded,
                color: Colors.red.shade700, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Lokasi Tidak Valid',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Text('Anda berada di luar radius presensi',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: Colors.red.shade700)),
              ]),
              const SizedBox(height: 8),
              Text('Jarak Anda: ${r.jarakLabel}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
              Text('Radius yang diizinkan: ${r.radiusMeter} meter',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE082))),
          child: const Text(
            'Presensi hanya dapat dilakukan dari lokasi pelatihan. '
            'Pastikan Anda berada di area BLK Jember.',
            style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: _doCheckLocation,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Cek Ulang Lokasi',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Kembali'),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.gps_off_rounded, color: Colors.orange, size: 48),
        const SizedBox(height: 12),
        const Text('GPS Tidak Tersedia',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(_errorMsg ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _doCheckLocation,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Coba Lagi',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildSubmitting() {
    return const Column(
      children: [
        CircularProgressIndicator(color: AppColors.primary),
        SizedBox(height: 16),
        Text('Menyimpan presensi...',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
              color: AppColors.mintBg, shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.mintDark, size: 48),
        ),
        const SizedBox(height: 14),
        const Text('Presensi Berhasil!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text('Kehadiran Anda telah tercatat pada ${widget.svc.formatDate(DateTime.now())}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(200, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bottom Sheet: Pengajuan Izin / Sakit
// ═══════════════════════════════════════════════════════════════════════════════

class _IzinSakitSheet extends StatefulWidget {
  final String type; // 'izin' | 'sakit'
  final AttendanceProvider provider;
  final String? token;
  final String pesertaId;
  final AttendanceService svc;
  final DateTime currentTime;

  const _IzinSakitSheet({
    required this.type,
    required this.provider,
    required this.token,
    required this.pesertaId,
    required this.svc,
    required this.currentTime,
  });

  @override
  State<_IzinSakitSheet> createState() => _IzinSakitSheetState();
}

class _IzinSakitSheetState extends State<_IzinSakitSheet> {
  final _notesController = TextEditingController();
  String _step = 'form'; // 'form' | 'submitting' | 'success'
  String? _error;
  final String _selectedJadwalId = '1';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _doSubmit() async {
    if (_notesController.text.trim().isEmpty) {
      setState(() => _error = 'Keterangan wajib diisi untuk ${widget.type == 'izin' ? 'pengajuan izin' : 'laporan sakit'}.');
      return;
    }
    setState(() { _step = 'submitting'; _error = null; });

    try {
      final now = widget.currentTime;
      final tanggal = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final jamHadir = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final request = AttendanceSubmitRequest(
        jadwalId: _selectedJadwalId,
        pesertaId: widget.pesertaId,
        tanggal: tanggal,
        jamHadir: jamHadir,
        status: widget.type,
        notes: _notesController.text.trim(),
        // Tidak perlu koordinat untuk izin/sakit
      );

      await widget.provider.submitAttendance(request, widget.token);
      if (!mounted) return;
      setState(() => _step = 'success');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = 'form';
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIzin = widget.type == 'izin';
    final title = isIzin ? 'Formulir Pengajuan Izin' : 'Formulir Keterangan Sakit';
    final iconColor = isIzin ? AppColors.orangeText : Colors.blue.shade700;
    final iconBg = isIzin ? AppColors.orangeLight : Colors.blue.shade50;
    final icon = isIzin ? Icons.mail_outline_rounded : Icons.healing_rounded;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          if (_step == 'success') ...[
            _buildSuccess(),
          ] else ...[
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 17,
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 16),

            if (_step == 'submitting')
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else ...[
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!,
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                ),

              Text(isIzin ? 'Alasan Izin' : 'Keterangan Sakit',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: isIzin
                      ? 'Contoh: Keperluan keluarga, urusan administrasi, dll.'
                      : 'Contoh: Demam sejak pagi, sedang berobat ke puskesmas.',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFFF7FAF8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _doSubmit,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(isIzin ? 'Ajukan Izin' : 'Laporkan Sakit',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isIzin ? AppColors.orangeText : Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final isIzin = widget.type == 'izin';
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: isIzin ? AppColors.orangeLight : Colors.blue.shade50,
              shape: BoxShape.circle),
          child: Icon(Icons.check_circle_rounded,
              color: isIzin ? AppColors.orangeText : Colors.blue.shade700, size: 48),
        ),
        const SizedBox(height: 14),
        Text(isIzin ? 'Izin Berhasil Diajukan!' : 'Laporan Sakit Terkirim!',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('Keterangan kehadiran Anda telah tercatat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(200, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
