import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/session/app_session.dart';

class MateriScreen extends StatefulWidget {
  const MateriScreen({super.key});

  @override
  State<MateriScreen> createState() => _MateriScreenState();
}

class _MateriScreenState extends State<MateriScreen> {
  static const String baseUrl = 'http://10.0.2.2:8080';
  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFF7EEEF);
  static const Color _textPrimary = Color(0xFF25273D);
  static const Color _textMuted = Color(0xFF8D90A3);

  List<Map<String, dynamic>> _allMateri = [];
  List<Map<String, dynamic>> _filteredMateri = [];
  bool _isLoading = true;
  String _selectedSubject = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _subjects = [
    'Semua', 'Matematika', 'IPA', 'IPS', 'B. Indo', 'B. Inggris', 'Umum',
  ];

  Map<String, Map<String, dynamic>> get _subjectConfig => {
    'Matematika': {'color': const Color(0xFFFF6B35), 'bg': const Color(0xFFFFF0EB), 'icon': Icons.calculate_rounded},
    'IPA': {'color': const Color(0xFF4B9BFF), 'bg': const Color(0xFFEBF3FF), 'icon': Icons.science_rounded},
    'IPS': {'color': const Color(0xFF12B892), 'bg': const Color(0xFFE3FBF4), 'icon': Icons.public_rounded},
    'B. Indo': {'color': const Color(0xFFFF6A88), 'bg': const Color(0xFFFFF0F4), 'icon': Icons.menu_book_rounded},
    'B. Inggris': {'color': const Color(0xFF9B59B6), 'bg': const Color(0xFFF5EEF8), 'icon': Icons.translate_rounded},
    'Umum': {'color': const Color(0xFF6C67FF), 'bg': const Color(0xFFEDEBFF), 'icon': Icons.auto_stories_rounded},
  };

  @override
  void initState() {
    super.initState();
    _fetchMateri();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    return AppSession.getAuthToken();
  }

  Future<void> _fetchMateri({String? subject}) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/api/siswa/materi').replace(
        queryParameters: subject != null && subject != 'Semua' ? {'subject': subject} : null,
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['data'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        setState(() {
          _allMateri = list;
          _filteredMateri = list;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMateri = _allMateri.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final mentor = (item['mentor_name'] ?? '').toString().toLowerCase();
        final subject = (item['subject'] ?? '').toString().toLowerCase();
        return title.contains(query) || mentor.contains(query) || subject.contains(query);
      }).toList();
    });
  }

  void _onSubjectTap(String subject) {
    setState(() => _selectedSubject = subject);
    _fetchMateri(subject: subject);
  }

  Future<void> _openFile(Map<String, dynamic> materi) async {
    final filePath = materi['file_path'] as String? ?? '';
    if (filePath.isEmpty) return;
    final uri = Uri.parse('$baseUrl$filePath');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka file.'), backgroundColor: _accent),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> _getSubjectConfig(String subject) {
    return _subjectConfig[subject] ?? {
      'color': const Color(0xFF8D90A3),
      'bg': const Color(0xFFF0F0F0),
      'icon': Icons.description_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: _background,
  body: SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildSearchBar(),
        _buildSubjectFilter(),
        const SizedBox(height: 8),
        Expanded(child: _buildMateriList()),
      ],
    ),
  ),
);
  }

  Widget _buildHeader() {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
    decoration: const BoxDecoration(
      color: _accent,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
    ),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Materi Pembelajaran',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'Akses materi sesuai paket yang aktif',
                style: TextStyle(color: Color(0xFFFFE5E5), fontSize: 13),
              ),
            ],
          ),
        ),
        const Icon(Icons.menu_book_rounded, color: Colors.white, size: 48),
      ],
    ),
  );
}

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: _textMuted),
            hintText: 'Cari materi atau mentor...',
            hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _subjects.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final subject = _subjects[index];
            final isSelected = _selectedSubject == subject;
            return GestureDetector(
              onTap: () => _onSubjectTap(subject),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _accent : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? _accent : const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  subject,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _textMuted,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMateriList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    if (_filteredMateri.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: const Color(0xFFFFE8E8), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.menu_book_rounded, color: _accent, size: 36),
            ),
            const SizedBox(height: 14),
            const Text('Materi belum tersedia', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Mentor belum mengupload materi apapun.', style: TextStyle(color: _textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: () => _fetchMateri(subject: _selectedSubject),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _filteredMateri.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildMateriCard(_filteredMateri[index]),
      ),
    );
  }

  Widget _buildMateriCard(Map<String, dynamic> materi) {
    final subject = materi['subject'] as String? ?? 'Umum';
    final config = _getSubjectConfig(subject);
    final mentorName = materi['mentor_name'] as String? ?? 'Mentor';
    final fileSize = materi['file_size'] as int? ?? 0;
    final fileType = (materi['file_type'] as String? ?? '.pdf').toUpperCase().replaceAll('.', '');

    return GestureDetector(
      onTap: () => _openFile(materi),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: config['bg'] as Color, borderRadius: BorderRadius.circular(14)),
              child: Icon(config['icon'] as IconData, color: config['color'] as Color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materi['title'] as String? ?? '-',
                    style: const TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text('Kak $mentorName · ${_formatFileSize(fileSize)}', style: const TextStyle(color: _textMuted, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: config['bg'] as Color, borderRadius: BorderRadius.circular(6)),
                        child: Text(subject, style: TextStyle(color: config['color'] as Color, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.picture_as_pdf_rounded, size: 13, color: _textMuted),
                      const SizedBox(width: 3),
                      Text(fileType, style: const TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFD0D0D0)),
          ],
        ),
      ),
    );
  }
}