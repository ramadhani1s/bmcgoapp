<<<<<<< HEAD
export 'pengumuman_screen.dart';                    style: TextStyle(color: _textLight, fontSize: 12),
=======
import 'package:flutter/material.dart';
import '../../services/pengumuman_service.dart';

class PengumumanScreen extends StatefulWidget {
  const PengumumanScreen({super.key});

  @override
  State<PengumumanScreen> createState() => _PengumumanScreenState();
}

class _PengumumanScreenState extends State<PengumumanScreen> {
  static const Color _primaryPurple = Color(0xFF7C3AED);
  static const Color _border = Color(0xFFDDE4F0);
  static const Color _textDark = Color(0xFF1E2A3E);
  static const Color _textLight = Color(0xFF667287);

  bool _loading = true;
  List<dynamic> _items = [];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await PengumumanService.getPengumumanList();
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showCreateModal() async {
    final judulController = TextEditingController();
    final isiController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          '+ Buat Pengumuman',
          style: TextStyle(
            color: _primaryPurple,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Judul',
                  style: TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: judulController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan judul pengumuman',
                    hintStyle: const TextStyle(color: Color(0xFFADB5C2)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Isi',
                  style: TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: isiController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Masukkan isi pengumuman...',
                    hintStyle: const TextStyle(color: Color(0xFFADB5C2)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(color: _textLight, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: _isCreating
                ? null
                : () async {
                    if (judulController.text.isEmpty ||
                        isiController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Judul dan Isi tidak boleh kosong'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() => _isCreating = true);
                    try {
                      final body = {
                        'judul': judulController.text,
                        'isi': isiController.text,
                      };
                      final result = await PengumumanService.createPengumuman(
                        body,
                      );

                      if (!mounted) return;

                      if (result['status'] == 'success') {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message']?.toString() ??
                                  'Pengumuman berhasil dibuat',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _load();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message']?.toString() ??
                                  'Gagal membuat pengumuman',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _isCreating = false);
                      }
                    }
                  },
            child: const Text(
              'Simpan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    return text.length > maxLength
        ? '${text.substring(0, maxLength)}...'
        : text;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
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
>>>>>>> 44babeedb4d212486e41dd7ced134688cb1ddc98
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
        const SizedBox(height: 16),
        // Stats Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Pengumuman',
                _items.length.toString(),
                const Color(0xFFFF7A00),
                const Color(0xFFF6EFE7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Terbaru',
                _items.isEmpty ? '0' : _items.length.toString(),
                const Color(0xFF2E7BEF),
                const Color(0xFFF0F5FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // List Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: const BoxDecoration(
                  color: _primaryPurple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: const Text(
                  'Daftar Pengumuman',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      const SizedBox(height: 6),
                      ..._items.map((item) => _buildTableRow(item)).toList(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: _textLight, fontSize: 11.5),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _textDark,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
}
