import 'package:flutter/material.dart';

class OlimpiadeEmpty extends StatelessWidget {
  const OlimpiadeEmpty({super.key, required this.accentColor});

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
            child: Icon(Icons.emoji_events_rounded, color: accentColor, size: 36),
          ),
          const SizedBox(height: 14),
          const Text('Belum ada olimpiade', style: TextStyle(color: Color(0xFF25273D), fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Olimpiade akan muncul di sini.', style: TextStyle(color: Color(0xFF8D90A3), fontSize: 13)),
        ],
      ),
    );
  }
}
