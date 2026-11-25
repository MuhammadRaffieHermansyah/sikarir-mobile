import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/instructor/presentation/widgets/instructor_ui.dart';
import 'package:sikarir/features/profile/data/models/instructor_profile_model.dart';
import 'package:sikarir/features/profile/data/services/account_service.dart';

/// Ubah profil instruktur. Mengembalikan [InstructorProfile] terbaru saat
/// disimpan (lewat `Navigator.pop`).
class InstructorProfileEditScreen extends StatefulWidget {
  final InstructorProfile initial;
  final AccountService? service;

  const InstructorProfileEditScreen({
    super.key,
    required this.initial,
    this.service,
  });

  @override
  State<InstructorProfileEditScreen> createState() =>
      _InstructorProfileEditScreenState();
}

class _InstructorProfileEditScreenState
    extends State<InstructorProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.name);
  late final _phone = TextEditingController(text: widget.initial.phone);
  late final _bio = TextEditingController(text: widget.initial.bio);
  late final _expertise = TextEditingController(text: widget.initial.expertise);
  late final AccountService _service = widget.service ?? AccountService();
  XFile? _photo;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    _expertise.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await _service.updateInstructorProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        bio: _bio.text.trim(),
        expertise: _expertise.text.trim(),
        photoPath: _photo?.path,
        token: auth.token,
      );
      await auth.updateUserName(result.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Pertahankan foto lama bila server tidak mengembalikan foto baru.
      Navigator.pop(
        context,
        InstructorProfile(
          id: result.id.isNotEmpty ? result.id : widget.initial.id,
          name: result.name,
          email: result.email.isNotEmpty ? result.email : widget.initial.email,
          phone: result.phone,
          bio: result.bio,
          expertise: result.expertise,
          photo: result.photo ?? widget.initial.photo,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, {String? hint, IconData? icon}) =>
      instructorInputDecoration(label, hint: hint, icon: icon);

  @override
  Widget build(BuildContext context) {
    final networkPhoto = widget.initial.photoUrl;
    final ImageProvider? avatar = _photo != null
        ? FileImage(File(_photo!.path))
        : (networkPhoto != null ? NetworkImage(networkPhoto) : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const InstructorAppBar(
        title: 'Ubah Profil',
        subtitle: 'Nama, foto, bio, dan keahlian',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.mint,
                  backgroundImage: avatar,
                  child: avatar == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: AppColors.mintDark,
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _saving ? null : _pickPhoto,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          InstructorCard(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: _decoration(
                      'Nama lengkap',
                      icon: Icons.person_outline_rounded,
                    ),
                    maxLength: 100,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  TextFormField(
                    initialValue: widget.initial.email,
                    enabled: false,
                    decoration: _decoration(
                      'Email (tidak dapat diubah)',
                      icon: Icons.mail_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: _decoration(
                      'Nomor WhatsApp (opsional)',
                      icon: Icons.phone_outlined,
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return null;
                      return RegExp(r'^\d{8,15}$').hasMatch(value)
                          ? null
                          : 'Nomor harus 8–15 digit angka';
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _expertise,
                    maxLength: 200,
                    decoration: _decoration(
                      'Keahlian (opsional)',
                      hint: 'Pisahkan dengan koma, mis. HTML, Laravel',
                      icon: Icons.star_outline_rounded,
                    ),
                  ),
                  TextFormField(
                    controller: _bio,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: _decoration('Bio singkat (opsional)'),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(fontSize: 12.5, color: Colors.red.shade700),
              ),
            ),
          InstructorPrimaryButton(
            label: 'Simpan Profil',
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
