import 'package:flutter/material.dart';
import 'attendance_status_chip.dart';
import 'attendance_card_shell.dart';

class AttendanceHistoryItem extends StatelessWidget {
  const AttendanceHistoryItem({
    super.key,
    required this.className,
    required this.subject,
    required this.submittedAt,
    required this.status,
  });

  final String className;
  final String subject;
  final String submittedAt;
  final String status;

  @override
  Widget build(BuildContext context) {
    return AttendanceCardShell(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('Mapel: $subject'),
                Text('Input: $submittedAt'),
              ],
            ),
          ),
          AttendanceStatusChip(status: status),
        ],
      ),
    );
  }
}