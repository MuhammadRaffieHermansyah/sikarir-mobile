class TrainingScheduleModel {
  final String id;
  final String classId;
  final String className;
  final int sessionNumber;
  final String title;
  final String topic;
  final String date;
  final String startTime;
  final String endTime;
  final String room;
  final String instructor;
  final String type; // 'tatap_muka', 'online'
  final String status; // 'akan_datang', 'berlangsung', 'selesai'
  final String? meetUrl;
  final bool isAttendanceOpen;
  final String? myAttendanceStatus; // 'hadir', 'izin', 'sakit', null

  TrainingScheduleModel({
    required this.id,
    required this.classId,
    required this.className,
    required this.sessionNumber,
    required this.title,
    required this.topic,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.instructor,
    required this.type,
    required this.status,
    this.meetUrl,
    required this.isAttendanceOpen,
    this.myAttendanceStatus,
  });

  factory TrainingScheduleModel.fromMap(Map<String, dynamic> map) {
    return TrainingScheduleModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      classId: (map['kelas_pelatihan_id'] ?? map['class_id'] ?? '1').toString(),
      className: (map['nama_kelas'] ?? map['class_name'] ?? 'Desain Grafis & UI/UX').toString(),
      sessionNumber: (map['sesi_ke'] ?? map['session_number'] ?? 1) as int,
      title: (map['judul_sesi'] ?? map['title'] ?? 'Sesi Pembelajaran').toString(),
      topic: (map['topik'] ?? map['topic'] ?? 'Pembahasan Modul Praktik').toString(),
      date: (map['tanggal'] ?? map['date'] ?? 'Hari Ini').toString(),
      startTime: (map['jam_mulai'] ?? map['start_time'] ?? '08:00').toString(),
      endTime: (map['jam_selesai'] ?? map['end_time'] ?? '15:00').toString(),
      room: (map['ruangan'] ?? map['room'] ?? 'Lab Komputer 02').toString(),
      instructor: (map['instruktur'] ?? map['instructor'] ?? 'Ahmad Fauzi, S.Kom.').toString(),
      type: (map['jenis'] ?? map['type'] ?? 'tatap_muka').toString().toLowerCase(),
      status: (map['status'] ?? 'akan_datang').toString().toLowerCase(),
      meetUrl: map['meet_url']?.toString(),
      isAttendanceOpen: map['absen_dibuka'] ?? map['is_attendance_open'] ?? true,
      myAttendanceStatus: map['status_kehadiran']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kelas_pelatihan_id': classId,
      'nama_kelas': className,
      'sesi_ke': sessionNumber,
      'judul_sesi': title,
      'topik': topic,
      'tanggal': date,
      'jam_mulai': startTime,
      'jam_selesai': endTime,
      'ruangan': room,
      'instruktur': instructor,
      'jenis': type,
      'status': status,
      'meet_url': meetUrl,
      'absen_dibuka': isAttendanceOpen,
      'status_kehadiran': myAttendanceStatus,
    };
  }
}
