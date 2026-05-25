import 'package:flutter/material.dart';

class MateriCard extends StatelessWidget {
  const MateriCard({
    super.key,
    required this.materi,
    required this.onTap,
    required this.getSubjectConfig,
    required this.textPrimary,
    required this.textMuted,
  });

  final Map<String, dynamic> materi;
  final VoidCallback onTap;
  final Map<String, dynamic> Function(String) getSubjectConfig;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    final subject = materi['subject'] as String? ?? 'Umum';
    final config = getSubjectConfig(subject);
    final mentorName = materi['mentor_name'] as String? ?? 'Mentor';
    final fileSize = materi['file_size'] as int? ?? 0;
    final fileType = (materi['file_type'] as String? ?? '.pdf').toUpperCase().replaceAll('.', '');

    String formatFileSize(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: config['bg'] as Color, borderRadius: BorderRadius.circular(14)),
              child: Icon(config['icon'] as IconData, color: config['color'] as Color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materi['title'] as String? ?? '-',
                    style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text('Kak $mentorName · ${formatFileSize(fileSize)}', style: TextStyle(color: textMuted, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: config['bg'] as Color, borderRadius: BorderRadius.circular(6)),
                        child: Text(subject, style: TextStyle(color: config['color'] as Color, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.picture_as_pdf_rounded, size: 13, color: Color(0xFF8D90A3)),
                      const SizedBox(width: 3),
                      Text(fileType, style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFD0D0D0)),
          ],
        ),
      ),
    );
  }
}
