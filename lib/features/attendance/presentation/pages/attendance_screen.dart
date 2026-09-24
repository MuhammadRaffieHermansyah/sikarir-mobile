import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().user?.token;
      context.read<AttendanceProvider>().fetchAttendanceData(token);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer.cancel();
    super.dispose();
  }

  String _formatTimeNumber(int n) => n.toString().padLeft(2, '0');

  void _showAttendanceModal({required String type}) {
    final notesController = TextEditingController();
    String selectedClass = 'Desain Grafis & UI/UX (Lab 02)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: type == 'hadir'
                          ? AppColors.mintBg
                          : (type == 'izin' ? AppColors.orangeLight : Colors.blue.shade50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      type == 'hadir'
                          ? Icons.touch_app_rounded
                          : (type == 'izin' ? Icons.mail_outline_rounded : Icons.healing_rounded),
                      color: type == 'hadir'
                          ? AppColors.mintDark
                          : (type == 'izin' ? AppColors.orangeText : Colors.blue.shade700),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    type == 'hadir'
                        ? 'Konfirmasi Presensi Masuk'
                        : (type == 'izin' ? 'Formulir Pengajuan Izin' : 'Formulir Keterangan Sakit'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Kelas Pelatihan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedClass,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: const [
                      DropdownMenuItem(
                        value: 'Desain Grafis & UI/UX (Lab 02)',
                        child: Text('Desain Grafis & UI/UX • Lab Komputer 02'),
                      ),
                      DropdownMenuItem(
                        value: 'Junior Web Developer (Lab 01)',
                        child: Text('Junior Web Developer • Lab Pemrograman 01'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedClass = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (type != 'hadir') ...[
                const Text(
                  'Keterangan & Alasan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: type == 'izin'
                        ? 'Tuliskan alasan izin keperluan Anda...'
                        : 'Tuliskan keluhan atau keterangan dokter...',
                    filled: true,
                    fillColor: const Color(0xFFF7FAF8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mintBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.mint),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.mintDark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lokasi: BLK Jember, Jl. Basuki Rahmat No. 203 (Radius Sesuai)',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final token = context.read<AuthProvider>().user?.token;
                    final req = AttendanceSubmitRequest(
                      classId: '1',
                      status: type,
                      notes: notesController.text.trim().isNotEmpty
                          ? notesController.text.trim()
                          : (type == 'hadir' ? 'Presensi Tatap Muka Terverifikasi' : null),
                      location: 'BLK Jember • Lab Komputer 02',
                    );

                    try {
                      await context.read<AttendanceProvider>().submitAttendance(req, token);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  type == 'hadir'
                                      ? 'Presensi masuk berhasil dicatat!'
                                      : 'Pengajuan $type berhasil dikirim!',
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.primaryDark,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal presensi: $e'),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: type == 'hadir'
                        ? AppColors.primary
                        : (type == 'izin' ? AppColors.orange : Colors.blue.shade700),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    type == 'hadir' ? 'Kirim Presensi Hadir' : 'Kirim Pengajuan',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClockOutDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Presensi Pulang / Selesai Sesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: const Text(
            'Apakah Anda sudah menyelesaikan seluruh agenda kelas hari ini dan ingin melakukan presensi pulang?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final token = context.read<AuthProvider>().user?.token;
                await context.read<AttendanceProvider>().clockOut(token);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Presensi pulang berhasil dicatat. Selamat istirahat!'),
                      backgroundColor: AppColors.primaryDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Konfirmasi Pulang'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final summary = attendanceProvider.summary;
    final today = attendanceProvider.todayAttendance;

    final hourStr = _formatTimeNumber(_currentTime.hour);
    final minStr = _formatTimeNumber(_currentTime.minute);
    final secStr = _formatTimeNumber(_currentTime.second);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Presensi & Kehadiran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () {
              final token = context.read<AuthProvider>().user?.token;
              attendanceProvider.fetchAttendanceData(token);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Presensi Hari Ini'),
            Tab(text: 'Riwayat Kehadiran'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Presensi Hari Ini
          RefreshIndicator(
            onRefresh: () async {
              final token = context.read<AuthProvider>().user?.token;
              await attendanceProvider.fetchAttendanceData(token);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Live Clock Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.location_city_rounded, color: AppColors.mint, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'BLK Jember • Lab Komputer 02',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: today != null ? AppColors.mint : AppColors.orangeLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              today != null ? 'Sudah Presensi' : 'Belum Presensi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: today != null ? AppColors.mintDark : AppColors.orangeText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$hourStr:$minStr:$secStr WIB',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Jadwal Sesi: 08:00 - 15:00 WIB (Toleransi Masuk 15 Menit)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Action buttons row
                      if (today == null) ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () => _showAttendanceModal(type: 'hadir'),
                                icon: const Icon(Icons.fingerprint_rounded, size: 20),
                                label: const Text('Presensi Masuk', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.mint,
                                  foregroundColor: AppColors.mintDark,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: () => _showAttendanceModal(type: 'izin'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white54),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Izin / Sakit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('Jam Masuk', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    today.clockInTime ?? '-',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 28, color: Colors.white24),
                              Column(
                                children: [
                                  const Text('Jam Pulang', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    today.clockOutTime ?? 'Belum Pulang',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (today.clockOutTime == null && today.status == 'hadir') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showClockOutDialog,
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: const Text('Presensi Pulang / Selesai Kelas', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Attendance Stats Cards
                const Text(
                  'Rekapitulasi Kehadiran Peserta',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatCard('Hadir', '${summary.totalPresent}', AppColors.mintDark, AppColors.mintBg, Icons.check_circle_outline_rounded),
                    _buildStatCard('Izin', '${summary.totalPermission}', AppColors.orangeText, AppColors.peachBg, Icons.mail_outline_rounded),
                    _buildStatCard('Sakit', '${summary.totalSick}', Colors.blue.shade700, Colors.blue.shade50, Icons.healing_outlined),
                    _buildStatCard('Alpa', '${summary.totalAbsent}', Colors.red.shade700, Colors.red.shade50, Icons.cancel_outlined),
                  ],
                ),
                const SizedBox(height: 16),

                // Percentage banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Persentase Kehadiran Kelas',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${summary.attendancePercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: summary.attendancePercentage / 100,
                          minHeight: 8,
                          backgroundColor: AppColors.cardBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Minimal kehadiran 85% untuk memenuhi syarat sertifikasi kompetensi BNSP.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TAB 2: Riwayat Kehadiran
          RefreshIndicator(
            onRefresh: () async {
              final token = context.read<AuthProvider>().user?.token;
              await attendanceProvider.fetchAttendanceData(token);
            },
            child: Column(
              children: [
                // Filter chips
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Semua', 'Hadir', 'Izin', 'Sakit', 'Alpa'].map((filter) {
                        final isSelected = attendanceProvider.selectedFilter.toLowerCase() == filter.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (_) => attendanceProvider.setFilter(filter),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: attendanceProvider.attendanceList.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada data presensi pada kategori ini.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: attendanceProvider.attendanceList.length,
                          itemBuilder: (context, index) {
                            final item = attendanceProvider.attendanceList[index];
                            return _buildAttendanceHistoryCard(item);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color textColor, Color bgColor, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceHistoryCard(AttendanceItem item) {
    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    switch (item.status.toLowerCase()) {
      case 'hadir':
        badgeBg = AppColors.mint;
        badgeText = AppColors.mintDark;
        badgeLabel = 'Hadir';
        break;
      case 'izin':
        badgeBg = AppColors.peachBg;
        badgeText = AppColors.orangeText;
        badgeLabel = 'Izin';
        break;
      case 'sakit':
        badgeBg = Colors.blue.shade50;
        badgeText = Colors.blue.shade700;
        badgeLabel = 'Sakit';
        break;
      default:
        badgeBg = Colors.red.shade50;
        badgeText = Colors.red.shade700;
        badgeLabel = 'Alpa';
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
              Text(
                item.date,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.className,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Masuk: ${item.clockInTime ?? '-'} • Pulang: ${item.clockOutTime ?? '-'}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.notes!,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
