import 'package:flutter/material.dart';
import '../../services/tryout_service.dart';
import 'tryout_discussion_screen.dart';

class TryOutResultDashboard extends StatefulWidget {
  final Map<String, dynamic> package;
  final Map<String, dynamic> result;
  
  const TryOutResultDashboard({
    super.key, 
    required this.package, 
    required this.result,
  });

  @override
  State<TryOutResultDashboard> createState() => _TryOutResultDashboardState();
}

class _TryOutResultDashboardState extends State<TryOutResultDashboard> {
  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFF7EEEF);

  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    final id = widget.package['id'] as int;
    // Gunakan endpoint pembahasan agar jawaban & pembahasan tersedia di layar hasil
    final list = await TryOutService.getQuestionsWithPembahasan(id);
    if (!mounted) return;
    setState(() {
      _questions = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If the result came from immediate exam completion, it will have 'skor', 'jawaban_benar', etc.
    // If it came from the list screen (history), it might only have 'nilai'.
    final score = widget.result['skor'] ?? widget.result['nilai'] ?? widget.package['nilai'] ?? 0;
    final totalSoal = widget.result['total_soal'] ?? widget.package['total_questions'] ?? _questions.length;
    final benar = widget.result['jawaban_benar'] ?? 0;
    final salah = widget.result['jawaban_salah'] ?? 0;
    final kosong = widget.result['tidak_dijawab'] ?? 0;
    final durasi = widget.package['durasi'] ?? 150;

    // Group questions by category
    final Map<String, List<Map<String, dynamic>>> byKategori = {};
    for (var q in _questions) {
      final k = (q['kategori'] as String? ?? '').trim();
      final cat = k.isEmpty ? 'Umum' : k;
      byKategori.putIfAbsent(cat, () => []).add(q);
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : Column(
                children: [
                  _buildHeader(score, durasi, totalSoal),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildStatCard('$benar', 'Terjawab Benar', const Color(0xFFE3FBF4), const Color(0xFF12B892))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatCard('$salah', 'Terjawab Salah', const Color(0xFFFFEFEF), const Color(0xFFFF4D4F))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatCard('$kosong', 'Tidak Terjawab', const Color(0xFFF0F0F0), Colors.grey.shade600)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Detail Pembahasan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ...byKategori.entries.map((e) => _buildKategoriCard(e.key, e.value)),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Kembali ke Daftar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(int score, int durasi, int totalSoal) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text('Hasil Try Out', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 36), // Balance the back button
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
            child: Text('$score', style: const TextStyle(color: _accent, fontSize: 40, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('Waktu Pengerjaan $durasi Menit', style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_outlined, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('Total Soal $totalSoal', style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String val, String lbl, Color bg, Color txt) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(val, style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 4),
          Text(lbl, textAlign: TextAlign.center, style: TextStyle(color: txt, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildKategoriCard(String nama, List<Map<String, dynamic>> qs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.library_books_rounded, color: _accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('${qs.length} Soal', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TryOutDiscussionScreen(kategori: nama, questions: qs)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32),
                    elevation: 0,
                  ),
                  child: const Text('Lihat Pembahasan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

