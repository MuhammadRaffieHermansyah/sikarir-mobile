import 'package:sikarir/core/constants/api_constants.dart';

class CertificateModel {
  final String id;
  final String title;
  final String issuer;
  final String issueDate;
  final String validUntil;
  final String certificateNumber;
  final String status; // 'aktif', 'proses', 'kadaluarsa'
  final String fileUrl;
  final String category;

  CertificateModel({
    required this.id,
    required this.title,
    required this.issuer,
    required this.issueDate,
    required this.validUntil,
    required this.certificateNumber,
    required this.status,
    required this.fileUrl,
    required this.category,
  });

  factory CertificateModel.fromMap(Map<String, dynamic> map) {
    final jadwal = map['jadwal'] as Map<String, dynamic>?;
    final pelatihan = jadwal?['pelatihan'] as Map<String, dynamic>?;
    final admin = map['admin'] as Map<String, dynamic>?;
    final adminUser = admin?['user'] as Map<String, dynamic>?;

    // Issuer name
    String issuerName = (map['penerbit'] ?? map['lembaga'] ?? map['issuer'] ?? '').toString();
    if (issuerName.isEmpty) {
      if (admin?['nama_admin'] != null && admin!['nama_admin'].toString().isNotEmpty) {
        issuerName = 'Balai Latihan Kerja (BLK) - ${admin['nama_admin']}';
      } else if (adminUser?['name'] != null && adminUser!['name'].toString().isNotEmpty) {
        issuerName = 'Balai Latihan Kerja (BLK) - ${adminUser['name']}';
      } else {
        issuerName = 'Balai Latihan Kerja (BLK) & BNSP';
      }
    }

    // Judul sertifikat
    final certTitle = (pelatihan?['nama_pelatihan'] ??
            map['nama_sertifikat'] ??
            map['judul'] ??
            map['title'] ??
            'Sertifikat Kompetensi Kerja')
        .toString();

    // Tanggal terbit
    final issueDate = (map['tanggal_terbit'] ?? map['issue_date'] ?? '-').toString();

    // Masa berlaku
    final validUntil = (map['masa_berlaku'] ?? map['valid_until'] ?? 'Seumur Hidup').toString();

    // Nomor sertifikat
    final certNum = (map['no_sertifikat'] ??
            map['nomor_sertifikat'] ??
            map['code'] ??
            'SRT-${map['id_sertifikat'] ?? '001'}')
        .toString();

    // File URL (PDF Sertifikat)
    final rawFile = (map['file_url'] ?? map['file_sertifikat'] ?? map['download_url'] ?? '').toString();
    final fileUrl = rawFile.isNotEmpty ? ApiConstants.fullImageUrl(rawFile) : '';

    // Status sertifikat
    final certStatus = (map['status'] ?? 'aktif').toString().toLowerCase();

    // Kategori kejuruan
    final cat = (pelatihan?['kategori'] ??
            pelatihan?['kejuruan'] ??
            map['kejuruan'] ??
            map['category'] ??
            'Pelatihan Vokasi & Sertifikasi')
        .toString();

    return CertificateModel(
      id: (map['id_sertifikat'] ?? map['id'] ?? map['_id'] ?? '').toString(),
      title: certTitle,
      issuer: issuerName,
      issueDate: issueDate,
      validUntil: validUntil,
      certificateNumber: certNum,
      status: certStatus,
      fileUrl: fileUrl,
      category: cat,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_sertifikat': title,
      'penerbit': issuer,
      'tanggal_terbit': issueDate,
      'masa_berlaku': validUntil,
      'nomor_sertifikat': certificateNumber,
      'status': status,
      'file_url': fileUrl,
      'kejuruan': category,
    };
  }
}
