import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';
import 'package:sikarir/features/training/presentation/pages/class_detail_screen.dart';
import 'package:sikarir/features/training/presentation/providers/training_class_provider.dart';

class MyClassesScreen extends StatefulWidget {
  const MyClassesScreen({super.key});

  @override
  State<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().user?.token;
      context.read<TrainingClassProvider>().fetchClasses(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainingClassProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Kelas Pelatihan Saya',
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
              provider.fetchClasses(token);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final token = context.read<AuthProvider>().user?.token;
          await provider.fetchClasses(token);
        },
        child: Column(
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Semua', provider),
                    _buildFilterChip('berlangsung', provider, label: 'Sedang Aktif'),
                    _buildFilterChip('akan_datang', provider, label: 'Akan Datang'),
                    _buildFilterChip('selesai', provider, label: 'Selesai'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : provider.classes.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada kelas pelatihan pada kategori ini.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.classes.length,
                          itemBuilder: (context, index) {
                            final item = provider.classes[index];
                            return _buildClassCard(item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, TrainingClassProvider provider, {String? label}) {
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

  Widget _buildClassCard(TrainingClassModel item) {
    Color statusBg;
    Color statusText;
    String statusLabel;

    if (item.status == 'berlangsung') {
      statusBg = AppColors.mint;
      statusText = AppColors.mintDark;
      statusLabel = 'Sedang Berlangsung';
    } else if (item.status == 'akan_datang') {
      statusBg = AppColors.peachBg;
      statusText = AppColors.orangeText;
      statusLabel = 'Akan Datang';
    } else {
      statusBg = Colors.grey.shade200;
      statusText = Colors.grey.shade700;
      statusLabel = 'Selesai';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClassDetailScreen(trainingClass: item),
              ),
            );
          },
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
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusText,
                        ),
                      ),
                    ),
                    Text(
                      item.code,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.instructor,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.room,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progress Pembelajaran', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                      '${(item.progress * 100).toInt()}% (${item.completedSessions}/${item.totalSessions} Sesi)',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      item.progress >= 1.0 ? AppColors.mintDark : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Periode: ${item.startDate}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const Row(
                      children: [
                        Text(
                          'Lihat Silabus',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
