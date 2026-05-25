import 'package:flutter/material.dart';

class PengumumanCard extends StatelessWidget {
  const PengumumanCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.getKategoriConfig,
    required this.textPrimary,
    required this.textMuted,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final Map<String, dynamic> Function(String) getKategoriConfig;
  final Color textPrimary;
  final Color textMuted;

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kategori = item['kategori'] as String? ?? 'Umum';
    final config = getKategoriConfig(kategori);
    final createdAt = item['created_at'] as String? ?? '';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: config['bg'] as Color, borderRadius: BorderRadius.circular(14)),
              child: Icon(config['icon'] as IconData, color: config['color'] as Color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['judul'] as String? ?? '-', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(item['isi'] as String? ?? '-', style: TextStyle(color: textMuted, fontSize: 12.5, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(_formatDate(createdAt), style: TextStyle(color: textMuted, fontSize: 11.5)),
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
