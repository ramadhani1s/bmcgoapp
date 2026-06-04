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

  const LatihanDariMateriScreen({
    super.key,
    required this.materiTitle,
    required this.materiId,
  });

  @override
  State<LatihanDariMateriScreen> createState() => _LatihanDariMateriScreenState();
}

class _LatihanDariMateriScreenState extends State<LatihanDariMateriScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  int _currentIndex = 0;
  Map<int, String> _answers = {};
  int _score = 0;
  bool _showPembahasan = true;

  @override
  void initState() {
    super.initState();
    _loadQuestionsFromApi();
  }

  Future<String?> _getToken() async {
    try {
      return await AppSession.getAuthToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadQuestionsFromApi() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      if (!mounted) return;

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login tidak ditemukan. Silakan login ulang.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/siswa/materi/${widget.materiId}/soal');
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> soalList = data['data'] as List<dynamic>? ?? [];
        
        // Konversi ke format yang dibutuhkan widget
        final List<Map<String, dynamic>> formattedQuestions = soalList.map((soal) {
          return {
            'pertanyaan': soal['pertanyaan'] ?? '',
            'pilihan_a': soal['pilihan_a'] ?? '',
            'pilihan_b': soal['pilihan_b'] ?? '',
            'pilihan_c': soal['pilihan_c'] ?? '',
            'pilihan_d': soal['pilihan_d'] ?? '',
            'jawaban': soal['jawaban'] ?? '',
            'pembahasan': soal['pembahasan'] ?? 'Tidak ada pembahasan',
          };
        }).toList();

        if (!mounted) return;
        setState(() {
          _questions = formattedQuestions;
          _isLoading = false;
          _currentIndex = 0;
          _answers.clear();
          _isSubmitted = false;
          _score = 0;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat soal: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
            'skor': correctCount,
            'total_soal': _questions.length,
            'jawaban': _answers,
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF007AFF)),
        ),
      );
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
            child: _isSubmitted
                ? ElevatedButton(
                    onPressed: _resetQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Kerjakan Ulang',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  )
                : NavigationButtonRow(
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
      title: const Text(
        'Latihan Soal',
        style: TextStyle(
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