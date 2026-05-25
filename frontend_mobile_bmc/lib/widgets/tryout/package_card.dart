import 'package:flutter/material.dart';

class PackageCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onStart;
  const PackageCard({super.key, required this.data, this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['judul'] ?? '-'), const SizedBox(height:6), Text('${data['jumlah_soal'] ?? 150} soal', style: const TextStyle(fontSize:12))])),
          ElevatedButton(onPressed: onStart, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7070)), child: const Text('Mulai'))
        ],
      ),
    );
  }
}
