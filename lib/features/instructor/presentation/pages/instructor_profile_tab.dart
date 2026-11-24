import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/profile/data/models/instructor_profile_model.dart';
import 'package:sikarir/features/profile/data/services/account_service.dart';
import 'package:sikarir/features/profile/presentation/pages/change_password_screen.dart';
import 'package:sikarir/features/profile/presentation/pages/instructor_profile_edit_screen.dart';

/// Tab profil instruktur: tampilan profil, ubah profil, ganti password, keluar.
class InstructorProfileTab extends StatefulWidget {
  const InstructorProfileTab({super.key});

  @override
  State<InstructorProfileTab> createState() => _InstructorProfileTabState();
}

class _InstructorProfileTabState extends State<InstructorProfileTab> {
  final _service = AccountService();
  InstructorProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final token = context.read<AuthProvider>().token;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _service.getInstructorProfile(token);
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final user = context.read<AuthProvider>().user;
    final current =
        _profile ??
        InstructorProfile(name: user?.name ?? '', email: user?.email ?? '');
    final updated = await Navigator.push<InstructorProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => InstructorProfileEditScreen(initial: current),
      ),
    );
    if (updated != null && mounted) setState(() => _profile = updated);
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Akun?'),
        content: const Text(
          'Anda perlu login kembali untuk mengakses aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Keluar', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final profile = _profile;
    final name = (profile?.name.isNotEmpty ?? false)
        ? profile!.name
        : (user?.name ?? '-');
    final email = (profile?.email.isNotEmpty ?? false)
        ? profile!.email
        : (user?.email ?? '-');
    final photoUrl = profile?.photoUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profil Instruktur',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.mint,
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? const Icon(
                                Icons.person_rounded,
                                color: AppColors.mintDark,
                                size: 30,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mintBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Instruktur',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.mintDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_loading && profile == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(color: AppColors.primary),
                    ),
                  if (profile != null) ..._details(profile),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.edit_outlined,
              title: 'Ubah Profil',
              subtitle: 'Nama, foto, bio, dan keahlian',
              onTap: _edit,
            ),
            _MenuTile(
              icon: Icons.lock_outline_rounded,
              title: 'Ganti Password',
              subtitle: 'Perbarui password akun Anda',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout_rounded, color: Colors.red.shade700),
              label: Text(
                'Keluar',
                style: TextStyle(color: Colors.red.shade700),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.red.shade200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _details(InstructorProfile p) {
    Widget row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );

    return [
      const SizedBox(height: 4),
      if (p.phone.isNotEmpty) row(Icons.phone_outlined, 'WhatsApp', p.phone),
      if (p.expertiseList.isNotEmpty)
        row(Icons.star_outline_rounded, 'Keahlian', p.expertiseList.join(', ')),
      if (p.bio.isNotEmpty) row(Icons.notes_rounded, 'Bio', p.bio),
    ];
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mintBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: onTap,
        ),
      ),
    );
  }
}
