import 'package:sikarir/core/constants/api_constants.dart';

/// Jenis materi yang bisa ditambahkan instruktur.
enum MaterialKind {
  file('file', 'File'),
  link('link', 'Link'),
  text('teks', 'Catatan');

  final String apiValue;
  final String label;
  const MaterialKind(this.apiValue, this.label);

  static MaterialKind fromApi(dynamic raw) {
    final v = (raw ?? '').toString().toLowerCase();
    return MaterialKind.values.firstWhere(
      (k) => k.apiValue == v || k.name == v,
      orElse: () => MaterialKind.file,
    );
  }
}

/// Satu materi di dalam modul (file / link / catatan teks).
class ModuleMaterial {
  final String id;
  final String moduleId;
  final String title;
  final MaterialKind kind;

  /// URL file (sudah dinormalisasi) atau link eksternal. Kosong untuk catatan teks.
  final String url;

  /// Isi catatan untuk materi bertipe teks.
  final String content;
  final String fileName;

  const ModuleMaterial({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.kind,
    this.url = '',
    this.content = '',
    this.fileName = '',
  });

  factory ModuleMaterial.fromMap(Map<String, dynamic> map) {
    final kind = MaterialKind.fromApi(map['tipe'] ?? map['type']);
    final rawUrl = (map['url'] ?? map['file_url'] ?? map['file'] ?? '')
        .toString();
    return ModuleMaterial(
      id: (map['id_materi'] ?? map['id'] ?? '').toString(),
      moduleId: (map['id_modul'] ?? map['modul_id'] ?? '').toString(),
      title: (map['judul'] ?? map['title'] ?? 'Materi').toString(),
      kind: kind,
      url: kind == MaterialKind.file
          ? ApiConstants.fullImageUrl(rawUrl)
          : rawUrl,
      content: (map['konten'] ?? map['content'] ?? '').toString(),
      fileName: (map['nama_file'] ?? '').toString(),
    );
  }
}

/// Modul untuk satu pertemuan pada sebuah kelas.
class ClassModule {
  final String id;
  final String classId;
  final String title;
  final String description;
  final int meetingNumber;
  final List<ModuleMaterial> materials;

  const ClassModule({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.meetingNumber,
    this.materials = const [],
  });

  factory ClassModule.fromMap(Map<String, dynamic> map) {
    final raw = map['materi'] ?? map['materials'] ?? const [];
    return ClassModule(
      id: (map['id_modul'] ?? map['id'] ?? '').toString(),
      classId: (map['id_kelas'] ?? map['kelas_id'] ?? '').toString(),
      title: (map['judul'] ?? map['title'] ?? 'Modul').toString(),
      description: (map['deskripsi'] ?? map['description'] ?? '').toString(),
      meetingNumber:
          int.tryParse(
            (map['pertemuan_ke'] ?? map['pertemuan'] ?? 1).toString(),
          ) ??
          1,
      materials: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (m) => ModuleMaterial.fromMap(Map<String, dynamic>.from(m)),
                )
                .toList()
          : const [],
    );
  }
}
