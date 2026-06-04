import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../core/session/app_session.dart';
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

  bool _isLoadingLatihan = true;
  String? _errorMessage;
  Map<String, List<Map<String, dynamic>>> _groupedQuestions = {};

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
        
        final Map<String, List<Map<String, dynamic>>> grouped = {};

        for (final soal in soalList) {
          final String rawPertanyaan = soal['pertanyaan'] ?? '';
          
          if (rawPertanyaan.contains('[SKELETON]')) {
            continue;
          }

          String title = 'Latihan Soal';
          String cleanPertanyaan = rawPertanyaan;
          
          // Try to extract title from [Latihan:Title] format
          final titleMatch = RegExp(r'\[Latihan:(.*?)\]').firstMatch(rawPertanyaan);
          if (titleMatch != null) {
            title = titleMatch.group(1)?.trim() ?? 'Latihan Soal';
          } else {
             // Fallback for older formats where the 3rd bracket was the title
             final oldFormatMatch = RegExp(r'^\[.*?\]\[.*?\]\[(.*?)\]').firstMatch(rawPertanyaan);
             if (oldFormatMatch != null && !oldFormatMatch.group(1)!.contains(':')) {
                 title = oldFormatMatch.group(1)?.trim() ?? 'Latihan Soal';
             }
          }

          // Aggressively strip ALL metadata brackets at the start of the string
          cleanPertanyaan = rawPertanyaan.replaceFirst(RegExp(r'^(?:\[.*?\]\s*)+'), '').trim();

          final formattedSoal = {
            'pertanyaan': cleanPertanyaan,
            'pilihan_a': soal['pilihan_a'] ?? '',
            'pilihan_b': soal['pilihan_b'] ?? '',
            'pilihan_c': soal['pilihan_c'] ?? '',
            'pilihan_d': soal['pilihan_d'] ?? '',
            'jawaban': soal['jawaban'] ?? '',
            'pembahasan': soal['pembahasan'] ?? 'Tidak ada pembahasan',
          };

          grouped.putIfAbsent(title, () => []).add(formattedSoal);
        }

        if (!mounted) return;
        setState(() {
          _groupedQuestions = grouped;
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

  void _startPractice(String title, List<Map<String, dynamic>> questions) {
    Navigator.pushNamed(
      context,
      '/latihan-dari-materi',
      arguments: {
        'materi_title': title,
        'materi_id': widget.materi['id'] ?? 0,
        'questions': questions,
      },
    );
  }

  Future<void> _openPdf() async {
  final filePath = widget.materi['file_path'] as String? ?? '';

  if (filePath.isEmpty) {
    return;
  }

  final uri = Uri.parse(
    'http://10.0.2.2:8080$filePath',
  );

  try {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    print('ERROR OPEN PDF: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    final subject = widget.materi['subject'] as String? ?? 'Umum';
    final config = _getSubjectConfig(subject);
    final title = widget.materi['title'] as String? ?? '-';
    final description = widget.materi['description'] as String? ?? '';
    final mentorName = widget.materi['mentor_name'] as String? ?? 'Mentor';
    final fileSize = widget.materi['file_size'] as int? ?? 0;
    final fileType = (widget.materi['file_type'] as String? ?? '.pdf').toUpperCase().replaceAll('.', '');
    
    // DEBUG
    print('DEBUG MateriDetail: materi keys = ${widget.materi.keys.toList()}');
    print('DEBUG MateriDetail: file_path = ${widget.materi['file_path']}');
    print('DEBUG MateriDetail: subject = $subject, title = $title, fileSize = $fileSize');

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
          'Detail Materi',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: config['bg'] as Color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      config['icon'] as IconData,
                      color: config['color'] as Color,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subject Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.label_rounded,
                          size: 14,
                          color: config['color'] as Color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subject,
                          style: TextStyle(
                            color: config['color'] as Color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mentor Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: config['bg'] as Color,
                          child: Icon(
                            Icons.person_rounded,
                            color: config['color'] as Color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pengajar',
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Kak $mentorName',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // File Info
                  if (fileSize > 0)
                    GestureDetector(
                      onTap: _openPdf,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: config['color'] as Color,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf_rounded,
                              color: config['color'] as Color,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'File Materi (Tap untuk buka)',
                                    style: TextStyle(
                                      color: _textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '$fileType • ${_formatFileSize(fileSize)}',
                                    style: TextStyle(
                                      color: _textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.open_in_new_rounded,
                              color: config['color'] as Color,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Description
                  if (description.isNotEmpty) ...[
                    Text(
                      'Deskripsi',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        description,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // --- Daftar Latihan Soal ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar Latihan Soal',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingLatihan)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  else if (_groupedQuestions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Belum ada latihan soal untuk materi ini.',
                          style: TextStyle(color: _textMuted),
                        ),
                      ),
                    )
                  else
                    ..._groupedQuestions.entries.map((entry) {
                      final title = entry.key;
                      final questions = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.quiz_rounded,
                              color: _accent,
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            '${questions.length} Soal',
                            style: TextStyle(color: _textMuted, fontSize: 13),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _startPractice(title, questions),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Mulai', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
