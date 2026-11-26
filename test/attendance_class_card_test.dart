import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';
import 'package:sikarir/features/attendance/presentation/widgets/attendance_class_card.dart';
import 'package:sikarir/features/instructor/data/models/attendance_session_model.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';

TrainingClassModel _kelas({String title = 'Pemrograman Web Dasar'}) =>
    TrainingClassModel(
      id: '3',
      pelatihanId: '1',
      jadwalId: '5',
      title: title,
      code: 'BLK-5',
      category: 'TIK',
      instructor: 'Budi Santoso',
      room: 'Lab Komputer 1',
      startDate: '2026-11-01',
      endDate: '2026-12-20',
      totalSessions: 16,
      completedSessions: 4,
      progress: 0.25,
      status: 'berlangsung',
      description: '',
      scheduleStart: '08:00',
      scheduleEnd: '15:00',
    );

const _session = AttendanceSession(
  id: '12',
  classId: '3',
  meetingNumber: 4,
  date: '2026-11-26',
  startTime: '09:00',
  endTime: '11:30',
  radiusMeter: 100,
  isOpen: true,
);

Widget _wrap(Widget child, {double width = 320}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );

void main() {
  testWidgets('menampilkan kelas, pertemuan, dan jam sesi yang dibuka',
      (tester) async {
    await tester.pumpWidget(_wrap(AttendanceClassCard(
      kelas: _kelas(),
      session: _session,
      sessionChecked: true,
      today: null,
      locationLabel: 'Lab Komputer 1',
      radiusMeter: 100,
      actions: const [Text('aksi')],
    )));

    expect(find.text('Pemrograman Web Dasar'), findsOneWidget);
    expect(find.text('Ke-4'), findsOneWidget);
    expect(find.text('09:00 – 11:30'), findsOneWidget);
    expect(find.text('Dibuka'), findsOneWidget);
    expect(find.text('26 November 2026'), findsOneWidget);
    expect(find.text('aksi'), findsOneWidget);
  });

  testWidgets('tanpa sesi memakai jam jadwal dan status belum dibuka',
      (tester) async {
    await tester.pumpWidget(_wrap(AttendanceClassCard(
      kelas: _kelas(),
      session: null,
      sessionChecked: true,
      today: null,
      locationLabel: 'Lab Komputer 1',
      radiusMeter: 100,
    )));

    expect(find.text('Belum Dibuka'), findsOneWidget);
    expect(find.text('Jam Pelatihan'), findsOneWidget);
    expect(find.text('08:00 – 15:00'), findsOneWidget);
    expect(find.text('-'), findsOneWidget); // pertemuan
  });

  testWidgets('menampilkan catatan hadir hari ini tanpa overflow di layar sempit',
      (tester) async {
    await tester.pumpWidget(_wrap(
      AttendanceClassCard(
        kelas: _kelas(
            title: 'Pelatihan Teknisi Jaringan Komputer dan Administrasi '
                'Server Tingkat Lanjut Berbasis Kompetensi Industri'),
        session: _session,
        sessionChecked: true,
        today: AttendanceItem(
          id: '1',
          userId: '9',
          classId: '5',
          className: 'x',
          date: '2026-11-26',
          clockInTime: '09:05:00',
          status: 'hadir',
        ),
        locationLabel: 'Gedung Workshop Otomotif dan Elektronika Lantai 2',
        radiusMeter: 100,
      ),
      width: 280,
    ));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Masuk'), findsOneWidget);
  });
}
