class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.10.5.218:8000/api';

  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String me = '$baseUrl/auth/me';

  static const String absen = '$baseUrl/absen';
  static const String lowongan = '$baseUrl/lowongan';
  static const String pelatihan = '$baseUrl/pelatihan';
  static const String sertifikasi = '$baseUrl/sertifikasi';
  static const String mitra = '$baseUrl/mitra';
  static const String jadwalPelatihan = '$baseUrl/jadwal-pelatihan';
  static const String kelasPelatihan = '$baseUrl/kelas-pelatihan';

}
