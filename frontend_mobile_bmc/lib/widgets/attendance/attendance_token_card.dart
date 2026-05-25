import 'package:flutter/material.dart';
import 'attendance_card_shell.dart';

class AttendanceTokenCard extends StatelessWidget {
  const AttendanceTokenCard({
    super.key,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AttendanceCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Input Token Absensi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Masukkan token yang diberikan mentor. 0-15 menit: hadir, >15-30 menit: terlambat, >30 menit: tidak hadir.',
            style: TextStyle(color: Color(0xFF64748B), height: 1.45),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Contoh: AB12CD',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: const Icon(Icons.how_to_reg_outlined),
              label: Text(isSubmitting ? 'Mengirim...' : 'Kirim Token'),
            ),
          ),
        ],
      ),
    );
  }
}