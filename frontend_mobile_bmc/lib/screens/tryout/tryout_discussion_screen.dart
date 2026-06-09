import 'package:flutter/material.dart';

class TryOutDiscussionScreen extends StatelessWidget {
  final String kategori;
  final List<Map<String, dynamic>> questions;

  const TryOutDiscussionScreen({super.key, required this.kategori, required this.questions});

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFFFF7070);
    const Color bg = Color(0xFFF7EEEF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(kategori, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: accent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
      ),
      body: questions.isEmpty
          ? const Center(child: Text('Tidak ada soal untuk kategori ini.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final q = questions[index];
                final qNum = index + 1;
                final correct = (q['jawaban'] as String? ?? '').trim().toUpperCase();

                final options = {
                  'A': q['pilihan_a'] as String? ?? '',
                  'B': q['pilihan_b'] as String? ?? '',
                  'C': q['pilihan_c'] as String? ?? '',
                  'D': q['pilihan_d'] as String? ?? '',
                  'E': q['pilihan_e'] as String? ?? '',
                };

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Soal Nomor $qNum', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(q['pertanyaan'] ?? '', style: const TextStyle(fontSize: 15, height: 1.5)),
                      const SizedBox(height: 16),
                      ...options.entries.where((e) => e.value.isNotEmpty).map((entry) {
                        final isCorrect = entry.key == correct;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isCorrect ? const Color(0xFFE8F5E9) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isCorrect ? const Color(0xFF4CAF50) : Colors.grey.shade300, width: isCorrect ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF0F0F0),
                                child: Text(entry.key, style: TextStyle(color: isCorrect ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 14))),
                              if (isCorrect) const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 20),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      const Text('Pembahasan Umum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          (q['pembahasan'] as String? ?? '').isNotEmpty ? q['pembahasan']! : 'Pembahasan tidak tersedia.',
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

