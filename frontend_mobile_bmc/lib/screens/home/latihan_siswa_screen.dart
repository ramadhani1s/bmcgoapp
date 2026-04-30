import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/models/mentor_latihan_model.dart';
import 'package:frontend_mobile_bmc/models/soal_model.dart';
import 'package:frontend_mobile_bmc/services/mentor_latihan_service.dart';
import 'package:frontend_mobile_bmc/services/soal_service.dart';

class LatihanSiswaScreen extends StatefulWidget {
  const LatihanSiswaScreen({super.key});

  @override
  State<LatihanSiswaScreen> createState() => _LatihanSiswaScreenState();
}

class _LatihanSiswaScreenState extends State<LatihanSiswaScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFD1D5DB);
  static const Color _accent = Color(0xFF2563EB);

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _submitted = false;
  MentorLatihanModel? _selectedLatihan;
  List<SoalModel> _questions = const [];
  final Map<String, String> _answers = {};
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _loadPractice();
  }

  Future<void> _loadPractice() async {
    setState(() => _isLoading = true);

    final latihanList = await MentorLatihanService.getAll();
    final published = latihanList.where((item) => item.isPublished).toList();
    final selectedLatihan = published.isNotEmpty
        ? published.first
        : (latihanList.isNotEmpty ? latihanList.first : null);

    if (selectedLatihan == null) {
      if (!mounted) return;
      setState(() {
        _selectedLatihan = null;
        _questions = const [];
        _isLoading = false;
      });
      return;
    }

    final allQuestions = await SoalService.getByLatihanId(selectedLatihan.id);
    final questions = allQuestions.take(5).toList();

    if (!mounted) return;
    setState(() {
      _selectedLatihan = selectedLatihan;
      _questions = questions;
      _answers.clear();
      _submitted = false;
      _score = 0;
      _isLoading = false;
    });
  }

  void _selectAnswer(String questionId, String answerKey) {
    if (_submitted) return;
    setState(() {
      _answers[questionId] = answerKey;
    });
  }

  Future<void> _submitAnswers() async {
    if (_questions.isEmpty) return;

    final missing = _questions
        .where((question) => !_answers.containsKey(question.id))
        .toList();
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua jawaban dulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    var score = 0;
    for (final question in _questions) {
      final selected = _answers[question.id]?.toUpperCase();
      if (selected == question.kunciJawaban.toUpperCase()) {
        score += 1;
      }
    }

    if (!mounted) return;
    setState(() {
      _score = score;
      _submitted = true;
      _isSubmitting = false;
    });

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hasil Latihan'),
        content: Text('Kamu benar $_score dari ${_questions.length} soal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Latihan 5 Soal'),
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedLatihan == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Belum ada latihan tersedia',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Mentor belum mengaktifkan latihan soal untuk siswa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _textMuted),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadPractice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Muat Ulang'),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedLatihan!.judul,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kerjakan 5 soal pertama setelah belajar materi',
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _infoChip(
                                icon: Icons.school_outlined,
                                text: _selectedLatihan!.mapel,
                              ),
                              _infoChip(
                                icon: Icons.class_outlined,
                                text: _selectedLatihan!.kelas,
                              ),
                              _infoChip(
                                icon: Icons.timer_outlined,
                                text: '${_selectedLatihan!.durasiMenit} menit',
                              ),
                              _infoChip(
                                icon: Icons.quiz_outlined,
                                text: '${_questions.length} soal',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      itemCount: _questions.length + 1,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == _questions.length) {
                          return _buildSubmitCard();
                        }

                        final question = _questions[index];
                        return _buildQuestionCard(index + 1, question);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int number, SoalModel question) {
    final options = question.pilihan.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Soal Latihan',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.pertanyaan,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          for (final option in options) ...[
            _optionTile(question.id, option.key, option.value),
            const SizedBox(height: 8),
          ],
          if (_submitted) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Text(
                _answers[question.id]?.toUpperCase() ==
                        question.kunciJawaban.toUpperCase()
                    ? 'Benar'
                    : 'Salah, jawaban benar: ${question.kunciJawaban}',
                style: const TextStyle(
                  color: Color(0xFF166534),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _optionTile(String questionId, String key, String value) {
    final selected = _answers[questionId]?.toUpperCase() == key;
    final submittedCorrect = _submitted && selected;

    return InkWell(
      onTap: () => _selectAnswer(questionId, key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _accent : _border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _accent : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                key,
                style: TextStyle(
                  color: selected ? Colors.white : _textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ),
            if (submittedCorrect)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF16A34A),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _submitted ? 'Hasil Latihan' : 'Selesaikan Latihan',
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _submitted
                ? 'Skor kamu: $_score dari ${_questions.length}'
                : 'Pastikan semua soal sudah dijawab sebelum dikirim.',
            style: const TextStyle(color: _textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitted || _isSubmitting ? null : _submitAnswers,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_submitted ? 'Sudah Dikirim' : 'Kirim Jawaban'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _loadPractice,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _border),
              foregroundColor: _textPrimary,
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Ulangi Latihan'),
          ),
        ],
      ),
    );
  }
}
