import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_sheet_common.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_status_style.dart';
import 'package:sikarir/features/attendance/utils/attendance_formatters.dart';

enum _FormStep { form, submitting, success }

/// Bottom sheet: pengajuan izin / laporan sakit untuk hari ini.
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
  _FormStep _step = _FormStep.form;
  String? _error;

  bool get _isIzin => widget.type == 'izin';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
      final request = AttendanceSubmitRequest(
        jadwalId: widget.jadwalId,
        pesertaId: widget.pesertaId,
        tanggal: formatApiDate(now),
        jamHadir: formatApiTime(now),
        status: widget.type,
        notes: notes,
        // Tidak perlu koordinat untuk izin/sakit
      );

      await widget.provider.submitAttendance(request, widget.token);
      if (!mounted) return;
      setState(() => _step = _FormStep.success);
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
            ..._buildForm(style),
        ],
      ],
    );
  }

  List<Widget> _buildForm(AttendanceStatusStyle style) {
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
      const SizedBox(height: 12),
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
        const Text('Keterangan kehadiran Anda telah tercatat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
