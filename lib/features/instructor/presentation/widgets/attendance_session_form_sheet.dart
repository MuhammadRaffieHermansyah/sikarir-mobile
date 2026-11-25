import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/attendance/data/services/location_service.dart';
import 'package:sikarir/features/instructor/data/models/attendance_session_model.dart';
import 'package:sikarir/features/instructor/presentation/widgets/instructor_ui.dart';

Future<AttendanceSessionInput?> showAttendanceSessionFormSheet(
  BuildContext context, {
  required int meetingCount,
  required int initialMeeting,
  double? defaultLatitude,
  double? defaultLongitude,
  int? defaultRadius,
}) {
  return showModalBottomSheet<AttendanceSessionInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SessionForm(
      meetingCount: meetingCount,
      initialMeeting: initialMeeting,
      latitude: defaultLatitude,
      longitude: defaultLongitude,
      radius: defaultRadius,
    ),
  );
}

class _SessionForm extends StatefulWidget {
  final int meetingCount;
  final int initialMeeting;
  final double? latitude;
  final double? longitude;
  final int? radius;

  const _SessionForm({
    required this.meetingCount,
    required this.initialMeeting,
    this.latitude,
    this.longitude,
    this.radius,
  });

  @override
  State<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<_SessionForm> {
  final _formKey = GlobalKey<FormState>();
  late int _meeting = widget.initialMeeting.clamp(1, widget.meetingCount);
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 15, minute: 0);
  late final _radius = TextEditingController(
    text: '${widget.radius ?? LocationService.defaultRadius}',
  );
  late double? _lat = widget.latitude;
  late double? _lng = widget.longitude;
  bool _locating = false;
  String? _error;

  @override
  void dispose() {
    _radius.dispose();
    super.dispose();
  }

  String _two(int v) => v.toString().padLeft(2, '0');
  String _fmtTime(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';
  String _fmtDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked == null) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } on LocationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final startMin = _start.hour * 60 + _start.minute;
    final endMin = _end.hour * 60 + _end.minute;
    if (endMin <= startMin) {
      setState(() => _error = 'Jam selesai harus setelah jam mulai');
      return;
    }
    Navigator.pop(
      context,
      AttendanceSessionInput(
        meetingNumber: _meeting,
        date: _fmtDate(_date),
        startTime: _fmtTime(_start),
        endTime: _fmtTime(_end),
        latitude: _lat,
        longitude: _lng,
        radiusMeter: int.parse(_radius.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _lat != null && _lng != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InstructorSheetHeader(
                title: 'Buat Sesi Presensi',
                subtitle: 'Atur jadwal dan lokasi presensi peserta',
                icon: Icons.how_to_reg_rounded,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: _meeting,
                decoration: _dec('Pertemuan', icon: Icons.event_note_rounded),
                items: [
                  for (var i = 1; i <= widget.meetingCount; i++)
                    DropdownMenuItem(value: i, child: Text('Pertemuan $i')),
                ],
                onChanged: (v) => setState(() => _meeting = v ?? _meeting),
              ),
              const SizedBox(height: 12),
              _pickerTile(
                Icons.event_rounded,
                'Tanggal',
                _fmtDate(_date),
                _pickDate,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _pickerTile(
                      Icons.schedule_rounded,
                      'Mulai',
                      _fmtTime(_start),
                      () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _pickerTile(
                      Icons.schedule_rounded,
                      'Selesai',
                      _fmtTime(_end),
                      () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _radius,
                decoration: _dec(
                  'Radius presensi (meter)',
                  icon: Icons.radar_rounded,
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return (n == null || n < 10 || n > 5000)
                      ? 'Isi radius 10–5000 meter'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mintBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 18,
                          color: AppColors.mintDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hasLocation
                                ? 'Lokasi: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                                : 'Lokasi: memakai titik default kelas/BLK',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.mintDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _locating ? null : _useMyLocation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _locating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 18),
                      label: const Text('Pakai lokasi saya saat ini'),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
                ),
              const SizedBox(height: 18),
              InstructorPrimaryButton(
                label: 'Buat Sesi',
                icon: Icons.add_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerTile(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label, {IconData? icon}) =>
      instructorInputDecoration(label, icon: icon);
}
