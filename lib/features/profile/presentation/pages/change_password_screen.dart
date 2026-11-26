import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/instructor/presentation/widgets/instructor_ui.dart';
import 'package:sikarir/features/profile/data/services/account_service.dart';

/// Ganti password untuk semua role (`PUT /profile/password`).
class ChangePasswordScreen extends StatefulWidget {
  final AccountService? service;

  /// True jika dibuka otomatis setelah login dengan sandi sementara dari admin.
  final bool sandiSementara;

  const ChangePasswordScreen({super.key, this.service, this.sandiSementara = false});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  late final AccountService _service = widget.service ?? AccountService();
  bool _hideOld = true;
  bool _hideNew = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthProvider>().token;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.changePassword(
        oldPassword: _old.text,
        newPassword: _new.text,
        confirmation: _confirm.text,
        token: token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diubah.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, bool hidden, VoidCallback toggle) =>
      instructorInputDecoration(
        label,
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: toggle,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const InstructorAppBar(
        title: 'Ganti Password',
        subtitle: 'Perbarui password akun Anda',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mintBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppColors.mintDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.sandiSementara
                        ? 'Anda masuk memakai sandi sementara dari admin BLK. Isi "password lama" dengan sandi sementara tersebut, lalu buat password baru minimal 8 karakter.'
                        : 'Gunakan password minimal 8 karakter dan berbeda dari password lama.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.mintDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _old,
                  obscureText: _hideOld,
                  decoration: _decoration(
                    'Password lama',
                    _hideOld,
                    () => setState(() => _hideOld = !_hideOld),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Password lama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _new,
                  obscureText: _hideNew,
                  decoration: _decoration(
                    'Password baru',
                    _hideNew,
                    () => setState(() => _hideNew = !_hideNew),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return 'Password baru minimal 8 karakter';
                    }
                    if (v == _old.text) {
                      return 'Password baru tidak boleh sama dengan yang lama';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: _hideNew,
                  decoration: _decoration(
                    'Konfirmasi password baru',
                    _hideNew,
                    () => setState(() => _hideNew = !_hideNew),
                  ),
                  validator: (v) =>
                      v != _new.text ? 'Konfirmasi tidak cocok' : null,
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(fontSize: 12.5, color: Colors.red.shade700),
              ),
            ),
          const SizedBox(height: 20),
          InstructorPrimaryButton(
            label: 'Simpan Password',
            loading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
