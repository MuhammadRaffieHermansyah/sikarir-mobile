import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Titik presensi (lokasi pelatihan) beserta radius yang diizinkan.
class AttendanceTarget {
  final double latitude;
  final double longitude;
  final int radiusMeter;
  final String label;

  const AttendanceTarget({
    required this.latitude,
    required this.longitude,
    required this.radiusMeter,
    required this.label,
  });

  /// Lokasi default BLK Jember (dipakai bila jadwal belum punya koordinat).
  static const defaultTarget = AttendanceTarget(
    latitude: LocationService.defaultLat,
    longitude: LocationService.defaultLng,
    radiusMeter: LocationService.defaultRadius,
    label: LocationService.defaultLokasiLabel,
  );

  /// Gunakan koordinat/radius jadwal bila tersedia, selain itu fallback default.
  factory AttendanceTarget.fromSchedule({
    double? latitude,
    double? longitude,
    int? radiusMeter,
    String? label,
  }) {
    final hasCoords = latitude != null && longitude != null;
    return AttendanceTarget(
      latitude: hasCoords ? latitude : LocationService.defaultLat,
      longitude: hasCoords ? longitude : LocationService.defaultLng,
      radiusMeter: (radiusMeter != null && radiusMeter > 0)
          ? radiusMeter
          : LocationService.defaultRadius,
      label: (label != null && label.trim().isNotEmpty)
          ? label
          : LocationService.defaultLokasiLabel,
    );
  }
}

/// Service untuk menangani GPS dan validasi lokasi presensi.
class LocationService {
  /// Koordinat lokasi BLK Jember (default jika jadwal belum dikonfigurasi)
  static const double defaultLat = -8.15753;
  static const double defaultLng = 113.7229492;
  static const int defaultRadius = 100; // meter
  static const String defaultLokasiLabel = 'BLK Jember, Jl. Basuki Rahmat No. 203';

  /// Akurasi GPS terburuk yang diterima (meter). Di atas ini, posisi dianggap
  /// tidak cukup andal untuk memvalidasi radius.
  static const double maxAccuracyMeter = 75;

  /// Minta izin lokasi dan kembalikan [Position] saat ini.
  /// Throw [LocationException] jika izin ditolak, layanan nonaktif, timeout,
  /// lokasi palsu (mock), atau akurasi terlalu rendah.
  static Future<Position> getCurrentPosition() async {
    // Periksa apakah layanan lokasi aktif
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Layanan GPS tidak aktif. Aktifkan GPS di pengaturan perangkat.',
        LocationExceptionType.serviceDisabled,
      );
    }

    // Periksa izin
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Izin lokasi ditolak. Berikan izin lokasi untuk dapat melakukan presensi.',
          LocationExceptionType.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Izin lokasi ditolak secara permanen. Buka pengaturan aplikasi untuk mengaktifkan izin lokasi.',
        LocationExceptionType.permissionDeniedForever,
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      throw const LocationException(
        'Gagal mendapatkan sinyal GPS tepat waktu. Pindah ke area terbuka lalu coba lagi.',
        LocationExceptionType.timeout,
      );
    }

    if (position.isMocked) {
      throw const LocationException(
        'Terdeteksi penggunaan lokasi palsu (mock location). Nonaktifkan aplikasi lokasi palsu untuk melakukan presensi.',
        LocationExceptionType.mockLocation,
      );
    }

    if (position.accuracy > maxAccuracyMeter) {
      throw LocationException(
        'Akurasi GPS terlalu rendah (±${position.accuracy.toStringAsFixed(0)} m). '
        'Pindah ke area terbuka lalu coba lagi.',
        LocationExceptionType.lowAccuracy,
      );
    }

    return position;
  }

  /// Buka pengaturan aplikasi (untuk izin yang ditolak permanen).
  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Buka pengaturan layanan lokasi/GPS perangkat.
  static Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Hitung jarak (meter) antara dua titik GPS menggunakan rumus Haversine.
  static double hitungJarak({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const double earthRadius = 6371000; // meter
    final double dLat = _toRad(lat2 - lat1);
    final double dLng = _toRad(lng2 - lng1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Cek apakah posisi saat ini dalam radius lokasi pelatihan.
  static LocationCheckResult cekLokasiValid({
    required Position position,
    double targetLat = defaultLat,
    double targetLng = defaultLng,
    int radiusMeter = defaultRadius,
  }) {
    final double jarak = hitungJarak(
      lat1: position.latitude,
      lng1: position.longitude,
      lat2: targetLat,
      lng2: targetLng,
    );

    return LocationCheckResult(
      jarakMeter: jarak,
      radiusMeter: radiusMeter,
      isValid: jarak <= radiusMeter,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeter: position.accuracy,
    );
  }

  /// Versi praktis: validasi terhadap [AttendanceTarget].
  static LocationCheckResult cekTerhadapTarget(
    Position position,
    AttendanceTarget target,
  ) =>
      cekLokasiValid(
        position: position,
        targetLat: target.latitude,
        targetLng: target.longitude,
        radiusMeter: target.radiusMeter,
      );

  static double _toRad(double deg) => deg * pi / 180;
}

class LocationCheckResult {
  final double jarakMeter;
  final int radiusMeter;
  final bool isValid;
  final double latitude;
  final double longitude;
  final double? accuracyMeter;

  const LocationCheckResult({
    required this.jarakMeter,
    required this.radiusMeter,
    required this.isValid,
    required this.latitude,
    required this.longitude,
    this.accuracyMeter,
  });

  String get jarakLabel {
    if (jarakMeter < 1000) {
      return '${jarakMeter.toStringAsFixed(0)} m';
    }
    return '${(jarakMeter / 1000).toStringAsFixed(1)} km';
  }
}

enum LocationExceptionType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  mockLocation,
  lowAccuracy,
  unknown,
}

class LocationException implements Exception {
  final String message;
  final LocationExceptionType type;

  const LocationException(this.message, this.type);

  @override
  String toString() => message;
}
