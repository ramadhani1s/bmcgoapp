import 'package:flutter/material.dart';
import '../../widgets/tryout/result_stat_card.dart';
import 'tryout_discussion_screen.dart';

class _MateriBar extends StatelessWidget {
  final String name;
  final double pct;
  const _MateriBar({required this.name, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(height: 10, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6))),
            FractionallySizedBox(widthFactor: pct.clamp(0.0, 1.0), child: Container(height: 10, decoration: BoxDecoration(color: const Color(0xFFFF7070), borderRadius: BorderRadius.circular(6))))
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class TryOutResultDashboard extends StatelessWidget {
  final Map<String, dynamic> result;
  final List<Map<String, dynamic>> questions;
  final Map<int, String> answers;
  const TryOutResultDashboard({super.key, required this.result, required this.questions, required this.answers});

  @override
  Widget build(BuildContext context) {
    final score = result['score'] ?? 0;
    final total = result['total'] ?? 0;
    final correct = result['correct'] ?? 0;
    final accuracy = result['accuracy'] ?? 0;
    final Map<String, dynamic> byMateri = (result['by_materi'] is Map) ? Map<String, dynamic>.from(result['by_materi']) : {};

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Try Out'), backgroundColor: const Color(0xFFFF7070)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResultStatCard(title: 'Skor', value: '$score'),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: ResultStatCard(title: 'Benar', value: '$correct')) , const SizedBox(width:8), Expanded(child: ResultStatCard(title: 'Total', value: '$total'))]),
            const SizedBox(height: 12),
            Text('Akurasi: ${accuracy.toStringAsFixed(1)}%'),
            const SizedBox(height: 18),
            const Text('Analisis per Sub-materi', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (byMateri.isEmpty) const Text('Analisis tidak tersedia dari server, menggunakan komputasi lokal.'),
            if (byMateri.isEmpty) const SizedBox(height: 8),
            if (byMateri.isNotEmpty)
              ...byMateri.entries.map((e) {
                final name = e.key;
                final val = e.value is num ? (e.value as num).toDouble() : 0.0;
                return _MateriBar(name: name, pct: val / 100.0);
              }),
            if (byMateri.isEmpty)
              // compute quick local breakdown
              ..._computeLocalByMateri().entries.map((e) => _MateriBar(name: e.key, pct: e.value)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TryOutDiscussionScreen(questions: questions, answers: answers))), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7070)), child: const Text('Lihat Pembahasan'))
          ],
        ),
      ),
    );
  }

  Map<String, double> _computeLocalByMateri() {
    final Map<String, List<bool>> accum = {};
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final materi = (q['materi'] ?? 'Umum').toString();
      final correct = (q['jawaban'] ?? q['answer']).toString();
      final user = answers[i];
      final ok = user != null && user == correct;
      accum.putIfAbsent(materi, () => []).add(ok);
    }
    final Map<String, double> out = {};
    accum.forEach((k, v) {
      final pct = v.isEmpty ? 0.0 : (v.where((e) => e).length / v.length);
      out[k] = pct;
    });
    return out;
  }
}
