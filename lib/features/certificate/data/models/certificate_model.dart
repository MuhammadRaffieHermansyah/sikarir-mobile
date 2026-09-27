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
    return CertificateModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      title: (map['nama_sertifikat'] ?? map['judul'] ?? map['title'] ?? 'Sertifikat Kompetensi').toString(),
      issuer: (map['penerbit'] ?? map['lembaga'] ?? map['issuer'] ?? 'BNSP / BLK').toString(),
      issueDate: (map['tanggal_terbit'] ?? map['issue_date'] ?? '2026').toString(),
      validUntil: (map['masa_berlaku'] ?? map['valid_until'] ?? 'Seumur Hidup').toString(),
      certificateNumber: (map['nomor_sertifikat'] ?? map['code'] ?? map['no_reg'] ?? 'REG-BNSP-001').toString(),
      status: (map['status'] ?? 'aktif').toString().toLowerCase(),
      fileUrl: (map['file_url'] ?? map['download_url'] ?? '').toString(),
      category: (map['kejuruan'] ?? map['category'] ?? 'TIK & Desain').toString(),
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
