import 'package:flutter/material.dart';

class AttendanceStatusChip extends StatelessWidget {
  const AttendanceStatusChip({super.key, required this.status});

  final String status;

  Color _statusColor(String value) {
    switch (value) {
      case 'hadir':
        return const Color(0xFF16A34A);
      case 'terlambat':
        return const Color(0xFFE67E22);
      case 'tidak_hadir':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.14 * 255).round()),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}