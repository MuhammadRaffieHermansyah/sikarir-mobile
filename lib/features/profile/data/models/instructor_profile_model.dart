import 'package:sikarir/core/storage/utils/file_url.dart';

/// Profil instruktur dari `GET/POST /instruktur/me`.
class InstructorProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String expertise;
  final String? photo;

  const InstructorProfile({
    this.id = '',
    this.name = '',
    this.email = '',
    this.phone = '',
    this.bio = '',
    this.expertise = '',
    this.photo,
  });

  String? get photoUrl => FileUrl.resolve(photo);

  /// Keahlian sebagai daftar (dipisah koma).
  List<String> get expertiseList => expertise
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  factory InstructorProfile.fromMap(Map<String, dynamic> map) {
    final data = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    final user = data['user'] is Map ? data['user'] as Map : const {};
    String s(dynamic v) => v == null ? '' : v.toString();

    return InstructorProfile(
      id: s(data['id_instruktur'] ?? data['id']),
      name: s(data['nama'] ?? data['name'] ?? user['name']),
      email: s(data['email'] ?? user['email']),
      phone: s(data['nomor_wa']),
      bio: s(data['bio']),
      expertise: s(data['keahlian']),
      photo: data['foto'] == null || data['foto'].toString().isEmpty
          ? null
          : data['foto'].toString(),
    );
  }
}
