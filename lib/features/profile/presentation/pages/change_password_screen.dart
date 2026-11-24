import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/profile/data/services/account_service.dart';

/// Ganti password untuk semua role (`PUT /profile/password`).
class ChangePasswordScreen extends StatefulWidget {
  final AccountService? service;
  const ChangePasswordScreen({super.key, this.service});

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
      InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(
            hidden
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: toggle,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ganti Password',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan Password'),
            ),
          ),
        ],
      ),
    );
  }
}
