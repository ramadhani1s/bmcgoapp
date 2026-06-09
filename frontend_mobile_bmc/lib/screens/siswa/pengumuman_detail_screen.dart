import 'package:flutter/material.dart';

class PengumumanDetailScreen extends StatelessWidget {
  const PengumumanDetailScreen({super.key, required this.item});

  final Map<String, dynamic> item;

  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFF7EEEF);
  static const Color _textPrimary = Color(0xFF25273D);
  static const Color _textMuted = Color(0xFF8D90A3);

  String _formatDateHeader(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}  •  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return rawDate;
    }
  }

  String _formatDateFull(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      const days = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
      const months = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
      return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return rawDate;
    }
  }

  String _formatTime(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} WIB';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = item['created_at'] as String? ?? '';
    final judul     = item['judul'] as String? ?? '-';
    final isi       = item['isi']   as String? ?? '-';

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFF7070),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          judul,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateHeader(createdAt),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Konten ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  children: [

                    // Card: Informasi Pengumuman
                    _buildCard(
                      icon: Icons.campaign_rounded,
                      title: 'Informasi Pengumuman',
                      children: [
                        _buildRow('Tanggal', _formatDateFull(createdAt)),
                        _buildDivider(),
                        _buildRow('Waktu', _formatTime(createdAt)),
                        _buildDivider(),
                        _buildRow('Sumber', 'Admin BMC'),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Card: Isi Pengumuman
                    _buildCard(
                      icon: Icons.article_rounded,
                      title: 'Isi Pengumuman',
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            isi,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 14,
                              height: 1.75,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Info tip box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18, color: _accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pengumuman ini bersifat resmi dari BMC. Harap diperhatikan dan disebarluaskan kepada yang bersangkutan.',
                              style: TextStyle(
                                color: _accent.withOpacity(0.85),
                                fontSize: 12.5,
                                height: 1.5,
                              ),
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
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: _textMuted, fontSize: 13.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, color: Color(0xFFF5F5F5));
}