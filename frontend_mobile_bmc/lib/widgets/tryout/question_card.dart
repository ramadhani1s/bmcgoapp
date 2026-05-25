import 'package:flutter/material.dart';

class QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final String? selected;
  final void Function(String) onSelect;
  const QuestionCard({super.key, required this.question, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final opts = (question['options'] as List<dynamic>? ?? []).cast<String>();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Soal ${question['nomor'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(question['pertanyaan'] ?? ''),
          const SizedBox(height: 12),
          ...opts.map((o) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: GestureDetector(
                  onTap: () => onSelect(o),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected == o ? const Color(0xFFFFECEC) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFECECEC)),
                    ),
                    child: Row(children: [Text(o), const SizedBox(width: 12), Expanded(child: Text('Pilihan $o'))]),
                  ),
                ),
              ))
        ],
      ),
    );
  }
}
