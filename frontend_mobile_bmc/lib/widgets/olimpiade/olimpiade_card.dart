import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OlimpiadeCard extends StatelessWidget {
  const OlimpiadeCard({
    super.key,
    required this.olimpiade,
    required this.onTap,
    required this.goldColor,
    required this.textPrimary,
    required this.textMuted,
  });

  final Map<String, dynamic> olimpiade;
  final VoidCallback onTap;
  final Color goldColor;
  final Color textPrimary;
  final Color textMuted;

  Widget _statusBadge(String status) {
    Color color;
    Color bg;
    String label;
    IconData icon;

    switch (status) {
      case 'tersedia':
        color = const Color(0xFF12B892);
        bg = const Color(0xFFE3FBF4);
        label = 'Sedang Berlangsung';
        icon = Icons.circle;
        break;
      case 'selesai':
        color = const Color(0xFF8D90A3);
        bg = const Color(0xFFF0F0F0);
        label = 'Selesai';
        icon = Icons.check_circle_rounded;
        break;
      default:
        color = const Color(0xFF8D90A3);
        bg = const Color(0xFFF0F0F0);
        label = status;
        icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString.toString());
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = olimpiade['status'] as String? ?? 'tersedia';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: goldColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.white.withAlpha((0.25 * 255).round()), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        olimpiade['nama'] as String? ?? '-',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        olimpiade['class_level'] as String? ?? '-',
                        style: const TextStyle(color: Color(0xFFFFE5B0), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusBadge(status),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF8D90A3)),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(olimpiade['tanggal']),
                      style: TextStyle(color: textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_rounded, size: 14, color: Color(0xFF8D90A3)),
                    const SizedBox(width: 6),
                    Text(
                      '${olimpiade['durasi'] ?? 120} menit • ${olimpiade['total_questions'] ?? 0} soal',
                      style: TextStyle(color: textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
                if ((olimpiade['lokasi'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Lokasi: ${olimpiade['lokasi']}',
                    style: TextStyle(color: textPrimary, fontSize: 13, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onTap,
                  child: Row(
                    children: [
                      Text(
                        status == 'tersedia' ? 'Mulai Olimpiade' : 'Lihat Hasil',
                        style: const TextStyle(color: Color(0xFFFF7070), fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFFF7070), size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

