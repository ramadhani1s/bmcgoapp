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
  bool _isCreating = false;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await PengumumanService.getPengumumanList();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _showCreateModal() async {
    final judulController = TextEditingController();
    final isiController = TextEditingController();
    String selectedKategori = 'Umum';
    String selectedTarget = 'Semua';
    String selectedStatus = 'Draft';
    bool isPinned = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: _PanelShell(
            width: 620,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.add, color: _primaryPurple, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buat Pengumuman Baru',
                            style: TextStyle(
                              color: _textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tulis pengumuman untuk diterbitkan ke siswa, mentor, atau orang tua',
                            style: TextStyle(color: _textLight, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    _closeButton(() => Navigator.of(ctx).pop()),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Judul Pengumuman', required: true),
                const SizedBox(height: 6),
                TextField(
                  controller: judulController,
                  decoration: _inputDecoration(
                    hintText: 'Masukkan judul pengumuman',
                  ),
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Isi Pengumuman', required: true),
                const SizedBox(height: 6),
                TextField(
                  controller: isiController,
                  maxLines: 5,
                  decoration: _inputDecoration(
                    hintText: 'Tulis isi pengumuman di sini...',
                    alignTop: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Kategori'),
                          const SizedBox(height: 6),
                          _buildDropdownField(
                            value: selectedKategori,
                            items: const [
                              'Umum',
                              'Akademik',
                              'Event',
                              'Pembayaran',
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() => selectedKategori = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Target Penerima'),
                          const SizedBox(height: 6),
                          _buildDropdownField(
                            value: selectedTarget,
                            items: const [
                              'Semua',
                              'Siswa',
                              'Mentor',
                              'Orang Tua',
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() => selectedTarget = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Status'),
                          const SizedBox(height: 6),
                          _buildDropdownField(
                            value: selectedStatus,
                            items: const [
                              'Draft',
                              'Diterbitkan',
                              'Dijadwalkan',
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() => selectedStatus = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Pin Pengumuman'),
                          const SizedBox(height: 6),
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _border),
                            ),
                            child: Row(
                              children: [
                                Switch(
                                  value: isPinned,
                                  onChanged: (value) {
                                    setDialogState(() => isPinned = value);
                                  },
                                  activeThumbColor: const Color(0xFF2E73FF),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isPinned ? 'Aktif' : 'Tidak aktif',
                                  style: TextStyle(
                                    color: isPinned
                                        ? const Color(0xFF2E73FF)
                                        : _textLight,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textDark,
                        side: const BorderSide(color: Color(0xFFE1E6EE)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isCreating
                          ? null
                          : () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              final navigator = Navigator.of(ctx);

                              if (judulController.text.trim().isEmpty ||
                                  isiController.text.trim().isEmpty) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Judul dan Isi tidak boleh kosong',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setState(() => _isCreating = true);
                              try {
                                final result =
                                    await PengumumanService.createPengumuman({
                                      'judul': judulController.text.trim(),
                                      'isi': isiController.text.trim(),
                                    });

                                if (!mounted) return;

                                if (result['status'] == 'success') {
                                  navigator.pop();
                                  scaffoldMessenger.showSnackBar(
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
                                  scaffoldMessenger.showSnackBar(
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
                                scaffoldMessenger.showSnackBar(
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
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Buat Pengumuman'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: _PanelShell(
          width: 420,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    color: _primaryPurple,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Pengumuman',
                          style: TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Informasi lengkap pengumuman',
                          style: TextStyle(color: _textLight, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  _closeButton(() => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _ModalChip(
                    label: 'Umum',
                    bgColor: Color(0xFFEAF1FF),
                    textColor: Color(0xFF2B58E8),
                  ),
                  _ModalChip(
                    label: 'Semua',
                    bgColor: Color(0xFFEAF7FF),
                    textColor: Color(0xFF2F6FDF),
                    icon: Icons.groups_outlined,
                  ),
                  _ModalChip(
                    label: 'Diterbitkan',
                    bgColor: Color(0xFFE8F9EE),
                    textColor: Color(0xFF15803D),
                  ),
                  _ModalChip(
                    label: 'Pinned',
                    bgColor: Color(0xFFFFF5D9),
                    textColor: Color(0xFFD97706),
                    icon: Icons.push_pin_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                judul,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  isi,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _textLight,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DetailInfoItem(
                      label: 'Dibuat',
                      value: _formatDate(createdAt),
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _DetailInfoItem(
                      label: 'Diterbitkan',
                      value: '14 Apr 2026',
                      icon: Icons.send_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _DetailInfoItem(
                      label: 'Dibuat Oleh',
                      value: 'Admin BMC',
                      icon: Icons.person_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textDark,
                    side: const BorderSide(color: Color(0xFFE1E6EE)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditModal(dynamic item) async {
    final id = item['id'];
    final judulController = TextEditingController(
      text: (item['judul'] ?? '').toString(),
    );
    final isiController = TextEditingController(
      text: (item['isi'] ?? '').toString(),
    );

    String selectedKategori = (item['kategori'] ?? 'Umum').toString();
    String selectedTarget = (item['target'] ?? 'Semua').toString();
    String selectedStatus = (item['status'] ?? 'Diterbitkan').toString();
    bool isPinned = (item['pinned'] is bool) ? item['pinned'] as bool : true;
    bool isUpdating = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: _PanelShell(
            width: 500,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFFFB6A00),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Pengumuman',
                              style: TextStyle(
                                color: _textDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ubah isi atau pengaturan pengumuman',
                              style: TextStyle(
                                color: _textLight,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _closeButton(() => Navigator.of(ctx).pop()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('Judul Pengumuman', required: true),
                  const SizedBox(height: 6),
                  TextField(
                    controller: judulController,
                    decoration: _inputDecoration(
                      hintText: 'Masukkan judul pengumuman',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('Isi Pengumuman', required: true),
                  const SizedBox(height: 6),
                  TextField(
                    controller: isiController,
                    maxLines: 5,
                    decoration: _inputDecoration(
                      hintText: 'Tulis isi pengumuman di sini...',
                      alignTop: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Kategori'),
                            const SizedBox(height: 6),
                            _buildDropdownField(
                              value: selectedKategori,
                              items: const [
                                'Umum',
                                'Akademik',
                                'Event',
                                'Pembayaran',
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => selectedKategori = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Target Penerima'),
                            const SizedBox(height: 6),
                            _buildDropdownField(
                              value: selectedTarget,
                              items: const [
                                'Semua',
                                'Siswa',
                                'Mentor',
                                'Orang Tua',
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => selectedTarget = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Status'),
                            const SizedBox(height: 6),
                            _buildDropdownField(
                              value: selectedStatus,
                              items: const [
                                'Draft',
                                'Diterbitkan',
                                'Dijadwalkan',
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => selectedStatus = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Pin Pengumuman'),
                            const SizedBox(height: 6),
                            Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _border),
                              ),
                              child: Row(
                                children: [
                                  Switch(
                                    value: isPinned,
                                    onChanged: (value) {
                                      setDialogState(() => isPinned = value);
                                    },
                                    activeThumbColor: const Color(0xFF2E73FF),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isPinned ? 'Aktif' : 'Tidak aktif',
                                    style: TextStyle(
                                      color: isPinned
                                          ? const Color(0xFF2E73FF)
                                          : _textLight,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textDark,
                          side: const BorderSide(color: Color(0xFFE1E6EE)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: isUpdating
                            ? null
                            : () async {
                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );
                                final navigator = Navigator.of(ctx);

                                if (judulController.text.trim().isEmpty ||
                                    isiController.text.trim().isEmpty) {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Judul dan Isi tidak boleh kosong',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setState(() => isUpdating = true);
                                try {
                                  final result =
                                      await PengumumanService.updatePengumuman(
                                        id,
                                        {
                                          'judul': judulController.text.trim(),
                                          'isi': isiController.text.trim(),
                                        },
                                      );

                                  if (!mounted) return;

                                  if (result['status'] == 'success') {
                                    navigator.pop();
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result['message']?.toString() ??
                                              'Pengumuman berhasil diperbarui',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _load();
                                  } else {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result['message']?.toString() ??
                                              'Gagal memperbarui pengumuman',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => isUpdating = false);
                                  }
                                }
                              },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Simpan Perubahan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFB6A00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(dynamic item) async {
    final id = item['id'];
    final judul = (item['judul'] ?? 'pengumuman ini').toString();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: _PanelShell(
          width: 360,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Hapus Pengumuman?',
                      style: TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _closeButton(() => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _textDark,
                    height: 1.35,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Apakah Anda yakin ingin menghapus pengumuman ',
                    ),
                    TextSpan(
                      text: '"$judul"',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(fontSize: 12.5, color: _textLight),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textDark,
                      side: const BorderSide(color: Color(0xFFE1E6EE)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        navigator.pop();
                        final result = await PengumumanService.deletePengumuman(
                          id,
                        );

                        if (!mounted) return;

                        if (result['status'] == 'success') {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message']?.toString() ??
                                    'Pengumuman berhasil dihapus',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _load();
                        } else {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message']?.toString() ??
                                    'Gagal menghapus pengumuman',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Ya, Hapus'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    bool alignTop = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFADB5C2), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE4F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE4F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryPurple, width: 1.2),
      ),
      contentPadding: EdgeInsets.fromLTRB(
        14,
        alignTop ? 14 : 12,
        14,
        alignTop ? 14 : 12,
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: _textDark,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF9AA4B6),
          ),
          style: const TextStyle(color: _textDark, fontSize: 13),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
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
      const months = [
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
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Pengumuman',
                _items.length.toString(),
                const Color(0xFF7C3AED).withValues(alpha: 0.08),
                const Color(0xFFF6F0FF),
                icon: Icons.campaign_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Diterbitkan',
                _items.length.toString(),
                const Color(0xFF17BF63).withValues(alpha: 0.08),
                const Color(0xFFF0FFF3),
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Draft',
                '0',
                const Color(0xFF6B7280).withValues(alpha: 0.06),
                const Color(0xFFF7F7F8),
                icon: Icons.edit_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Dijadwalkan',
                '0',
                const Color(0xFF2E7BEF).withValues(alpha: 0.06),
                const Color(0xFFF0F5FF),
                icon: Icons.schedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, size: 18, color: Color(0xFF9AA3B2)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cari pengumuman berdasarkan judul atau isi...',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Color(0xFFA0A9B7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Semua Kategori',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Color(0xFF667287)),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: Color(0xFF9AA3B2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Semua Status',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Color(0xFF667287)),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: Color(0xFF9AA3B2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textDark,
                  side: const BorderSide(color: Color(0xFFE1E6EE)),
                ),
              ),
            ],
          ),
        ),
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
                const Padding(
                  padding: EdgeInsets.all(20),
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
                      ..._items.map((item) => _buildTableRow(item)),
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
    Color bgColor, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
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
          ),
          if (icon != null)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            'PENGUMUMAN',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            'KATEGORI',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            'TARGET',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'TANGGAL',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            'STATUS',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            'AKSI',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(dynamic item) {
    final judul = (item['judul'] ?? 'N/A').toString();
    final isi = (item['isi'] ?? '').toString();
    final createdAt = (item['created_at'] ?? '').toString();

    final kategori = (item['kategori'] ?? 'Umum').toString();
    final target = (item['target'] ?? 'Semua').toString();
    final status = (item['status'] ?? 'Diterbitkan').toString();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.campaign_outlined,
                      color: Color(0xFFF0B429),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        judul,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _truncateText(isi, 120),
                  style: const TextStyle(fontSize: 12, color: _textLight),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _tableChip(
                kategori,
                const Color(0xFFF0F5FF),
                const Color(0xFF325CCF),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _tableChip(
                target,
                const Color(0xFFFFF3E8),
                const Color(0xFFB45309),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(fontSize: 12, color: _textLight),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Publish: -',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9AA4B6)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _tableChip(
                status,
                const Color(0xFFDCFCE7),
                const Color(0xFF15803D),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionButton(
                      icon: Icons.remove_red_eye,
                      color: const Color(0xFF2B58E8),
                      onPressed: () => _showDetailModal(item),
                    ),
                    const SizedBox(width: 4),
                    _actionButton(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFFFB6A00),
                      onPressed: () => _showEditModal(item),
                    ),
                    const SizedBox(width: 4),
                    _actionButton(
                      icon: Icons.delete_outline,
                      color: const Color(0xFFEF4444),
                      onPressed: () => _showDeleteConfirmation(item),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _tableChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _closeButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: const Padding(
        padding: EdgeInsets.all(2),
        child: Icon(Icons.close, size: 16, color: Color(0xFF6B7280)),
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  final double width;
  final EdgeInsets padding;
  final Widget child;

  const _PanelShell({
    required this.width,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: BoxConstraints(maxWidth: width),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ModalChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final IconData? icon;

  const _ModalChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailInfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF667287),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF667287)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E2A3E),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
