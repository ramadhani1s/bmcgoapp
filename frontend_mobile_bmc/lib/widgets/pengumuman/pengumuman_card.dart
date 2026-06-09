import 'package:flutter/material.dart';

class PengumumanCard extends StatelessWidget {
  const PengumumanCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.textPrimary,
    required this.textMuted,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final Color textPrimary;
  final Color textMuted;

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}  •  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return rawDate;
    }
  }

  String _getDay(String rawDate) {
    try {
      return DateTime.parse(rawDate).toLocal().day.toString();
    } catch (_) {
      return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = item['created_at'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon kalender dengan angka tanggal
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7070),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 10),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _getDay(createdAt),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF7070),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['judul'] as String? ?? '-',
                    style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['isi'] as String? ?? '-',
                    style: TextStyle(color: textMuted, fontSize: 12.5, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(_formatDate(createdAt), style: TextStyle(color: textMuted, fontSize: 11.5)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7070),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 18),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFD0D0D0), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}