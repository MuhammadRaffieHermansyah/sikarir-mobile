import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/core/storage/utils/file_url.dart';

class PesertaProfile {
  final String idPeserta;
  final String idUser;
  final String nomorPeserta;
  final String? nama;
  final String jenisKelamin;
  final String? nomorKk;
  final String? nomorWa;
  final String? tanggalLahir;
  final String? tempatLahir;
  final String? alamatLengkap;
  final String? pendidikanTerakhir;
  final String? pendidikanSekarang;
  final String? statusPendidikan; // sudah_lulus | masih_menempuh
  final String? jurusan;
  final String? pasFoto;          // URL foto dari server
  final bool isDisabilitas;
  final String? jenisDisabilitas;
  final bool isProfileComplete;

  PesertaProfile({
    required this.idPeserta,
    required this.idUser,
    required this.nomorPeserta,
    required this.jenisKelamin,
    this.nama,
    this.nomorKk,
    this.nomorWa,
    this.tanggalLahir,
    this.tempatLahir,
    this.alamatLengkap,
    this.pendidikanTerakhir,
    this.pendidikanSekarang,
    this.statusPendidikan,
    this.jurusan,
    this.pasFoto,
    this.isDisabilitas = false,
    this.jenisDisabilitas,
    this.isProfileComplete = false,
  });

  factory PesertaProfile.fromMap(Map<String, dynamic> map) {
    final data = map['data'] is Map<String, dynamic> ? map['data'] : map;
    return PesertaProfile(
      idPeserta: (data['id_peserta'] ?? data['id'] ?? '').toString(),
      idUser: (data['id_user'] ?? data['user_id'] ?? '').toString(),
      nomorPeserta: (data['nomor_peserta'] ?? '').toString(),
      nama: data['nama']?.toString() ??
          data['name']?.toString() ??
          (data['user'] is Map ? data['user']['name']?.toString() : null),
      jenisKelamin: (data['jenis_kelamin'] ?? 'Laki-laki').toString(),
      nomorKk: data['nomor_kk']?.toString(),
      nomorWa: data['nomor_wa']?.toString(),
      tanggalLahir: data['tanggal_lahir']?.toString(),
      tempatLahir: data['tempat_lahir']?.toString(),
      alamatLengkap: data['alamat_lengkap']?.toString(),
      pendidikanTerakhir: data['pendidikan_terakhir']?.toString(),
      pendidikanSekarang: data['pendidikan_sekarang']?.toString(),
      statusPendidikan: data['status_pendidikan']?.toString(),
      jurusan: data['jurusan']?.toString(),
      pasFoto: data['pas_foto'] != null && data['pas_foto'].toString().isNotEmpty
          ? ApiConstants.fullImageUrl(data['pas_foto'].toString())
          : null,
      isDisabilitas: data['is_disabilitas'] == true ||
          data['is_disabilitas'].toString() == '1',
      jenisDisabilitas: data['jenis_disabilitas']?.toString(),
      isProfileComplete: data['is_profile_complete'] == true ||
          (data['nomor_wa'] != null &&
              data['nomor_wa'].toString().isNotEmpty &&
              data['nomor_kk'] != null &&
              data['nomor_kk'].toString().isNotEmpty &&
              data['alamat_lengkap'] != null &&
              data['alamat_lengkap'].toString().isNotEmpty &&
              data['pendidikan_terakhir'] != null &&
              data['pendidikan_terakhir'].toString().isNotEmpty),
    );
  }
    String? get pasFotoUrl => FileUrl.resolve(pasFoto);
  Map<String, dynamic> toMap() {
    return {
      if (nama != null) 'nama': nama,
      if (nama != null) 'name': nama,
      'jenis_kelamin': jenisKelamin,
      'nomor_kk': nomorKk,
      'nomor_wa': nomorWa,
      'tanggal_lahir': tanggalLahir,
      'tempat_lahir': tempatLahir,
      'alamat_lengkap': alamatLengkap,
      'pendidikan_terakhir': pendidikanTerakhir,
      if (pendidikanSekarang != null) 'pendidikan_sekarang': pendidikanSekarang,
      if (statusPendidikan != null) 'status_pendidikan': statusPendidikan,
      if (jurusan != null) 'jurusan': jurusan,
      'is_disabilitas': isDisabilitas,
      if (jenisDisabilitas != null) 'jenis_disabilitas': jenisDisabilitas,
    };
  }
}
