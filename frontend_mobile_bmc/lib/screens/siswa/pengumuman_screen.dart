import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  List<Map<String, dynamic>> _allPengumuman = [];
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
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
          _allPengumuman = list;
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

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildKategoriFilter(),
            const SizedBox(height: 8),
            Expanded(child: _buildList()),
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
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pengumuman', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Informasi resmi dari BMC', style: TextStyle(color: Color(0xFFFFE5E5), fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Widget _buildKategoriFilter() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _kategori.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final k = _kategori[index];
            final isSelected = _selectedKategori == k;
            return GestureDetector(
              onTap: () => _onKategoriTap(k),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _accent : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? _accent : const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  k,
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

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: const Color(0xFFFFE8E8), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.campaign_rounded, color: _accent, size: 36),
            ),
            const SizedBox(height: 14),
            const Text('Belum ada pengumuman', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Admin belum membuat pengumuman apapun.', style: TextStyle(color: _textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: () => _fetchPengumuman(kategori: _selectedKategori),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildCard(_filtered[index]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final kategori = item['kategori'] as String? ?? 'Umum';
    final config = _getKategoriConfig(kategori);
    final createdAt = item['created_at'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: config['bg'] as Color, borderRadius: BorderRadius.circular(14)),
            child: Icon(config['icon'] as IconData, color: config['color'] as Color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['judul'] as String? ?? '-',
                  style: const TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  item['isi'] as String? ?? '-',
                  style: const TextStyle(color: _textMuted, fontSize: 12.5, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(color: _textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFD0D0D0)),
        ],
      ),
    );
  }
}