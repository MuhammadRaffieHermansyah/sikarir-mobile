import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/data/models/auth_models.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Back arrow
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 20),
                // Logo/Title
                const Text(
                  'Daftar',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Buat akun baru',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'masukkan nama lengkap Anda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'masukkan email Anda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email wajib diisi';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'minimal 6 karakter',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.remove_red_eye_outlined
                            : Icons.remove_red_eye_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 24),
                // Register button
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    try {
                      await _authProvider.register(
                        RegisterRequest(
                          name: _nameController.text.trim(),
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        ),
                      );
                      navigator.popUntil((route) => route.isFirst);
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Gagal daftar: $e'),
                          backgroundColor: AppColors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Daftar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Login link
                TextButton(
                  onPressed: () {
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text(
                    'Sudah punya akun? Masuk',
                    style: TextStyle(
                      color: AppColors.mint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Or divider
                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        thickness: 1,
                        color: AppColors.cardBorder,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'atau',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        thickness: 1,
                        color: AppColors.cardBorder,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Social login buttons
                const Text(
                  'Atau daftar dengan',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialButton(
                      icon: Icons.language_outlined,
                      color: AppColors.primary,
                      label: 'Google',
                    ),
                    _buildSocialButton(
                      icon: Icons.apple_outlined,
                      color: AppColors.primaryLight,
                      label: 'Apple',
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

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}