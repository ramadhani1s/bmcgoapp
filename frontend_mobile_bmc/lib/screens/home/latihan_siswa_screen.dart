import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/services/siswa_latihan_service.dart';
import 'package:frontend_mobile_bmc/models/soal_model.dart';

class LatihanSiswaScreen extends StatefulWidget {
  final String subject;
  final String materiTitle;

  const LatihanSiswaScreen({
    super.key,
    required this.subject,
    required this.materiTitle,
  });

  @override
  State<LatihanSiswaScreen> createState() => _LatihanSiswaScreenState();
}

class _LatihanSiswaScreenState extends State<LatihanSiswaScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _submitted = false;
  List<SoalLatihan> _soal = [];
  final Map<int, String> _jawabanSiswa = {};
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _loadSoal();
  }

  Future<void> _loadSoal() async {
    setState(() => _isLoading = true);
    
    final soal = await SiswaLatihanService.getSoalBySubject(widget.subject);
    
    if (!mounted) return;
    setState(() {
      _soal = soal.cast<SoalLatihan>();
      _jawabanSiswa.clear();
      _submitted = false;
      _score = 0;
      _isLoading = false;
    });
  }

  void _pilihJawaban(int soalId, String jawaban) {
    if (_submitted) return;
    setState(() {
      _jawabanSiswa[soalId] = jawaban;
    });
  }

  void _submitJawaban() {
    if (_soal.isEmpty) return;

    final belumTerjawab = _soal.where((s) => !_jawabanSiswa.containsKey(s.id)).length;
    if (belumTerjawab > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masih $belumTerjawab soal belum dijawab'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    int benar = 0;
    for (final soal in _soal) {
      final jawabanSiswa = _jawabanSiswa[soal.id] ?? '';
      if (jawabanSiswa.toUpperCase() == soal.jawaban.toUpperCase()) {
        benar++;
      }
    }

    setState(() {
      _score = benar;
      _submitted = true;
      _isSubmitting = false;
    });

    _showHasilDialog();
  }

  void _showHasilDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎯 Hasil Latihan'),
        content: Text(
          'Kamu menjawab $_score dari ${_soal.length} soal dengan benar.\n\n'
          'Skor: ${(_score / _soal.length * 100).toInt()}%',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Latihan ${widget.subject}'),
        backgroundColor: const Color(0xFFFF7070),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _soal.isEmpty
              ? _buildEmptyState()
              : _buildSoalList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.question_mark, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada soal untuk mata pelajaran ini',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subject,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadSoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7070),
            ),
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }

  Widget _buildSoalList() {
    return Column(
      children: [
        // Header info
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.materiTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7070).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_soal.length} Soal',
                  style: const TextStyle(color: Color(0xFFFF7070)),
                ),
              ),
            ],
          ),
        ),
        // List soal
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _soal.length,
            itemBuilder: (context, index) {
              final soal = _soal[index];
              final selected = _jawabanSiswa[soal.id];
              final isCorrect = _submitted && selected == soal.jawaban;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nomor & pertanyaan
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _submitted
                                  ? (isCorrect ? Colors.green : Colors.red)
                                  : const Color(0xFFFF7070),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              soal.pertanyaan,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Pilihan A-D
                      ...['A', 'B', 'C', 'D'].map((option) {
                        final text = _getOptionText(soal, option);
                        final isSelected = selected == option;
                        final isAnswer = _submitted && soal.jawaban == option;
                        
                        Color? bgColor;
                        if (_submitted) {
                          if (isAnswer) bgColor = Colors.green.withOpacity(0.1);
                          else if (isSelected && !isAnswer) bgColor = Colors.red.withOpacity(0.1);
                        } else if (isSelected) {
                          bgColor = const Color(0xFFFF7070).withOpacity(0.1);
                        }

                        return GestureDetector(
                          onTap: _submitted ? null : () => _pilihJawaban(soal.id, option),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgColor ?? Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected && !_submitted
                                    ? const Color(0xFFFF7070)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFF7070)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '$option. $text',
                                    style: TextStyle(
                                      color: _submitted && isAnswer
                                          ? Colors.green
                                          : null,
                                    ),
                                  ),
                                ),
                                if (_submitted && isAnswer)
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              ],
                            ),
                          ),
                        );
                      }),
                      // Pembahasan (jika submitted dan salah)
                      if (_submitted && selected != soal.jawaban && soal.pembahasan.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '💡 Pembahasan:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(soal.pembahasan),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Submit button
        if (!_submitted)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1))],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitJawaban,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7070),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Kumpulkan Jawaban',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  String _getOptionText(SoalLatihan soal, String option) {
    switch (option) {
      case 'A': return soal.pilihanA;
      case 'B': return soal.pilihanB;
      case 'C': return soal.pilihanC;
      case 'D': return soal.pilihanD;
      default: return '';
    }
  }
}