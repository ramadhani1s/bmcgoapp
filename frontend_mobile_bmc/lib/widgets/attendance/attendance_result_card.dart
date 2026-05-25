import 'package:flutter/material.dart';
import 'attendance_card_shell.dart';
import 'attendance_status_chip.dart';

class AttendanceResultCard extends StatelessWidget {
  const AttendanceResultCard({
    super.key,
    required this.status,
    required this.className,
    required this.subject,
    required this.submittedAt,
  });

  final String status;
  final String className;
  final String subject;
  final String submittedAt;

  @override
  Widget build(BuildContext context) {
    return AttendanceCardShell(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Absensi Terakhir',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          AttendanceStatusChip(status: status),
          const SizedBox(height: 8),
          Text('Kelas: $className'),
          Text('Mapel: $subject'),
          Text('Waktu Input: $submittedAt'),
        ],
      ),
    );
  }
}