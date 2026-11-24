import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/data/services/location_service.dart';
import 'package:sikarir/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_sheet_common.dart';
import 'package:sikarir/features/attendance/utils/attendance_formatters.dart';

enum _Step { checking, valid, invalid, error, submitting, success }

/// Jenis presensi yang dikonfirmasi lewat sheet lokasi.
enum AttendanceAction { masuk, pulang }

/// Bottom sheet: cek lokasi GPS lalu konfirmasi presensi masuk atau pulang.
class LocationCheckSheet extends StatefulWidget {
  final AttendanceProvider provider;
  final String? token;
  final String pesertaId;
  final String jadwalId;
  final AttendanceTarget target;
  final AttendanceAction action;

  /// Wajib untuk [AttendanceAction.pulang]: id catatan presensi masuk hari ini.
  final String? absenId;

  const LocationCheckSheet({
    super.key,
    required this.provider,
    required this.token,
    required this.pesertaId,
    required this.jadwalId,
    required this.target,
    this.action = AttendanceAction.masuk,
    this.absenId,
  }) : assert(action == AttendanceAction.masuk || absenId != null,
            'absenId wajib untuk presensi pulang');

  @override
  State<LocationCheckSheet> createState() => _LocationCheckSheetState();
}

class _LocationCheckSheetState extends State<LocationCheckSheet> {
  _Step _step = _Step.checking;
  LocationCheckResult? _result;
  String? _errorMsg;
  LocationExceptionType? _errorType;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _doCheckLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _doCheckLocation() async {
    setState(() => _step = _Step.checking);
    try {
      final pos = await LocationService.getCurrentPosition();
      final check = LocationService.cekTerhadapTarget(pos, widget.target);
      if (!mounted) return;
      setState(() {
        _result = check;
        _step = check.isValid ? _Step.valid : _Step.invalid;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.error;
        _errorMsg = e.message;
        _errorType = e.type;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _step = _Step.error;
        _errorMsg = 'Gagal mendapatkan lokasi GPS.';
        _errorType = LocationExceptionType.unknown;
      });
    }
  }

  bool get _isPulang => widget.action == AttendanceAction.pulang;

  Future<void> _doSubmit() async {
    setState(() => _step = _Step.submitting);
    try {
      if (_isPulang) {
        // Jam keluar ditentukan server; klien hanya mengirim koordinat.
        await widget.provider.clockOut(
          absenId: widget.absenId!,
          latitude: _result!.latitude,
          longitude: _result!.longitude,
          token: widget.token,
        );
      } else {
        // Waktu diambil saat submit (bukan snapshot saat sheet dibuka).
        final now = DateTime.now();
        final notes = _notesController.text.trim();

        final request = AttendanceSubmitRequest(
          jadwalId: widget.jadwalId,
          pesertaId: widget.pesertaId,
          tanggal: formatApiDate(now),
          jamHadir: formatApiTime(now),
          status: 'hadir',
          notes: notes.isEmpty ? null : notes,
          latitude: _result?.latitude,
          longitude: _result?.longitude,
        );

        await widget.provider.submitAttendance(request, widget.token);
      }
      if (!mounted) return;
      setState(() => _step = _Step.success);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _step = _Step.valid; // kembali ke valid agar bisa coba lagi
        _errorMsg = msg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AttendanceSheetFrame(
      crossAxisAlignment: _step == _Step.checking ||
              _step == _Step.submitting ||
              _step == _Step.success
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.stretch,
      children: [_buildContent()],
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case _Step.checking:
        return _buildLoading('Memeriksa lokasi GPS...',
            hint: 'Pastikan GPS aktif dan Anda mengizinkan akses lokasi.');
      case _Step.valid:
        return _buildValid();
      case _Step.invalid:
        return _buildInvalid();
      case _Step.error:
        return _buildError();
      case _Step.submitting:
        return _buildLoading('Menyimpan presensi...');
      case _Step.success:
        return _buildSuccess();
    }
  }

  Widget _buildLoading(String title, {String? hint}) {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildValid() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.mintBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(
                _isPulang ? Icons.logout_rounded : Icons.fingerprint_rounded,
                color: AppColors.mintDark,
                size: 22),
          ),
          const SizedBox(width: 12),
          Text(_isPulang ? 'Konfirmasi Presensi Pulang' : 'Konfirmasi Presensi Masuk',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.mintBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.mint)),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.mintDark, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lokasi Valid',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mintDark)),
                  Text('Jarak Anda: ${r.jarakLabel} dari lokasi pelatihan',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.mintDark)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        if (!_isPulang) ...[
          const Text('Keterangan (opsional)',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            decoration: attendanceNotesDecoration('Tambah catatan...'),
            maxLines: 2,
            maxLength: kAttendanceNotesMaxLength,
          ),
          const SizedBox(height: 12),
        ] else
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(
              'Jam pulang dicatat otomatis oleh server saat Anda mengonfirmasi.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _doSubmit,
          icon: const Icon(Icons.check_rounded),
          label: Text(_isPulang ? 'Konfirmasi Pulang' : 'Konfirmasi Presensi',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          style: attendancePrimaryButtonStyle(),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildInvalid() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.location_off_rounded,
                color: Colors.red.shade700, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Lokasi Tidak Valid',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Anda berada di luar radius presensi',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700)),
                ),
              ]),
              const SizedBox(height: 8),
              Text('Jarak Anda: ${r.jarakLabel}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
              Text('Radius yang diizinkan: ${r.radiusMeter} meter',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE082))),
          child: Text(
            'Presensi hanya dapat dilakukan dari lokasi pelatihan. '
            'Pastikan Anda berada di area ${widget.target.label}.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF795548)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _doCheckLocation,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Cek Ulang Lokasi',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: attendancePrimaryButtonStyle(height: 48, radius: 12),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Kembali'),
        ),
      ],
    );
  }

  Widget _buildError() {
    final needsSettings =
        _errorType == LocationExceptionType.permissionDeniedForever ||
            _errorType == LocationExceptionType.serviceDisabled;
    final isServiceOff = _errorType == LocationExceptionType.serviceDisabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.gps_off_rounded, color: Colors.orange, size: 48),
        const SizedBox(height: 12),
        Text(
            _errorType == LocationExceptionType.mockLocation
                ? 'Lokasi Palsu Terdeteksi'
                : 'GPS Tidak Tersedia',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(_errorMsg ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        if (needsSettings) ...[
          OutlinedButton.icon(
            onPressed: () => isServiceOff
                ? LocationService.openLocationSettings()
                : LocationService.openAppSettings(),
            icon: const Icon(Icons.settings_rounded),
            label: Text(
                isServiceOff ? 'Buka Pengaturan GPS' : 'Buka Pengaturan Aplikasi',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        ElevatedButton.icon(
          onPressed: _doCheckLocation,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Coba Lagi',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: attendancePrimaryButtonStyle(height: 48, radius: 12),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
              color: AppColors.mintBg, shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.mintDark, size: 48),
        ),
        const SizedBox(height: 14),
        Text(_isPulang ? 'Presensi Pulang Berhasil!' : 'Presensi Berhasil!',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(
            _isPulang
                ? 'Kepulangan Anda telah tercatat pada ${formatLongDate(DateTime.now())}'
                : 'Kehadiran Anda telah tercatat pada ${formatLongDate(DateTime.now())}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(200, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
