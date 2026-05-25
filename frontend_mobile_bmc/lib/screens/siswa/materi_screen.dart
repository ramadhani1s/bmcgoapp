import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/session/app_session.dart';
import '../../widgets/materi/materi_header.dart';
import '../../widgets/materi/materi_search_bar.dart';
import '../../widgets/materi/subject_filter.dart';
import '../../widgets/materi/materi_card.dart';

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

  // file size formatting moved to MateriCard widget when needed

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
        MateriHeader(title: 'Materi Pembelajaran', subtitle: 'Akses materi sesuai paket yang aktif', accentColor: _accent),
        MateriSearchBar(controller: _searchController, hint: 'Cari materi atau mentor...', mutedColor: _textMuted),
        SubjectFilter(subjects: _subjects, selected: _selectedSubject, onTap: _onSubjectTap, accentColor: _accent, mutedColor: _textMuted),
        const SizedBox(height: 8),
        Expanded(child: _buildMateriList()),
      ],
    ),
  ),
);
  }

  // UI moved to widgets: MateriHeader, MateriSearchBar, SubjectFilter, MateriCard

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
        itemBuilder: (context, index) {
          final m = _filteredMateri[index];
          return MateriCard(
            materi: m,
            onTap: () => _openFile(m),
            getSubjectConfig: _getSubjectConfig,
            textPrimary: _textPrimary,
            textMuted: _textMuted,
          );
        },
      ),
    );
  }
}