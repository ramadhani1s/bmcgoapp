import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_mobile_bmc/config/api_config.dart';
import '../../core/session/app_session.dart';

class LatihanDariMateriScreen extends StatefulWidget {
  final String subject;
  final String materiTitle;

  const LatihanDariMateriScreen({
    super.key,
    required this.subject,
    required this.materiTitle,
  });

  @override
  State<LatihanDariMateriScreen> createState() => _LatihanDariMateriScreenState();
}

class _LatihanDariMateriScreenState extends State<LatihanDariMateriScreen> {
  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFF7EEEF);
  static const Color _textPrimary = Color(0xFF25273D);
  static const Color _textMuted = Color(0xFF8D90A3);

  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _submitted = false;
  bool _isSubmitting = false;
  int _currentIndex = 0;
  final Map<String, String> _answers = {};
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<String?> _getToken() async {
    try {
      return await AppSession.getAuthToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadQuestions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (!mounted) return;

      if (token == null || token.isEmpty) {
        setState(() {
          _questions = [];
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

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/siswa/soal-latihan').replace(
        queryParameters: {'subject': widget.subject},
      );
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['data'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        
        if (!mounted) return;
        setState(() {
          _questions = list;
          _isLoading = false;
          _currentIndex = 0;
          _answers.clear();
          _submitted = false;
          _score = 0;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat soal latihan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectAnswer(String answer) {
    if (_submitted) return;
    setState(() {
      _answers['q_$_currentIndex'] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _submitAnswers() async {
    if (_questions.isEmpty) return;

    // Check if all questions answered
    final missing = <int>[];
    for (int i = 0; i < _questions.length; i++) {
      if (!_answers.containsKey('q_$i')) {
        missing.add(i + 1);
      }
    }

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lengkapi soal: ${missing.join(', ')}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    var score = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final selected = _answers['q_$i']?.toUpperCase();
      final correct = (q['jawaban'] as String? ?? '').toUpperCase();
      if (selected == correct) {
        score += 1;
      }
    }

    setState(() {
      _submitted = true;
      _score = score;
      _isSubmitting = false;
    });
  }

  Map<String, dynamic> _getSubjectConfig(String subject) {
    final configs = {
      'Matematika': {
        'color': const Color(0xFFFF6B35),
        'bg': const Color(0xFFFFF0EB),
      },
      'IPA': {
        'color': const Color(0xFF4B9BFF),
        'bg': const Color(0xFFEBF3FF),
      },
      'IPS': {
        'color': const Color(0xFF12B892),
        'bg': const Color(0xFFE3FBF4),
      },
      'B. Indo': {
        'color': const Color(0xFFFF6A88),
        'bg': const Color(0xFFFFF0F4),
      },
      'B. Inggris': {
        'color': const Color(0xFF9B59B6),
        'bg': const Color(0xFFF5EEF8),
      },
      'Umum': {
        'color': const Color(0xFF6C67FF),
        'bg': const Color(0xFFEDEBFF),
      },
    };
    return configs[subject] ??
        {
          'color': const Color(0xFF8D90A3),
          'bg': const Color(0xFFF0F0F0),
        };
  }

  @override
  Widget build(BuildContext context) {
    final config = _getSubjectConfig(widget.subject);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: config['bg'] as Color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: _textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.materiTitle,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.quiz_rounded,
                          color: _accent,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Soal belum tersedia',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Belum ada soal latihan untuk materi ini.',
                        style: TextStyle(color: _textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Progress Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: config['bg'] as Color,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Soal ${_currentIndex + 1} dari ${_questions.length}',
                                        style: TextStyle(
                                          color: config['color'] as Color,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${((_currentIndex + 1) / _questions.length * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: config['color'] as Color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: (_currentIndex + 1) /
                                          _questions.length,
                                      minHeight: 6,
                                      backgroundColor: Colors.white,
                                      valueColor: AlwaysStoppedAnimation(
                                        config['color'] as Color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Question
                            if (!_submitted) ...[
                              Text(
                                'Pertanyaan',
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Text(
                                  _questions[_currentIndex]['pertanyaan']
                                      as String? ??
                                      '-',
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Options
                              ..._buildOptions(),
                            ] else
                              _buildResultView(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _questions.isNotEmpty
          ? Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
              child: _submitted
                  ? ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 0;
                          _answers.clear();
                          _submitted = false;
                          _score = 0;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Mulai Ulang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _currentIndex == 0 ? null : _previousQuestion,
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: _currentIndex == 0
                                    ? Colors.grey[300]!
                                    : config['color'] as Color,
                              ),
                            ),
                            child: Text(
                              '← Sebelumnya',
                              style: TextStyle(
                                color: _currentIndex == 0
                                    ? Colors.grey[500]
                                    : config['color'] as Color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : (_currentIndex == _questions.length - 1
                                    ? _submitAnswers
                                    : _nextQuestion),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isSubmitting
                                  ? 'Mengirim...'
                                  : (_currentIndex == _questions.length - 1
                                      ? 'Selesai'
                                      : 'Berikutnya →'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            )
          : null,
    );
  }

  List<Widget> _buildOptions() {
    final q = _questions[_currentIndex];
    final options = [
      {'key': 'A', 'value': q['pilihan_a'] as String? ?? ''},
      {'key': 'B', 'value': q['pilihan_b'] as String? ?? ''},
      {'key': 'C', 'value': q['pilihan_c'] as String? ?? ''},
      {'key': 'D', 'value': q['pilihan_d'] as String? ?? ''},
    ];

    final selected = _answers['q_$_currentIndex'];
    final config = _getSubjectConfig(widget.subject);

    return options.map((opt) {
      final key = opt['key'] as String;
      final isSelected = selected == key;
      return GestureDetector(
        onTap: () => _selectAnswer(key),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? (config['bg'] as Color).withOpacity(0.5)
                : Colors.white,
            border: Border.all(
              color: isSelected
                  ? config['color'] as Color
                  : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? config['color'] as Color
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    key,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  opt['value'] as String,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildResultView() {
    final percentage = ((_score / _questions.length) * 100).toStringAsFixed(0);
    final isPassed = _score >= (_questions.length * 0.6);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isPassed
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              isPassed ? Icons.check_circle_rounded : Icons.info_rounded,
              size: 40,
              color: isPassed ? const Color(0xFF4CAF50) : _accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'Selamat! Anda Lulus' : 'Skor Anda',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_score / ${_questions.length} benar',
            style: TextStyle(
              color: _textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isPassed
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$percentage%',
              style: TextStyle(
                color: isPassed ? const Color(0xFF4CAF50) : _accent,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
