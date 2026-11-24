/// Formatter tanggal/waktu untuk fitur presensi (tanpa dependensi `intl`).
library;

const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

String _two(int n) => n.toString().padLeft(2, '0');

/// 24 November 2026
String formatLongDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Selasa, 24 November 2026
String formatDayDate(DateTime d) => '${_days[d.weekday - 1]}, ${formatLongDate(d)}';

/// November 2026
String formatMonthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

/// 08:05 atau 08:05:09
String formatClock(DateTime d, {bool withSeconds = false}) =>
    withSeconds
        ? '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}'
        : '${_two(d.hour)}:${_two(d.minute)}';

/// 2026-11-24 (format `tanggal` yang dipakai API)
String formatApiDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// 08:05 (format `jam_hadir` yang dipakai API)
String formatApiTime(DateTime d) => formatClock(d);

/// Parse tanggal API ('2026-11-24' atau ISO '2026-11-24T00:00:00.000000Z').
/// Mengembalikan `null` bila tidak dapat dibaca.
DateTime? tryParseApiDate(String raw) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw.trim());
  if (match == null) return null;
  final y = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  final d = int.parse(match.group(3)!);
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}

/// '08:05:00' → '08:05'; teks yang bukan jam dikembalikan apa adanya.
String formatApiTimeLabel(String raw) {
  final match = RegExp(r'^(\d{2}):(\d{2})').firstMatch(raw.trim());
  return match == null ? raw : '${match.group(1)}:${match.group(2)}';
}

/// 24 Nov – 26 Nov 2026 (atau satu tanggal bila awal = akhir).
String formatDateRangeLabel(DateTime start, DateTime end) {
  if (start == end) return formatLongDate(start);
  return '${formatLongDate(start)} – ${formatLongDate(end)}';
}

/// Label tanggal untuk tampilan; bila tak terbaca, kembalikan teks aslinya.
String formatApiDateLabel(String raw) {
  final d = tryParseApiDate(raw);
  return d == null ? raw : formatDayDate(d);
}
