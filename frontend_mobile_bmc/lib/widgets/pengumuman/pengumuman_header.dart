import 'package:flutter/material.dart';

class PengumumanHeader extends StatelessWidget {
  const PengumumanHeader({super.key, required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.22 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pengumuman', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Informasi resmi dari BMC', style: TextStyle(color: Color(0xFFFFE5E5), fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 48),
        ],
      ),
    );
  }
}
