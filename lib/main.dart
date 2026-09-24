import 'package:flutter/material.dart';
import 'package:sikarir/app/router/app_router.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/pages/login_page.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/certificate/presentation/certificate_screen.dart';
import 'package:sikarir/features/home/home.dart';
import 'package:sikarir/features/job/presentation/job_list_screen.dart';
import 'package:sikarir/features/profile/presentation/profile_screen.dart';
import 'package:sikarir/features/training/presentation/training_catalog_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const SikarirApp());
}

class SikarirApp extends StatefulWidget {
  const SikarirApp({super.key});

  @override
  State<SikarirApp> createState() => _SikarirAppState();
}

class _SikarirAppState extends State<SikarirApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      builder: (context, child) {
        final authProvider = context.watch<AuthProvider>();
        return MaterialApp(
          title: 'SIKARIR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: authProvider.isAuthenticated
              ? const MainNavigationScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showNotificationModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_available,
                    color: AppColors.mintDark,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Kelas Tatap Muka Besok',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Pukul 08:00 WIB di Lab Komputer 02 • BLK Jember',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.peachBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.work,
                    color: AppColors.peachText,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Loker Baru Sesuai Keahlian',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Junior Web & UI Developer di PT Midtrans Indonesia',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomePage(
        onNotificationTap: _showNotificationModal,
        onProfileTap: () => _onTabSelected(4),
        onSwitchTab: _onTabSelected,
      ),
      TrainingCatalogScreen(
        onNotificationTap: _showNotificationModal,
        onProfileTap: () => _onTabSelected(4),
      ),
      JobListScreen(
        onNotificationTap: _showNotificationModal,
        onProfileTap: () => _onTabSelected(4),
        onNavigateToCertificate: () => _onTabSelected(3),
      ),
      CertificateScreen(
        onNotificationTap: _showNotificationModal,
        onProfileTap: () => _onTabSelected(4),
      ),
      ProfileScreen(onNotificationTap: _showNotificationModal),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_outlined,
                  Icons.home_rounded,
                  'Beranda',
                ),
                _buildNavItem(
                  1,
                  Icons.school_outlined,
                  Icons.school_rounded,
                  'Pelatihan',
                ),
                _buildNavItem(
                  2,
                  Icons.work_outline_rounded,
                  Icons.work_rounded,
                  'Lowongan',
                ),
                _buildNavItem(
                  3,
                  Icons.verified_outlined,
                  Icons.verified_rounded,
                  'Sertifikat',
                ),
                _buildNavItem(
                  4,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData solidIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? solidIcon : outlineIcon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}