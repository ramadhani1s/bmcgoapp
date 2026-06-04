import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_mobile_bmc/config/api_config.dart';
import '../../widgets/latihan/soal_card.dart';
import '../../widgets/latihan/navigation_button_row.dart';

import '../../core/session/app_session.dart';

class LatihanDariMateriScreen extends StatefulWidget {
  final String materiTitle;
  final int materiId;
  final List<Map<String, dynamic>> questions;

  const LatihanDariMateriScreen({
    super.key,
    required this.materiTitle,
    required this.materiId,
    required this.questions,
  });

  @override
  State<LatihanDariMateriScreen> createState() => _LatihanDariMateriScreenState();
}

class _LatihanDariMateriScreenState extends State<LatihanDariMateriScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  int _currentIndex = 0;
  Map<int, String> _answers = {};
  int _score = 0;
  bool _showPembahasan = true;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.questions);
  }

  Future<String?> _getToken() async {
    try {
      return await AppSession.getAuthToken();
    } catch (_) {
      return null;
    }
  }
  void _selectAnswer(String answer) {
    if (_isSubmitted || _answers.containsKey(_currentIndex)) return;
    setState(() {
      _answers[_currentIndex] = answer;
      _showPembahasan = true;
    });
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showPembahasan = _answers.containsKey(_currentIndex);
      });
    }
  }

  void _goToNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _showPembahasan = _answers.containsKey(_currentIndex);
      });
    }
  }

  Future<void> _submitQuiz() async {
    // Cek apakah semua soal sudah dijawab
    final unansweredCount = _questions.length - _answers.length;
    if (unansweredCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masih ada $unansweredCount soal yang belum dijawab!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Hitung skor
    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      final selected = _answers[i]?.toUpperCase();
      final correct = (_questions[i]['jawaban'] as String).toUpperCase();
      if (selected == correct) {
        correctCount++;
      }
    }

    // Simpan hasil ke API (opsional)
    try {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/api/siswa/latihan/simpan-hasil');
        await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'materi_id': widget.materiId,
            'latihan_title': widget.materiTitle,
            'skor': correctCount,
            'total_soal': _questions.length,
          }),
        ).timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      // Abaikan error simpan hasil, yang penting skor sudah dihitung
      debugPrint('Gagal simpan hasil: $e');
    }

    if (!mounted) return;
    setState(() {
      _score = correctCount;
      _isSubmitted = true;
      _isSubmitting = false;
    });
  }

  void _resetQuiz() {
    setState(() {
      _currentIndex = 0;
      _answers.clear();
      _isSubmitted = false;
      _score = 0;
      _showPembahasan = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _buildResultScreen();
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Soal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Soal latihan untuk materi ini\nbelum tersedia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final selectedAnswer = _answers[_currentIndex];
    
    // Buat list options dari pilihan_a, pilihan_b, dll
    final List<String> options = [
      currentQuestion['pilihan_a']?.toString() ?? '',
      currentQuestion['pilihan_b']?.toString() ?? '',
      currentQuestion['pilihan_c']?.toString() ?? '',
      currentQuestion['pilihan_d']?.toString() ?? '',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: SoalCard(
                currentSoal: _currentIndex + 1,
                totalSoal: _questions.length,
                soalText: currentQuestion['pertanyaan'] ?? '',
                options: options,
                selectedAnswer: selectedAnswer,
                isSubmitted: selectedAnswer != null,
                correctAnswer: currentQuestion['jawaban'],
                pembahasan: currentQuestion['pembahasan'] ?? 'Tidak ada pembahasan',
                onAnswerSelected: _selectAnswer,
                onTogglePembahasan: () {
                  setState(() {
                    _showPembahasan = !_showPembahasan;
                  });
                },
                showPembahasan: _showPembahasan,
              ),
            ),
          ),
          // Bottom Navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: NavigationButtonRow(
              onPrevious: _goToPrevious,
              onNext: _goToNext,
              isPreviousEnabled: _currentIndex > 0,
              isNextEnabled: _currentIndex < _questions.length - 1,
              isLastQuestion: _currentIndex == _questions.length - 1,
              isSubmitting: _isSubmitting,
              onSubmit: _submitQuiz,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final int total = _questions.length;
    final int correct = _score;
    final int wrong = total - correct;
    final int finalScore = total > 0 ? (correct / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F5),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '💪',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Skor Kamu',
                    style: TextStyle(
                      color: Color(0xFF8D90A3),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$finalScore',
                    style: const TextStyle(
                      color: Color(0xFF25273D),
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$correct dari $total jawaban benar',
                    style: const TextStyle(
                      color: Color(0xFF8D90A3),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        count: correct,
                        label: 'Benar',
                        color: const Color(0xFF12B892),
                        bgColor: const Color(0xFFE3FBF4),
                      ),
                      _buildStatCard(
                        count: wrong,
                        label: 'Salah',
                        color: const Color(0xFFFF6B35),
                        bgColor: const Color(0xFFFFF0EB),
                      ),
                      _buildStatCard(
                        count: total,
                        label: 'Total',
                        color: const Color(0xFF4B9BFF),
                        bgColor: const Color(0xFFEBF3FF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _resetQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7070),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Kerjakan Ulang',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Review Jawaban',
              style: TextStyle(
                color: Color(0xFF25273D),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(total, (index) {
              final q = _questions[index];
              final String userAnswerOption = _answers[index] ?? '';
              final String correctAnswerOption = q['jawaban'] ?? '';
              final bool isCorrect = userAnswerOption.toUpperCase() == correctAnswerOption.toUpperCase();
              
              String userAnswerText = '';
              if (userAnswerOption.isNotEmpty) {
                 userAnswerText = q['pilihan_${userAnswerOption.toLowerCase()}']?.toString() ?? userAnswerOption;
              } else {
                 userAnswerText = 'Tidak dijawab';
              }
              String correctAnswerText = q['pilihan_${correctAnswerOption.toLowerCase()}']?.toString() ?? correctAnswerOption;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCorrect ? const Color(0xFF12B892).withOpacity(0.5) : const Color(0xFFFF6B35).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFF12B892) : const Color(0xFFFF6B35),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isCorrect ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                                color: isCorrect ? const Color(0xFF12B892) : const Color(0xFFFF6B35),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${index + 1}. ${q['pertanyaan']}',
                                      style: const TextStyle(
                                        color: Color(0xFF25273D),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Jawabanmu: ',
                                            style: TextStyle(
                                              color: isCorrect ? const Color(0xFF12B892) : const Color(0xFFFF6B35),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: userAnswerText,
                                            style: const TextStyle(
                                              color: Color(0xFF8D90A3),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: 'Jawaban benar: ',
                                            style: TextStyle(
                                              color: Color(0xFF12B892),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: correctAnswerText,
                                            style: const TextStyle(
                                              color: Color(0xFF8D90A3),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required int count, required String label, required Color color, required Color bgColor}) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF007AFF)),
        onPressed: () {
          if (_isSubmitted) {
            Navigator.pop(context);
          } else {
            _showExitConfirmation();
          }
        },
      ),
      title: Text(
        'Latihan ${widget.materiTitle}',
        style: const TextStyle(
          color: Color(0xFF1C1C1E),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Latihan?'),
        content: const Text('Progress Anda akan hilang. Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}