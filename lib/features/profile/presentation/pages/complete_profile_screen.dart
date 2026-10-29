import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/profile/presentation/providers/peserta_provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const CompleteProfileScreen({super.key, this.onCompleted});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomorWaController;
  late TextEditingController _nomorKkController;
  late TextEditingController _tempatLahirController;
  late TextEditingController _alamatController;
  late TextEditingController _jurusanController;
  late TextEditingController _jenisDisabilitasController;

  String _jenisKelamin = 'Laki-laki';
  String _pendidikanTerakhir = 'SMA / SMK / MA';
  String? _statusPendidikan; // 'sudah_lulus' | 'masih_menempuh'
  bool _isDisabilitas = false;
  DateTime? _tanggalLahir;
  File? _pasFotoFile;
  String? _pasFotoUrl; // URL foto yang sudah ada di server
  bool _initialized = false;

  final List<String> _listPendidikan = [
    'SD / Sederajat',
    'SMP / MTs',
    'SMA / SMK / MA',
    'Diploma (D1 - D3)',
    'Sarjana (S1 / D4)',
    'Magister (S2)',
  ];

  @override
  void initState() {
    super.initState();
    _nomorWaController = TextEditingController();
    _nomorKkController = TextEditingController();
    _tempatLahirController = TextEditingController();
    _alamatController = TextEditingController();
    _jurusanController = TextEditingController();
    _jenisDisabilitasController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  void _loadExistingData() {
    final profile = context.read<PesertaProvider>().profile;
    if (profile != null && !_initialized) {
      setState(() {
        _nomorWaController.text = profile.nomorWa ?? '';
        _nomorKkController.text = profile.nomorKk ?? '';
        _tempatLahirController.text = profile.tempatLahir ?? '';
        _alamatController.text = profile.alamatLengkap ?? '';
        _jurusanController.text = profile.jurusan ?? '';
        _jenisDisabilitasController.text = profile.jenisDisabilitas ?? '';
        _jenisKelamin =
            (profile.jenisKelamin.isNotEmpty) ? profile.jenisKelamin : 'Laki-laki';
        if (profile.pendidikanTerakhir != null &&
            profile.pendidikanTerakhir!.isNotEmpty) {
          if (_listPendidikan.contains(profile.pendidikanTerakhir)) {
            _pendidikanTerakhir = profile.pendidikanTerakhir!;
          }
        }
        if (profile.tanggalLahir != null) {
          _tanggalLahir = DateTime.tryParse(profile.tanggalLahir!);
        }
        _isDisabilitas = profile.isDisabilitas;
        _statusPendidikan = profile.statusPendidikan;
        _pasFotoUrl = profile.pasFoto;
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _nomorWaController.dispose();
    _nomorKkController.dispose();
    _tempatLahirController.dispose();
    _alamatController.dispose();
    _jurusanController.dispose();
    _jenisDisabilitasController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = _tanggalLahir ?? DateTime(now.year - 20, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 14),
      helpText: 'PILIH TANGGAL LAHIR',
      confirmText: 'PILIH',
      cancelText: 'BATAL',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tanggalLahir = picked;
      });
    }
  }

  Future<void> _pickPasFoto(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Izin kamera dinonaktifkan. Silakan aktifkan di Pengaturan.'),
                action: SnackBarAction(
                  label: 'Pengaturan',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
                backgroundColor: AppColors.orange,
              ),
            );
          }
          return;
        } else if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin kamera diperlukan untuk mengambil foto.'),
                backgroundColor: AppColors.orange,
              ),
            );
          }
          return;
        }
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _pasFotoFile = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint('Error pick image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showFotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Pilih Pas Foto',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Ambil dari Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPasFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPasFoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih tanggal lahir Anda.'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    if (_statusPendidikan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih status pendidikan Anda saat ini.'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    if (_pasFotoFile == null && (_pasFotoUrl == null || _pasFotoUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan unggah pas foto resmi Anda.'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    final token = context.read<AuthProvider>().user?.token;
    final pesertaProvider = context.read<PesertaProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final String tglFormatted =
        '${_tanggalLahir!.year}-${_tanggalLahir!.month.toString().padLeft(2, '0')}-${_tanggalLahir!.day.toString().padLeft(2, '0')}';

    final data = <String, dynamic>{
      'jenis_kelamin': _jenisKelamin,
      'nomor_wa': _nomorWaController.text.trim(),
      'nomor_kk': _nomorKkController.text.trim(),
      'tempat_lahir': _tempatLahirController.text.trim(),
      'tanggal_lahir': tglFormatted,
      'pendidikan_terakhir': _pendidikanTerakhir,
      'status_pendidikan': _statusPendidikan!,
      'alamat_lengkap': _alamatController.text.trim(),
      'is_disabilitas': _isDisabilitas ? '1' : '0',
      if (_isDisabilitas && _jenisDisabilitasController.text.trim().isNotEmpty)
        'jenis_disabilitas': _jenisDisabilitasController.text.trim(),
      if (_jurusanController.text.trim().isNotEmpty)
        'jurusan': _jurusanController.text.trim(),
    };

    try {
      await pesertaProvider.updateProfile(data, token, _pasFotoFile);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Data diri berhasil disimpan dan diverifikasi!'),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        if (widget.onCompleted != null) {
          widget.onCompleted!();
        } else {
          navigator.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<PesertaProvider>().profile;
    final userName = context.watch<AuthProvider>().user?.name ?? 'Peserta';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lengkapi Data Diri',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<PesertaProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Edukasi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAF5F0), Color(0xFFDCEDE4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.mint),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assignment_ind_rounded,
                            color: AppColors.mintDark,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $userName!',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Lengkapi data diri resmi Anda di bawah ini untuk dapat mendaftar program pelatihan vokasi dan mendapatkan sertifikasi BLK.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Nomor Peserta
                  if (profile?.nomorPeserta != null &&
                      profile!.nomorPeserta.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_outlined,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          const Text('No. Peserta: ',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            profile.nomorPeserta,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ========================
                  // SECTION: Data Pribadi
                  // ========================
                  _buildSectionCard(
                    title: 'Data Pribadi',
                    icon: Icons.person_rounded,
                    children: [
                      // Jenis Kelamin
                      _buildLabel('Jenis Kelamin *'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGenderChoice('Laki-laki', Icons.male_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child:
                                _buildGenderChoice('Perempuan', Icons.female_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nomor WhatsApp
                      _buildLabel('Nomor WhatsApp / HP Aktif *'),
                      TextFormField(
                        controller: _nomorWaController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          hint: 'Contoh: 081234567890',
                          prefixIcon: Icons.phone_android_rounded,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nomor WhatsApp wajib diisi';
                          }
                          if (v.trim().length < 9) {
                            return 'Nomor telepon tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nomor KK / NIK
                      _buildLabel('Nomor Kartu Keluarga (KK) / NIK *'),
                      TextFormField(
                        controller: _nomorKkController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          hint: '16 Digit No. KK atau KTP',
                          prefixIcon: Icons.credit_card_rounded,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nomor KK/NIK wajib diisi';
                          }
                          if (v.trim().length < 10) {
                            return 'Nomor KK/NIK minimal 10 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tempat & Tanggal Lahir
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Tempat Lahir *'),
                                TextFormField(
                                  controller: _tempatLahirController,
                                  decoration: _inputDecoration(
                                    hint: 'Kota kelahiran',
                                    prefixIcon: Icons.location_city_rounded,
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Wajib diisi'
                                          : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Tanggal Lahir *'),
                                GestureDetector(
                                  onTap: _selectDate,
                                  child: Container(
                                    height: 48,
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FBF9),
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_month_rounded,
                                            size: 18, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _tanggalLahir == null
                                                ? 'Pilih Tgl'
                                                : '${_tanggalLahir!.day}/${_tanggalLahir!.month}/${_tanggalLahir!.year}',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: _tanggalLahir == null
                                                  ? Colors.grey.shade400
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Alamat Lengkap
                      _buildLabel('Alamat Lengkap Domisili *'),
                      TextFormField(
                        controller: _alamatController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          hint:
                              'Masukkan alamat lengkap beserta RT/RW, Kelurahan, Kecamatan, Kota.',
                          prefixIcon: Icons.home_rounded,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Alamat domisili wajib diisi';
                          }
                          if (v.trim().length < 8) {
                            return 'Mohon tulis alamat lebih lengkap';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ========================
                  // SECTION: Pendidikan
                  // ========================
                  _buildSectionCard(
                    title: 'Pendidikan',
                    icon: Icons.school_rounded,
                    children: [
                      // Pendidikan Terakhir
                      _buildLabel('Pendidikan Terakhir *'),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBF9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _pendidikanTerakhir,
                            isExpanded: true,
                            items: _listPendidikan.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(p,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _pendidikanTerakhir = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Pendidikan Saat Ini
                      _buildLabel('Status Pendidikan Saat Ini *'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusChoice(
                              value: 'sudah_lulus',
                              label: 'Sudah Lulus',
                              icon: Icons.check_circle_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatusChoice(
                              value: 'masih_menempuh',
                              label: 'Masih Menempuh',
                              icon: Icons.menu_book_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Jurusan (opsional)
                      _buildLabel('Jurusan / Peminatan (opsional)'),
                      TextFormField(
                        controller: _jurusanController,
                        decoration: _inputDecoration(
                          hint: 'Contoh: Rekayasa Perangkat Lunak, IPA, dll.',
                          prefixIcon: Icons.school_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ========================
                  // SECTION: Disabilitas
                  // ========================
                  _buildSectionCard(
                    title: 'Aksesibilitas & Disabilitas',
                    icon: Icons.accessibility_new_rounded,
                    children: [
                      _buildLabel('Apakah Anda Penyandang Disabilitas? *'),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _isDisabilitas = false),
                              child: _buildYesNoTile(
                                label: 'Tidak',
                                icon: Icons.check_circle_outline_rounded,
                                isSelected: !_isDisabilitas,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _isDisabilitas = true),
                              child: _buildYesNoTile(
                                label: 'Ya',
                                icon: Icons.accessible_rounded,
                                isSelected: _isDisabilitas,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Jika ya, tampilkan field jenis disabilitas
                      if (_isDisabilitas) ...[
                        const SizedBox(height: 12),
                        _buildLabel('Jenis Disabilitas (opsional)'),
                        TextFormField(
                          controller: _jenisDisabilitasController,
                          decoration: _inputDecoration(
                            hint: 'Contoh: Tuna Rungu, Tuna Daksa, dll.',
                            prefixIcon: Icons.info_outline_rounded,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ========================
                  // SECTION: Pas Foto
                  // ========================
                  _buildSectionCard(
                    title: 'Pas Foto Resmi',
                    icon: Icons.photo_camera_rounded,
                    children: [
                      const Text(
                        'Unggah pas foto resmi berlatar belakang merah atau biru (format JPG/PNG, maks. 2MB).',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: _showFotoOptions,
                          child: Container(
                            width: 140,
                            height: 175,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FBF9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: (_pasFotoFile != null ||
                                        (_pasFotoUrl != null &&
                                            _pasFotoUrl!.isNotEmpty))
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                                width: (_pasFotoFile != null ||
                                        (_pasFotoUrl != null &&
                                            _pasFotoUrl!.isNotEmpty))
                                    ? 2
                                    : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _pasFotoFile != null
                                ? Image.file(_pasFotoFile!, fit: BoxFit.cover)
                                : (_pasFotoUrl != null &&
                                        _pasFotoUrl!.isNotEmpty)
                                    ? Image.network(
                                        _pasFotoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, e, st) =>
                                            _buildFotoPlaceholder(),
                                      )
                                    : _buildFotoPlaceholder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _showFotoOptions,
                          icon: const Icon(Icons.upload_rounded, size: 16),
                          label: Text(
                            (_pasFotoFile != null ||
                                    (_pasFotoUrl != null &&
                                        _pasFotoUrl!.isNotEmpty))
                                ? 'Ganti Foto'
                                : 'Unggah Foto',
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tombol Simpan
                  ElevatedButton(
                    onPressed: provider.isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Simpan Data Diri',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Helper Widgets ────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade200, thickness: 1),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildGenderChoice(String value, IconData icon) {
    final isSelected = _jenisKelamin == value;
    return GestureDetector(
      onTap: () => setState(() => _jenisKelamin = value),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintBg : const Color(0xFFF9FBF9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChoice({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _statusPendidikan == value;
    return GestureDetector(
      onTap: () => setState(() => _statusPendidikan = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintBg : const Color(0xFFF9FBF9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoTile({
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.mintBg : const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_rounded, size: 52, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(
          'Pas Foto\n3×4',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
      prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.primary),
      filled: true,
      fillColor: const Color(0xFFF9FBF9),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
