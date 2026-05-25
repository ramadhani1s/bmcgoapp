import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/models/mentor_latihan_model.dart';

class PracticeOverviewCard extends StatelessWidget {
  const PracticeOverviewCard({
    super.key,
    required this.latihan,
    required this.questionCount,
    required this.accentColor,
    required this.borderColor,
  });

  final MentorLatihanModel latihan;
  final int questionCount;
  final Color accentColor;
  final Color borderColor;

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              latihan.judul,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kerjakan 5 soal pertama setelah belajar materi',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(Icons.school_outlined, latihan.mapel),
                _infoChip(Icons.class_outlined, latihan.kelas),
                _infoChip(Icons.timer_outlined, '${latihan.durasiMenit} menit'),
                _infoChip(Icons.quiz_outlined, '$questionCount soal'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
