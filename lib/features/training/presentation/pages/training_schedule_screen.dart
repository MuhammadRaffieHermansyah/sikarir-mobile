import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/training/data/models/training_schedule_model.dart';
import 'package:sikarir/features/training/presentation/providers/training_schedule_provider.dart';

class TrainingScheduleScreen extends StatefulWidget {
  const TrainingScheduleScreen({super.key});

  @override
  State<TrainingScheduleScreen> createState() => _TrainingScheduleScreenState();
}

class _TrainingScheduleScreenState extends State<TrainingScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().user?.token;
      context.read<TrainingScheduleProvider>().fetchSchedules(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainingScheduleProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Jadwal Pelatihan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () {
              final token = context.read<AuthProvider>().user?.token;
              provider.fetchSchedules(token);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final token = context.read<AuthProvider>().user?.token;
          await provider.fetchSchedules(token);
        },
        child: Column(
          children: [
            // Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Semua', provider),
                    _buildFilterChip('tatap_muka', provider, label: 'Tatap Muka di Lab'),
                    _buildFilterChip('online', provider, label: 'Kelas Online (Zoom)'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : provider.schedules.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada jadwal pelatihan pada kategori ini.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.schedules.length,
                          itemBuilder: (context, index) {
                            final item = provider.schedules[index];
                            return _buildScheduleCard(item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, TrainingScheduleProvider provider, {String? label}) {
    final isSelected = provider.filter.toLowerCase() == key.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label ?? key),
        selected: isSelected,
        onSelected: (_) => provider.setFilter(key),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildScheduleCard(TrainingScheduleModel item) {
    final isOnline = item.type == 'online';
    final isToday = item.date.toLowerCase().contains('hari ini');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isToday ? AppColors.mintDark : AppColors.cardBorder,
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.blue.shade50 : AppColors.mintBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOnline ? Icons.videocam_rounded : Icons.apartment_rounded,
                        size: 14,
                        color: isOnline ? Colors.blue.shade700 : AppColors.mintDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOnline ? 'Kelas Daring (Online)' : 'Tatap Muka di Lab',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOnline ? Colors.blue.shade700 : AppColors.mintDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.date,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isToday ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.topic,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '${item.startTime} - ${item.endTime} WIB',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Spacer(),
                const Icon(Icons.meeting_room_outlined, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  item.room,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Instruktur: ${item.instructor}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (isOnline && item.meetUrl != null) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Membuka tautan meeting: ${item.meetUrl}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.video_call_rounded, size: 18),
                      label: const Text('Gabung Zoom', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                      );
                    },
                    icon: const Icon(Icons.fingerprint_rounded, size: 18),
                    label: const Text('Presensi Sesi', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
