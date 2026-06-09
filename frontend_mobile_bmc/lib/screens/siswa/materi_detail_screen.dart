import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../core/session/app_session.dart';
import '../../widgets/latihan/soal_card.dart';
import '../../widgets/latihan/navigation_button_row.dart';

class MateriDetailScreen extends StatefulWidget {
  final Map<String, dynamic> materi;

  const MateriDetailScreen({
    super.key,
    required this.materi,
  });

  @override
  State<MateriDetailScreen> createState() => _MateriDetailScreenState();
}

class _MateriDetailScreenState extends State<MateriDetailScreen> {
  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFF7EEEF);
  static const Color _textPrimary = Color(0xFF25273D);
  static const Color _textMuted = Color(0xFF8D90A3);

  int _activeTab = 0; // 0 = Materi, 1 = Latihan Soal
  
  bool _isLoadingLatihan = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _questions = [];
  
  // Quiz State
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  int _currentIndex = 0;
  Map<int, String> _answers = {};
  int _score = 0;
  bool _showPembahasan = true;

  Map<String, Map<String, dynamic>> get _subjectConfig => {
    'Matematika': {
      'color': const Color(0xFFFF6B35),
      'bg': const Color(0xFFFFF0EB),
      'icon': Icons.calculate_rounded,
    },
    'IPA': {
      'color': const Color(0xFF4B9BFF),
      'bg': const Color(0xFFEBF3FF),
      'icon': Icons.science_rounded,
    },
    'IPS': {
      'color': const Color(0xFF12B892),
      'bg': const Color(0xFFE3FBF4),
      'icon': Icons.public_rounded,
    },
    'B. Indo': {
      'color': const Color(0xFFFF6A88),
      'bg': const Color(0xFFFFF0F4),
      'icon': Icons.menu_book_rounded,
    },
    'B. Inggris': {
      'color': const Color(0xFF9B59B6),
      'bg': const Color(0xFFF5EEF8),
      'icon': Icons.translate_rounded,
    },
    'Umum': {
      'color': const Color(0xFF6C67FF),
      'bg': const Color(0xFFEDEBFF),
      'icon': Icons.auto_stories_rounded,
    },
  };

  Map<String, dynamic> _getSubjectConfig(String subject) {
    return _subjectConfig[subject] ??
        {
          'color': const Color(0xFF8D90A3),
          'bg': const Color(0xFFF0F0F0),
          'icon': Icons.description_outlined,
        };
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void initState() {
    super.initState();
    _loadQuestionsFromApi();
  }

  Future<void> _loadQuestionsFromApi() async {
    if (!mounted) return;
    setState(() => _isLoadingLatihan = true);

    try {
      final token = await AppSession.getAuthToken();
      if (!mounted) return;

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingLatihan = false;
          _errorMessage = 'Sesi telah habis, silakan login kembali.';
        });
        return;
      }

      final materiId = widget.materi['id'] ?? 0;
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/siswa/materi/$materiId/soal');
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> soalList = data['data'] as List<dynamic>? ?? [];
        
        List<Map<String, dynamic>> loadedQuestions = [];

        for (final soal in soalList) {
          final String rawPertanyaan = soal['pertanyaan'] ?? '';
          
          if (rawPertanyaan.contains('[SKELETON]')) {
            continue;
          }

          String cleanPertanyaan = rawPertanyaan.replaceFirst(RegExp(r'^(?:\[.*?\]\s*)+'), '').trim();

          loadedQuestions.add({
            'pertanyaan': cleanPertanyaan,
            'pilihan_a': soal['pilihan_a'] ?? '',
            'pilihan_b': soal['pilihan_b'] ?? '',
            'pilihan_c': soal['pilihan_c'] ?? '',
            'pilihan_d': soal['pilihan_d'] ?? '',
            'jawaban': soal['jawaban'] ?? '',
            'pembahasan': soal['pembahasan'] ?? 'Tidak ada pembahasan',
          });
        }

        if (!mounted) return;
        setState(() {
          _questions = loadedQuestions;
          _isLoadingLatihan = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingLatihan = false;
          _errorMessage = 'Gagal memuat soal: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLatihan = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _openPdf() async {
    final filePath = widget.materi['file_path'] as String? ?? '';

    if (filePath.isEmpty) {
      return;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$filePath');

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('ERROR OPEN PDF: $e');
    }
  }

  // --- Quiz Functions ---
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

    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      final selected = _answers[i]?.toUpperCase();
      final correct = (_questions[i]['jawaban'] as String).toUpperCase();
      if (selected == correct) {
        correctCount++;
      }
    }

    try {
      final token = await AppSession.getAuthToken();
      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/api/siswa/latihan/simpan-hasil');
        await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'materi_id': widget.materi['id'] ?? 0,
            'latihan_title': widget.materi['title'] ?? 'Latihan Soal',
            'skor': correctCount,
            'total_soal': _questions.length,
          }),
        ).timeout(const Duration(seconds: 10));
      }
    } catch (e) {
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
    final subject = widget.materi['subject'] as String? ?? 'Umum';
    final config = _getSubjectConfig(subject);
    final title = widget.materi['title'] as String? ?? '-';
    final mentorName = widget.materi['mentor_name'] as String? ?? 'Mentor';
    final fileSize = widget.materi['file_size'] as int? ?? 0;
    final fileType = (widget.materi['file_type'] as String? ?? '.pdf').toUpperCase().replaceAll('.', '');

    return Scaffold(
      backgroundColor: _background,
      body: Column(
        children: [
          // Header Background
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Main Header Content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Box
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        config['icon'] as IconData,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title & Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subject,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Footer Info
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Kak $mentorName',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.description_outlined, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    const Text(
                      '12 Halaman', // Hardcoded as in mockup
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    const Text(
                      'PDF',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tab Switcher
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _activeTab == 0 ? const Color(0xFFEBF3FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: _activeTab == 0 ? const Color(0xFF4B9BFF) : _textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Materi',
                            style: TextStyle(
                              color: _activeTab == 0 ? const Color(0xFF4B9BFF) : _textMuted,
                              fontWeight: _activeTab == 0 ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _activeTab == 1 ? const Color(0xFFFFF0F4) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_rounded,
                            size: 18,
                            color: _activeTab == 1 ? _accent : _textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Latihan Soal',
                            style: TextStyle(
                              color: _activeTab == 1 ? _accent : _textMuted,
                              fontWeight: _activeTab == 1 ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (_questions.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _isSubmitted ? '${_score}/${_questions.length}' : '${_answers.length}/${_questions.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content Area
          Expanded(
            child: _activeTab == 0 ? _buildMateriTab(config, description: widget.materi['description'] as String? ?? '', fileSize: fileSize, fileType: fileType) : _buildLatihanTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildMateriTab(Map<String, dynamic> config, {required String description, required int fileSize, required String fileType}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File Info
          if (fileSize > 0)
            GestureDetector(
              onTap: _openPdf,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _accent.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf_rounded,
                        color: _accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'File Materi (Tap untuk buka)',
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$fileType • ${_formatFileSize(fileSize)}',
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new_rounded,
                      color: _accent,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Description
          if (description.isNotEmpty) ...[
            const Text(
              'Deskripsi',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                description,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLatihanTab() {
    if (_isLoadingLatihan) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
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
                color: _textPrimary,
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
      );
    }

    if (_isSubmitted) {
      return _buildResultView();
    }

    final currentQuestion = _questions[_currentIndex];
    final selectedAnswer = _answers[_currentIndex];
    
    final List<String> options = [
      currentQuestion['pilihan_a']?.toString() ?? '',
      currentQuestion['pilihan_b']?.toString() ?? '',
      currentQuestion['pilihan_c']?.toString() ?? '',
      currentQuestion['pilihan_d']?.toString() ?? '',
    ];

    // Progress percentage
    final double progress = (_currentIndex + 1) / _questions.length;

    return Column(
      children: [
        // Custom Progress Indicator above Soal Card as in Mockup
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800), // Orange progress
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: SoalCard(
              currentSoal: _currentIndex + 1,
              totalSoal: _questions.length,
              soalText: currentQuestion['pertanyaan'] ?? '',
              options: options,
              selectedAnswer: selectedAnswer,
              isSubmitted: selectedAnswer != null, // Show colors immediately upon selection like in modern apps, or keep it true if selected
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
    );
  }

  Widget _buildResultView() {
    final int total = _questions.length;
    final int correct = _score;
    final int wrong = total - correct;
    final int finalScore = total > 0 ? (correct / total * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
}
