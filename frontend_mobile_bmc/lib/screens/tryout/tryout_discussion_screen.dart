import 'package:flutter/material.dart';

class TryOutDiscussionScreen extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final Map<int, String> answers;
  const TryOutDiscussionScreen({super.key, required this.questions, required this.answers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembahasan'), backgroundColor: const Color(0xFFFF7070)),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (c, i) {
          final q = questions[i];
          final user = answers[i];
          final correct = q['jawaban'] ?? q['answer'];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Soal ${q['nomor'] ?? i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(q['pertanyaan'] ?? ''),
                const SizedBox(height: 8),
                Text('Jawaban Anda: ${user ?? '-'}'),
                Text('Kunci: ${correct ?? '-'}'),
                const SizedBox(height: 8),
                Text('Pembahasan: ${q['pembahasan'] ?? 'Tidak tersedia'}')
              ],
            ),
          );
        },
      ),
    );
  }
}
