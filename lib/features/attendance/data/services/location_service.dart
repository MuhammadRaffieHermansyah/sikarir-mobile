import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Service untuk menangani GPS dan validasi lokasi presensi.
class LocationService {
  /// Koordinat lokasi BLK Jember (default jika jadwal belum dikonfigurasi)
  static const double defaultLat = -8.1763;
  static const double defaultLng = 113.7007;
  static const int defaultRadius = 100; // meter
  static const String defaultLokasiLabel = 'BLK Jember, Jl. Basuki Rahmat No. 203';

  /// Minta izin lokasi dan kembalikan [Position] saat ini.
  /// Throw [LocationException] jika izin ditolak atau layanan nonaktif.
  static Future<Position> getCurrentPosition() async {
    // Periksa apakah layanan lokasi aktif
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Layanan GPS tidak aktif. Aktifkan GPS di pengaturan perangkat.',
        LocationExceptionType.serviceDisabled,
      );
    }

    // Periksa izin
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Izin lokasi ditolak. Berikan izin lokasi untuk dapat melakukan presensi.',
          LocationExceptionType.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Izin lokasi ditolak secara permanen. Buka pengaturan aplikasi untuk mengaktifkan izin lokasi.',
        LocationExceptionType.permissionDeniedForever,
      );
    }

    // Ambil posisi saat ini
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

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
    );
  }

  static double _toRad(double deg) => deg * pi / 180;
}

class LocationCheckResult {
  final double jarakMeter;
  final int radiusMeter;
  final bool isValid;
  final double latitude;
  final double longitude;

  const LocationCheckResult({
    required this.jarakMeter,
    required this.radiusMeter,
    required this.isValid,
    required this.latitude,
    required this.longitude,
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
  unknown,
}

class LocationException implements Exception {
  final String message;
  final LocationExceptionType type;

  const LocationException(this.message, this.type);

  @override
  String toString() => message;
}

