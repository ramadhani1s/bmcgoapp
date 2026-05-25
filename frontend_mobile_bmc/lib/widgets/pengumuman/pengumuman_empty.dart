import 'package:flutter/material.dart';

class PengumumanEmpty extends StatelessWidget {
  const PengumumanEmpty({super.key, required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: const Color(0xFFFFE8E8), borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.campaign_rounded, color: accentColor, size: 36),
          ),
          const SizedBox(height: 14),
          const Text('Belum ada pengumuman', style: TextStyle(color: Color(0xFF25273D), fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Admin belum membuat pengumuman apapun.', style: TextStyle(color: Color(0xFF8D90A3), fontSize: 13)),
        ],
      ),
    );
  }
}
