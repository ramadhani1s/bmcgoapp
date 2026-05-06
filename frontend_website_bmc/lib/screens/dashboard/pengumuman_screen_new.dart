import 'package:flutter/material.dart';
import '../../services/pengumuman_service.dart';

class PengumumanScreen extends StatefulWidget {
  const PengumumanScreen({super.key});

  @override
  State<PengumumanScreen> createState() => _PengumumanScreenState();
}

class _PengumumanScreenState extends State<PengumumanScreen> {
  static const Color _primaryPurple = Color(0xFF7C3AED);
  static const Color _primaryBlue = Color(0xFF3B82F6);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningOrange = Color(0xFFF59E0B);
  static const Color _dangerRed = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMedium = Color(0xFF6B7280);
  static const Color _textLight = Color(0xFF9CA3AF);
  static const Color _bgLight = Color(0xFFF9FAFB);
  static const Color _border = Color(0xFFE5E7EB);

  bool _loading = true;
  List<dynamic> _items = [];
  bool _isCreating = false;

  export 'pengumuman_screen_list.dart';
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelola Pengumuman',
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Buat, kelola, dan terbitkan pengumuman untuk siswa, mentor, dan orang tua',
                    style: TextStyle(color: _textLight, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showCreateModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                '+ Buat Pengumuman',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Stats Row - Paket Les style
        Row(
          children: [
            _buildStatCard(
              'Total Pengumuman',
              _items.length.toString(),
              const Color(0xFFFF7A00),
              const Color(0xFFF6EFE7),
              Icons.campaign_rounded,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Terbaru',
              _items.isEmpty ? '0' : _items.length.toString(),
              const Color(0xFF2E7BEF),
              const Color(0xFFF0F5FF),
              Icons.notifications_rounded,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Card Grid (Paket Les style)
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          )
        else if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Belum ada pengumuman',
              style: TextStyle(color: _textLight, fontSize: 13),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 960
                    ? 3
                  : width >= 640
                        ? 2
                        : 1;
                final cardAspectRatio = crossAxisCount == 1
                  ? 1.85
                    : crossAxisCount == 2
                    ? 2.05
                    : 1.6;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: cardAspectRatio,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _buildAnnouncementCard(item);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAnnouncementCard(dynamic item) {
    final judul = (item['judul'] ?? 'N/A').toString();
    final isi = (item['isi'] ?? '').toString();
    final createdAt = (item['created_at'] ?? '').toString();

    return InkWell(
      onTap: () => _showDetailModal(item),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EDF7)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.08),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFBDEDC9), Color(0xFFD8F2DF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Text(
                judul,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _truncateText(isi, 130),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _actionPill(
                            label: 'Detail',
                            icon: Icons.visibility_outlined,
                            onPressed: () => _showDetailModal(item),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionPill(
                            label: 'Edit',
                            icon: Icons.edit_outlined,
                            onPressed: () => _showEditModal(item),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionPill(
                            label: 'Hapus',
                            icon: Icons.delete_outline,
                            onPressed: () => _showDeleteConfirmation(item),
                            danger: true,
                          ),
                        ),
                      ],
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

  Widget _actionPill({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    final Color color = danger
        ? const Color(0xFFEF4444)
        : const Color(0xFF8B5E57);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.28)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildModalFieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: _textDark,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: -0.2,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: _dangerRed),
            ),
        ],
      ),
    );
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: _textLight,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primaryPurple, width: 2),
        ),
        contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      ),
      style: const TextStyle(
        color: _textDark,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color accentColor,
    Color backgroundColor,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: accentColor.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: const [
        Expanded(
          flex: 2,
          child: Text(
            'JUDUL',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'ISI PREVIEW',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'TANGGAL',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'AKSI',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(dynamic item) {
    final judul = item['judul'] ?? 'N/A';
    final isi = item['isi'] ?? '';
    final createdAt = item['created_at'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              judul,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _truncateText(isi, 40),
              style: const TextStyle(fontSize: 11, color: _textLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              _formatDate(createdAt),
              style: const TextStyle(fontSize: 11, color: _textLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: const Color(0xFF4F82FF),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.delete_outline,
                  size: 14,
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetailModal(dynamic item) async {
    final judul = (item['judul'] ?? 'N/A').toString();
    final isi = (item['isi'] ?? '').toString();
    final createdAt = (item['created_at'] ?? '').toString();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(isi, style: const TextStyle(fontSize: 14, height: 1.6)),
              const SizedBox(height: 12),
              Text(
                'Dibuat: ${_formatDate(createdAt)}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(dynamic item) async {
    final id = item['id'];
    final judul = (item['judul'] ?? 'pengumuman ini').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengumuman'),
        content: Text('Apakah Anda yakin ingin menghapus "$judul"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await PengumumanService.deletePengumuman(id);
        if (!mounted) return;
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengumuman berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _load();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message']?.toString() ?? 'Gagal menghapus pengumuman',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showEditModal(dynamic item) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final id = item['id'];
    final judulController = TextEditingController(text: (item['judul'] ?? '').toString());
    final isiController = TextEditingController(text: (item['isi'] ?? '').toString());

    await showDialog(
      context: context,
      builder: (ctx) {
        final dialogNavigator = Navigator.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 840, maxHeight: MediaQuery.of(ctx).size.height * 0.9),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 18, 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Edit Pengumuman', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                              SizedBox(height: 4),
                              Text('Perbarui isi atau pengaturan pengumuman', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                            ]),
                          ),
                          IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white)),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                        child: SingleChildScrollView(
                          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildModalFieldLabel('Judul Pengumuman', required: true),
                            const SizedBox(height: 8),
                            _buildModalTextField(controller: judulController, hintText: 'Masukkan judul pengumuman'),
                            const SizedBox(height: 16),
                            _buildModalFieldLabel('Isi Pengumuman', required: true),
                            const SizedBox(height: 8),
                            _buildModalTextField(controller: isiController, hintText: 'Tulis isi pengumuman di sini...', maxLines: 4),
                            const SizedBox(height: 16),
                          ]),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF475569), side: const BorderSide(color: Color(0xFFD6DEEA)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Batal')),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(onPressed: () async {
                          if (judulController.text.trim().isEmpty || isiController.text.trim().isEmpty) {
                            scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Judul dan isi tidak boleh kosong'), backgroundColor: _dangerRed));
                            return;
                          }
                          try {
                            final result = await PengumumanService.updatePengumuman(id, {'judul': judulController.text.trim(), 'isi': isiController.text.trim()});
                            if (!mounted) return;
                            if (result['status'] == 'success') {
                              dialogNavigator.pop();
                              scaffoldMessenger.showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Pengumuman berhasil diperbarui'), backgroundColor: _successGreen));
                              _load();
                            } else {
                              scaffoldMessenger.showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Gagal memperbarui pengumuman'), backgroundColor: _dangerRed));
                            }
                          } catch (e) {
                            if (!mounted) return;
                            scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _dangerRed));
                          }
                        }, icon: const Icon(Icons.check_rounded, size: 18), label: const Text('Simpan Perubahan'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
