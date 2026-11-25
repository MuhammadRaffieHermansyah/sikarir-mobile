import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/attendance/data/services/location_service.dart';
import 'package:sikarir/features/instructor/data/models/attendance_session_model.dart';

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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buat Sesi Presensi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _meeting,
                decoration: _dec('Pertemuan'),
                items: [
                  for (var i = 1; i <= widget.meetingCount; i++)
                    DropdownMenuItem(value: i, child: Text('Pertemuan $i')),
                ],
                onChanged: (v) => setState(() => _meeting = v ?? _meeting),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_rounded),
                label: Text('Tanggal: ${_fmtDate(_date)}'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(true),
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text('Mulai ${_fmtTime(_start)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(false),
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text('Selesai ${_fmtTime(_end)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _radius,
                decoration: _dec('Radius presensi (meter)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return (n == null || n < 10 || n > 5000)
                      ? 'Isi radius 10–5000 meter'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                hasLocation
                    ? 'Lokasi: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                    : 'Lokasi: memakai titik default kelas/BLK',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _locating ? null : _useMyLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: const Text('Pakai lokasi saya saat ini'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Buat Sesi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
