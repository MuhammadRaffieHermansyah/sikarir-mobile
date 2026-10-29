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

    return CertificateModel(
      id: (map['id_sertifikat'] ?? map['id'] ?? map['_id'] ?? '').toString(),
      title: (pelatihan?['nama_pelatihan'] ?? map['nama_sertifikat'] ?? map['judul'] ?? map['title'] ?? 'Sertifikat Kompetensi').toString(),
      issuer: (map['penerbit'] ?? map['lembaga'] ?? map['issuer'] ?? 'Badan Nasional Sertifikasi Profesi (BNSP)').toString(),
      issueDate: (map['tanggal_terbit'] ?? map['issue_date'] ?? '2026').toString(),
      validUntil: (map['masa_berlaku'] ?? map['valid_until'] ?? 'Seumur Hidup').toString(),
      certificateNumber: (map['no_sertifikat'] ?? map['nomor_sertifikat'] ?? map['code'] ?? 'REG-BNSP-001').toString(),
      status: (map['status'] ?? 'aktif').toString().toLowerCase(),
      fileUrl: (map['file_url'] ?? map['download_url'] ?? '').toString(),
      category: (pelatihan?['kategori'] ?? map['kejuruan'] ?? map['category'] ?? 'Pelatihan Kejuruan').toString(),
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
