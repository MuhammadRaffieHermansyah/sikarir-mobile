class ApiConstants {
  ApiConstants._();

  static const String ipConfig = '192.168.0.7';

  static const String baseUrl = 'http://$ipConfig:8000/api';

  /// Base URL untuk file storage (gambar, dokumen, dll.)
  static const String storageUrl = 'http://$ipConfig:8000/storage';

  /// Helper: jika [path] sudah URL lengkap, kembalikan apa adanya (menyesuaikan host jika localhost).
  /// Jika path relatif (dari DB), prefix dengan storageUrl dan bersihkan slash/storage duplikat.
  static String fullImageUrl(String path) {
    if (path.isEmpty) return '';

    String cleaned = path.trim();

    // Normalisasi localhost/127.0.0.1 ke host ipConfig jika URL dibangkitkan dari backend Laravel
    if (cleaned.contains('localhost:8000')) {
      cleaned = cleaned.replaceAll('localhost:8000', '$ipConfig:8000');
    } else if (cleaned.contains('127.0.0.1:8000')) {
      cleaned = cleaned.replaceAll('127.0.0.1:8000', '$ipConfig:8000');
    }

    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }

    if (cleaned.startsWith('/')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.startsWith('storage/')) {
      cleaned = cleaned.substring(8);
    }

    return '$storageUrl/$cleaned';
  }

  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String me = '$baseUrl/auth/me';

  static const String pesertaMe = '$baseUrl/pesertas/me';
  static const String pesertas = '$baseUrl/pesertas';
  static const String absen = '$baseUrl/absen';
  static const String lowongan = '$baseUrl/lowongan';
  static const String pelatihan = '$baseUrl/pelatihan';
  static const String sertifikasi = '$baseUrl/sertifikat';
  static const String sertifikatMe = '$baseUrl/sertifikat/me';
  static const String mitra = '$baseUrl/mitras';
  static const String jadwalPelatihan = '$baseUrl/jadwal-pelatihan';
  static const String kelasPelatihan = '$baseUrl/kelas-pelatihan';
  static const String kelasPelatihanMe = '$baseUrl/kelas-pelatihan/me';
}
