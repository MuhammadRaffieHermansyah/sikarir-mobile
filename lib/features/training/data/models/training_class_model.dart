class TrainingClassModel {
  final String id;
  final String pelatihanId;
  final String title;
  final String code;
  final String category;
  final String instructor;
  final String room;
  final String startDate;
  final String endDate;
  final int totalSessions;
  final int completedSessions;
  final double progress; // 0.0 to 1.0
  final String status; // 'berlangsung', 'akan_datang', 'selesai'
  final String description;
  final List<ClassMaterial> materials;

  TrainingClassModel({
    required this.id,
    required this.pelatihanId,
    required this.title,
    required this.code,
    required this.category,
    required this.instructor,
    required this.room,
    required this.startDate,
    required this.endDate,
    required this.totalSessions,
    required this.completedSessions,
    required this.progress,
    required this.status,
    required this.description,
    this.materials = const [],
  });

  factory TrainingClassModel.fromMap(Map<String, dynamic> map) {
    final rawMaterials = map['materi'] ?? map['materials'] ?? [];
    final List<ClassMaterial> materialList = (rawMaterials is List)
        ? rawMaterials.map((m) => ClassMaterial.fromMap(m as Map<String, dynamic>)).toList()
        : [];

    final completed = (map['sesi_selesai'] ?? map['completed_sessions'] ?? 0) as num;
    final total = (map['total_sesi'] ?? map['total_sessions'] ?? 16) as num;
    final calcProgress = total > 0 ? (completed / total).toDouble().clamp(0.0, 1.0) : 0.0;

    return TrainingClassModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      pelatihanId: (map['pelatihan_id'] ?? '').toString(),
      title: (map['nama_kelas'] ?? map['nama'] ?? map['title'] ?? 'Kelas Pelatihan').toString(),
      code: (map['kode_kelas'] ?? map['code'] ?? 'BLK-2026-01').toString(),
      category: (map['kategori'] ?? map['kejuruan'] ?? 'Teknologi Informasi').toString(),
      instructor: (map['instruktur'] ?? map['pengajar'] ?? 'Instruktur BLK').toString(),
      room: (map['ruangan'] ?? map['room'] ?? 'Lab 01').toString(),
      startDate: (map['tanggal_mulai'] ?? map['start_date'] ?? '01 September 2026').toString(),
      endDate: (map['tanggal_selesai'] ?? map['end_date'] ?? '30 Oktober 2026').toString(),
      totalSessions: total.toInt(),
      completedSessions: completed.toInt(),
      progress: (map['progress'] != null) ? (map['progress'] as num).toDouble() : calcProgress,
      status: (map['status'] ?? 'berlangsung').toString().toLowerCase(),
      description: (map['deskripsi'] ?? map['description'] ?? 'Pelatihan berbasis kompetensi industri berstandar SKKNI & BNSP.').toString(),
      materials: materialList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pelatihan_id': pelatihanId,
      'nama_kelas': title,
      'kode_kelas': code,
      'kategori': category,
      'instruktur': instructor,
      'ruangan': room,
      'tanggal_mulai': startDate,
      'tanggal_selesai': endDate,
      'total_sesi': totalSessions,
      'sesi_selesai': completedSessions,
      'progress': progress,
      'status': status,
      'deskripsi': description,
    };
  }
}

class ClassMaterial {
  final String id;
  final String title;
  final String type; // 'pdf', 'video', 'slide', 'assignment'
  final String duration;
  final String fileUrl;
  final bool isCompleted;

  ClassMaterial({
    required this.id,
    required this.title,
    required this.type,
    required this.duration,
    required this.fileUrl,
    required this.isCompleted,
  });

  factory ClassMaterial.fromMap(Map<String, dynamic> map) {
    return ClassMaterial(
      id: (map['id'] ?? '').toString(),
      title: (map['judul'] ?? map['title'] ?? 'Materi Pembelajaran').toString(),
      type: (map['tipe'] ?? map['type'] ?? 'pdf').toString(),
      duration: (map['durasi'] ?? map['duration'] ?? '45 Menit').toString(),
      fileUrl: (map['file_url'] ?? map['url'] ?? '').toString(),
      isCompleted: map['sudah_selesai'] ?? map['is_completed'] ?? false,
    );
  }
}
