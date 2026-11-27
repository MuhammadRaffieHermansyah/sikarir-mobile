import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/instructor/data/models/attendance_session_model.dart';
import 'package:sikarir/features/instructor/presentation/widgets/instructor_ui.dart';

/// Lembar rekap satu sesi: ringkasan status dan daftar nama peserta.
class SessionParticipantsSheet extends StatefulWidget {
  final AttendanceSession session;
  final Future<List<SessionParticipant>> Function() load;

  const SessionParticipantsSheet({
    super.key,
    required this.session,
    required this.load,
  });

  @override
  State<SessionParticipantsSheet> createState() =>
      _SessionParticipantsSheetState();
}

class _SessionParticipantsSheetState extends State<SessionParticipantsSheet> {
  late Future<List<SessionParticipant>> _future = widget.load();

  void _retry() {
    final next = widget.load();
    setState(() {
      _future = next;
    });
  }

  static (Color, Color) _colors(String status) => switch (status) {
    'hadir' => (AppColors.mint, AppColors.mintDark),
    'izin' => (AppColors.blueGray, AppColors.blueGrayText),
    'sakit' => (AppColors.peachBg, AppColors.peachText),
    'alpha' => (const Color(0xFFFDECEC), const Color(0xFFB42318)),
    _ => (AppColors.background, AppColors.textSecondary),
  };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scrollController) =>
          FutureBuilder<List<SessionParticipant>>(
            future: _future,
            builder: (context, snapshot) {
              final header = <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Rekap Pertemuan ${widget.session.meetingNumber}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.session.date} • ${widget.session.startTime}–${widget.session.endTime}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
              ];

              Widget body;
              if (snapshot.connectionState != ConnectionState.done) {
                body = const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              } else if (snapshot.hasError) {
                // InstructorMessage bisa digulir sendiri, jadi beri tinggi tetap di dalam ListView.
                body = SizedBox(
                  height: 340,
                  child: InstructorMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'Gagal Memuat Rekap',
                    message: snapshot.error.toString().replaceFirst(
                      'Exception: ',
                      '',
                    ),
                    onRetry: _retry,
                    error: true,
                  ),
                );
              } else {
                final list = snapshot.data ?? const <SessionParticipant>[];
                final count = <String, int>{};
                for (final p in list) {
                  count[p.status] = (count[p.status] ?? 0) + 1;
                }
                body = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in const [
                          'hadir',
                          'izin',
                          'sakit',
                          'alpha',
                          'belum',
                        ])
                          if (s != 'belum' || (count[s] ?? 0) > 0)
                            InstructorChip(
                              label:
                                  '${SessionParticipant(id: '', name: '', status: s).statusLabel} ${count[s] ?? 0}',
                              background: _colors(s).$1,
                              foreground: _colors(s).$2,
                            ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (list.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Belum ada peserta terdaftar di kelas ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    for (final p in list)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (p.checkInTime != null || p.note != null)
                                    Text(
                                      [
                                        if (p.checkInTime != null)
                                          'Pukul ${p.checkInTime}',
                                        if (p.note != null) p.note!,
                                      ].join(' • '),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InstructorChip(
                              label: p.statusLabel,
                              background: _colors(p.status).$1,
                              foreground: _colors(p.status).$2,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }

              return ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).viewPadding.bottom + 24,
                ),
                children: [...header, body],
              );
            },
          ),
    );
  }
}
