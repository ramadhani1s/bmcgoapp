import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/config/api_config.dart';
import 'package:http/http.dart' as http;

import '../../core/session/app_session.dart';
import '../../widgets/pengumuman/pengumuman_header.dart';
import '../../widgets/pengumuman/pengumuman_card.dart';
import '../../widgets/pengumuman/pengumuman_empty.dart';
import 'pengumuman_detail_screen.dart';

class PengumumanScreen extends StatefulWidget {
  const PengumumanScreen({super.key});

  @override
  State<PengumumanScreen> createState() => _PengumumanScreenState();
}

class _PengumumanScreenState extends State<PengumumanScreen> {
  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFF7EEEF);
  static const Color _textPrimary = Color(0xFF25273D);
  static const Color _textMuted = Color(0xFF8D90A3);

  List<Map<String, dynamic>> _list = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPengumuman();
  }

  Future<void> _fetchPengumuman() async {
    setState(() => _isLoading = true);
    try {
      final token = await AppSession.getAuthToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/siswa/pengumuman');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawList = data['data'];
        final list = (rawList as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        setState(() {
          _list = list;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PengumumanDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            PengumumanHeader(accentColor: _accent),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_list.isEmpty) return const PengumumanEmpty(accentColor: _accent);

    return RefreshIndicator(
      color: _accent,
      onRefresh: _fetchPengumuman,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _list[index];
          return PengumumanCard(
            item: item,
            onTap: () => _openDetail(item),
            textPrimary: _textPrimary,
            textMuted: _textMuted,
          );
        },
      ),
    );
  }
}