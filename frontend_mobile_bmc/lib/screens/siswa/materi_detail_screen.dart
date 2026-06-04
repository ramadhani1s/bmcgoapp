import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

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

  void _startPractice() {
    final subject = widget.materi['subject'] as String? ?? 'Umum';
    Navigator.pushNamed(
      context,
      '/latihan-dari-materi',
      arguments: {
        'materi_title': widget.materi['title'] as String? ?? 'Latihan Soal',
        'materi_id': widget.materi['id'] ?? 0,
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
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
        child: ElevatedButton(
          onPressed: _startPractice,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Mulai Latihan Soal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
