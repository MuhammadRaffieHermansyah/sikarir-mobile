import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';

/// Batas panjang `keterangan` sesuai validasi backend (`max:255`).
const int kAttendanceNotesMaxLength = 255;

/// Rangka bottom sheet: sudut atas membulat, handle, dan padding keyboard.
class AttendanceSheetFrame extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  const AttendanceSheetFrame({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Dekorasi input keterangan yang dipakai kedua sheet.
InputDecoration attendanceNotesDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
    filled: true,
    fillColor: const Color(0xFFF7FAF8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

/// Tombol utama bulat berwarna (aksi sheet).
ButtonStyle attendancePrimaryButtonStyle({
  Color color = AppColors.primary,
  double height = 50,
  double radius = 14,
}) {
  return ElevatedButton.styleFrom(
    backgroundColor: color,
    foregroundColor: Colors.white,
    minimumSize: Size.fromHeight(height),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
  );
}
