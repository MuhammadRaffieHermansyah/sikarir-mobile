import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_sheet_common.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_status_style.dart';
import 'package:sikarir/features/attendance/utils/attendance_formatters.dart';

enum _FormStep { form, submitting, success }

/// Batas rentang izin/sakit (hari kalender) dan ukuran lampiran — sesuai backend.
const int kMaxRentangHari = 14;
const int kMaxLampiranBytes = 2 * 1024 * 1024;

/// Bottom sheet: pengajuan izin / laporan sakit (satu hari atau rentang),
/// dengan lampiran foto opsional.
class IzinSakitSheet extends StatefulWidget {
  final String type; // 'izin' | 'sakit'
  final AttendanceProvider provider;
  final String? token;
  final String pesertaId;
  final String jadwalId;

  const IzinSakitSheet({
    super.key,
    required this.type,
    required this.provider,
    required this.token,
    required this.pesertaId,
    required this.jadwalId,
  });

  @override
  State<IzinSakitSheet> createState() => _IzinSakitSheetState();
}

class _IzinSakitSheetState extends State<IzinSakitSheet> {
  final _notesController = TextEditingController();
  final _picker = ImagePicker();
  _FormStep _step = _FormStep.form;
  String? _error;
  String? _successMessage;
  DateTimeRange? _range; // null = hari ini saja
  XFile? _attachment;

  bool get _isIzin => widget.type == 'izin';

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final today = _today;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      initialDateRange: _range ?? DateTimeRange(start: today, end: today),
      helpText: 'Pilih tanggal ${_isIzin ? 'izin' : 'sakit'}',
      saveText: 'Pilih',
    );
    if (picked == null || !mounted) return;

    final days = picked.end.difference(picked.start).inDays + 1;
    if (days > kMaxRentangHari) {
      setState(() => _error = 'Rentang maksimal $kMaxRentangHari hari.');
      return;
    }
    setState(() {
      _error = null;
      _range = (picked.start == today && picked.end == today) ? null : picked;
    });
  }

  Future<void> _pickAttachment(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (picked == null || !mounted) return;

      if (await picked.length() > kMaxLampiranBytes) {
        setState(() => _error = 'Ukuran lampiran maksimal 2 MB.');
        return;
      }
      setState(() {
        _attachment = picked;
        _error = null;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() => _error =
          'Tidak dapat mengakses ${source == ImageSource.camera ? 'kamera' : 'galeri'}. Periksa izin aplikasi.');
    }
  }

  void _chooseAttachmentSource() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Ambil foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAttachment(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAttachment(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doSubmit() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      setState(() => _error =
          'Keterangan wajib diisi untuk ${_isIzin ? 'pengajuan izin' : 'laporan sakit'}.');
      return;
    }
    setState(() {
      _step = _FormStep.submitting;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final start = _range?.start ?? _today;
      final end = _range?.end ?? start;

      final request = AttendanceSubmitRequest(
        jadwalId: widget.jadwalId,
        pesertaId: widget.pesertaId,
        tanggal: formatApiDate(start),
        jamHadir: formatApiTime(now),
        status: widget.type,
        notes: notes,
        tanggalSelesai: end == start ? null : formatApiDate(end),
        attachmentPath: _attachment?.path,
        // Tidak perlu koordinat untuk izin/sakit
      );

      final result = await widget.provider.submitAttendance(request, widget.token);
      if (!mounted) return;

      final skipped = result.skippedDates
          .map((d) => tryParseApiDate(d))
          .whereType<DateTime>()
          .map(formatLongDate)
          .toList();
      setState(() {
        _step = _FormStep.success;
        _successMessage = [
          if (result.items.length > 1)
            result.message ?? '${result.items.length} hari presensi tercatat.',
          if (skipped.isNotEmpty)
            'Dilewati karena sudah tercatat: ${skipped.join(', ')}.',
        ].join('\n');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _FormStep.form;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = AttendanceStatusStyle.of(widget.type);

    return AttendanceSheetFrame(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_step == _FormStep.success)
          _buildSuccess(style)
        else ...[
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: style.bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(style.outlineIcon, color: style.fg, size: 22),
            ),
            const SizedBox(width: 12),
            Text(_isIzin ? 'Formulir Pengajuan Izin' : 'Formulir Keterangan Sakit',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 16),
          if (_step == _FormStep.submitting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildForm(style),
                ),
              ),
            ),
        ],
      ],
    );
  }

  List<Widget> _buildForm(AttendanceStatusStyle style) {
    final rangeLabel = _range == null
        ? 'Hari ini (${formatLongDate(_today)})'
        : formatDateRangeLabel(_range!.start, _range!.end);

    return [
      if (_error != null)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
          child: Text(_error!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
        ),
      const Text('Tanggal',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      OutlinedButton.icon(
        onPressed: _pickRange,
        icon: const Icon(Icons.date_range_rounded, size: 18),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(rangeLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: style.fg,
          side: BorderSide(color: style.fg.withValues(alpha: 0.5)),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          'Rentang maksimal $kMaxRentangHari hari. Akhir pekan dan hari libur dilewati otomatis.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ),
      const SizedBox(height: 14),
      Text(_isIzin ? 'Alasan Izin' : 'Keterangan Sakit',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: _notesController,
        decoration: attendanceNotesDecoration(_isIzin
            ? 'Contoh: Keperluan keluarga, urusan administrasi, dll.'
            : 'Contoh: Demam sejak pagi, sedang berobat ke puskesmas.'),
        maxLines: 3,
        maxLength: kAttendanceNotesMaxLength,
      ),
      const SizedBox(height: 4),
      Text(_isIzin ? 'Lampiran (opsional)' : 'Surat dokter / bukti (opsional)',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      if (_attachment == null)
        OutlinedButton.icon(
          onPressed: _chooseAttachmentSource,
          icon: const Icon(Icons.attach_file_rounded, size: 18),
          label: const Text('Tambah foto lampiran',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            minimumSize: const Size.fromHeight(44),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        )
      else
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_attachment!.path),
                    width: 48, height: 48, fit: BoxFit.cover),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_attachment!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5)),
              ),
              IconButton(
                tooltip: 'Hapus lampiran',
                onPressed: () => setState(() => _attachment = null),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
        ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _doSubmit,
        icon: const Icon(Icons.send_rounded, size: 18),
        label: Text(_isIzin ? 'Ajukan Izin' : 'Laporkan Sakit',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        style: attendancePrimaryButtonStyle(color: style.fg),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
    ];
  }

  Widget _buildSuccess(AttendanceStatusStyle style) {
    final extra = _successMessage;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: style.bg, shape: BoxShape.circle),
          child: Icon(Icons.check_circle_rounded, color: style.fg, size: 48),
        ),
        const SizedBox(height: 14),
        Text(_isIzin ? 'Izin Berhasil Dicatat!' : 'Laporan Sakit Tercatat!',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(
          extra != null && extra.isNotEmpty
              ? extra
              : 'Keterangan kehadiran Anda telah tercatat.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
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
