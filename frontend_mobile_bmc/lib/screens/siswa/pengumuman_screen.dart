import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/session/app_session.dart';
import '../../widgets/pengumuman/pengumuman_header.dart';
import '../../widgets/pengumuman/kategori_filter.dart';
import '../../widgets/pengumuman/pengumuman_card.dart';
import '../../widgets/pengumuman/pengumuman_empty.dart';

class PengumumanScreen extends StatefulWidget {
  const PengumumanScreen({super.key});

  @override
  State<PengumumanScreen> createState() => _PengumumanScreenState();
}

class _PengumumanScreenState extends State<PengumumanScreen> {
  static const String baseUrl = 'http://10.0.2.2:8080';
  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFF7EEEF);
  static const Color _textPrimary = Color(0xFF25273D);
  static const Color _textMuted = Color(0xFF8D90A3);

  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _selectedKategori = 'Semua';

  final List<String> _kategori = ['Semua', 'Jadwal', 'Akademik', 'Pembayaran', 'Umum'];

  Map<String, Map<String, dynamic>> get _kategoriConfig => {
    'Jadwal': {'color': const Color(0xFF4B9BFF), 'bg': const Color(0xFFEBF3FF), 'icon': Icons.calendar_today_rounded},
    'Akademik': {'color': const Color(0xFF12B892), 'bg': const Color(0xFFE3FBF4), 'icon': Icons.school_rounded},
    'Pembayaran': {'color': const Color(0xFFFF6B35), 'bg': const Color(0xFFFFF0EB), 'icon': Icons.payment_rounded},
    'Umum': {'color': const Color(0xFF6C67FF), 'bg': const Color(0xFFEDEBFF), 'icon': Icons.campaign_rounded},
  };

  @override
  void initState() {
    super.initState();
    _fetchPengumuman();
  }

  Future<String> _getToken() async {
    return AppSession.getAuthToken();
  }

  Future<void> _fetchPengumuman({String? kategori}) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/api/siswa/pengumuman').replace(
        queryParameters: kategori != null && kategori != 'Semua' ? {'kategori': kategori} : null,
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
          _filtered = list;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onKategoriTap(String kategori) {
    setState(() => _selectedKategori = kategori);
    _fetchPengumuman(kategori: kategori);
  }

  Map<String, dynamic> _getKategoriConfig(String kategori) {
    return _kategoriConfig[kategori] ?? {
      'color': const Color(0xFF8D90A3),
      'bg': const Color(0xFFF0F0F0),
      'icon': Icons.info_outline_rounded,
    };
  }

  // date formatting moved into PengumumanCard

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            PengumumanHeader(accentColor: _accent),
            KategoriFilter(kategori: _kategori, selected: _selectedKategori, onTap: _onKategoriTap, accentColor: _accent, mutedColor: _textMuted),
            const SizedBox(height: 8),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // header and kategori filter moved to widgets

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_filtered.isEmpty) return const PengumumanEmpty(accentColor: _accent);

    return RefreshIndicator(
      color: _accent,
      onRefresh: () => _fetchPengumuman(kategori: _selectedKategori),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _filtered[index];
          return PengumumanCard(
            item: item,
            onTap: () {
              // keep current behavior: could navigate to detail
            },
            getKategoriConfig: _getKategoriConfig,
            textPrimary: _textPrimary,
            textMuted: _textMuted,
          );
        },
      ),
    );
  }

  // card UI moved to PengumumanCard
}