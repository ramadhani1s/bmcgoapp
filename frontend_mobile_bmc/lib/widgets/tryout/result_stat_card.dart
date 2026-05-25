import 'package:flutter/material.dart';

class ResultStatCard extends StatelessWidget {
  final String title;
  final String value;
  const ResultStatCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
