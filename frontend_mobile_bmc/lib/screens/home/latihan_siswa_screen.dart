import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/models/mentor_latihan_model.dart';
import 'package:frontend_mobile_bmc/models/soal_model.dart';
import 'package:frontend_mobile_bmc/services/mentor_latihan_service.dart';
import 'package:frontend_mobile_bmc/services/soal_service.dart';
import 'package:frontend_mobile_bmc/widgets/latihan/practice_overview_card.dart';
import 'package:frontend_mobile_bmc/widgets/latihan/question_card.dart';
import 'package:frontend_mobile_bmc/widgets/latihan/submit_card.dart';

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
                  PracticeOverviewCard(
                    latihan: _selectedLatihan!,
                    questionCount: _questions.length,
                    accentColor: _accent,
                    borderColor: _border,
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      itemCount: _questions.length + 1,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == _questions.length) {
                          return SubmitCard(
                            submitted: _submitted,
                            isSubmitting: _isSubmitting,
                            score: _score,
                            questionsLength: _questions.length,
                            onSubmit: _submitAnswers,
                            onRetry: _loadPractice,
                            accentColor: _accent,
                            borderColor: _border,
                          );
                        }

                        final question = _questions[index];
                        return QuestionCard(
                          number: index + 1,
                          question: question,
                          selectedAnswer: _answers[question.id],
                          submitted: _submitted,
                          onSelectAnswer: _selectAnswer,
                          accentColor: _accent,
                          borderColor: _border,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // _infoChip removed; moved to widget in practice_overview_card when needed.

}
