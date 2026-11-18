import 'package:sikarir/core/constants/api_constants.dart';

/// Mengubah path/URL file dari server (mis. pas_foto) jadi URL
/// yang bisa dibuka HP. Alamat server diambil dari ApiConstants.baseUrl.
class FileUrl {
  FileUrl._();

  static String? resolve(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty || value == 'null') return null;

    final base = Uri.parse(ApiConstants.baseUrl);
    final origin = '${base.scheme}://${base.host}:${base.port}';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        return uri.replace(host: base.host, port: base.port).toString();
      }
      return value;
    }

    final path = value.startsWith('/') ? value.substring(1) : value;
    if (path.startsWith('storage/')) return '$origin/$path';
    return '$origin/storage/$path';
  }
}