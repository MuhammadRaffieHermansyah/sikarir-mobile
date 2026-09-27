class PartnerModel {
  final String id;
  final String name;
  final String industry;
  final String logo;
  final String location;
  final String description;
  final int activeVacancies;
  final String partnershipType; // 'Penyalur Kerja', 'Tempat Magang OJT', 'Penguji Asesmen'
  final String website;

  PartnerModel({
    required this.id,
    required this.name,
    required this.industry,
    required this.logo,
    required this.location,
    required this.description,
    required this.activeVacancies,
    required this.partnershipType,
    required this.website,
  });

  factory PartnerModel.fromMap(Map<String, dynamic> map) {
    return PartnerModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      name: (map['nama_mitra'] ?? map['nama'] ?? map['name'] ?? 'Mitra Industri BLK').toString(),
      industry: (map['sektor'] ?? map['bidang'] ?? map['industry'] ?? 'Teknologi & Manufaktur').toString(),
      logo: (map['logo'] ?? map['logo_url'] ?? 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=100&auto=format&fit=crop&q=80').toString(),
      location: (map['lokasi'] ?? map['alamat'] ?? map['location'] ?? 'Indonesia').toString(),
      description: (map['deskripsi'] ?? map['description'] ?? 'Mitra industri resmi balai latihan kerja.').toString(),
      activeVacancies: (map['lowongan_aktif'] ?? map['active_vacancies'] ?? 2) as int,
      partnershipType: (map['jenis_kemitraan'] ?? map['type'] ?? 'Penyalur Kerja & OJT').toString(),
      website: (map['website'] ?? 'https://kemnaker.go.id').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_mitra': name,
      'sektor': industry,
      'logo': logo,
      'lokasi': location,
      'deskripsi': description,
      'lowongan_aktif': activeVacancies,
      'jenis_kemitraan': partnershipType,
      'website': website,
    };
  }
}
