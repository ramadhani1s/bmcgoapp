import 'package:flutter/material.dart';
import '../../services/paket_les_service.dart';

class PaketLesScreen extends StatefulWidget {
  const PaketLesScreen({super.key});

  @override
  State<PaketLesScreen> createState() => _PaketLesScreenState();
}

class _PaketLesScreenState extends State<PaketLesScreen> {
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFDDE4F0);
  static const Color _textDark = Color(0xFF1E2A3E);
  static const Color _textMuted = Color(0xFF7B8798);

  List<Map<String, dynamic>> paketList = [];
  bool isLoading = true;
  String selectedStatus = 'aktif';
  String _searchText = '';
  String _selectedKategori = 'Semua Kategori';
  String _selectedStatusFilter = 'Semua Status';

  final TextEditingController _searchController = TextEditingController();

  static const List<String> _kategoriOptions = [
    'Semua Kategori',
    'Reguler',
    'Premium',
    'Intensif',
  ];

  static const List<String> _statusOptions = [
    'Semua Status',
    'Aktif',
    'Nonaktif',
  ];

  // Form Controllers
  final namaController = TextEditingController();
  final deskripsiController = TextEditingController();
  final hargaController = TextEditingController();
  final diskonController = TextEditingController();
  final durasiController = TextEditingController();

  DateTime? tanggalMulaiPromo;
  DateTime? tanggalSelesaiPromo;

  @override
  void initState() {
    super.initState();
    _loadPaketList();
  }

  Future<void> _loadPaketList() async {
    setState(() => isLoading = true);
    try {
      final list = await PaketLesService.getPaketLesList();
      if (mounted) {
        setState(() {
          paketList = list;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading paket: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _clearControllers() {
    namaController.clear();
    deskripsiController.clear();
    hargaController.clear();
    diskonController.clear();
    durasiController.clear();
    tanggalMulaiPromo = null;
    tanggalSelesaiPromo = null;
    selectedStatus = 'aktif';
  }

  Future<void> _createPaket() async {
    if (namaController.text.isEmpty || hargaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Nama Paket dan Harga wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int? hargaAwal;
    try {
      hargaAwal = int.parse(
        hargaController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Harga harus berupa angka"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (hargaAwal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Harga harus lebih dari 0"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = {
      'nama_paket': namaController.text.trim(),
      'deskripsi': deskripsiController.text.trim(),
      'harga_awal': hargaAwal,
      'diskon':
          int.tryParse(
            diskonController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0,
      'durasi':
          int.tryParse(
            durasiController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0,
      'tanggal_mulai_promo': _formatDateToString(tanggalMulaiPromo),
      'tanggal_selesai_promo': _formatDateToString(tanggalSelesaiPromo),
      'status': selectedStatus,
    };

    debugPrint('CREATE PAKET: $data');

    final result = await PaketLesService.createPaket(data);

    if (mounted) {
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Paket berhasil dibuat"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        _clearControllers();
        _loadPaketList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${result['message'] ?? 'Gagal membuat paket'}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updatePaket(int id) async {
    if (namaController.text.isEmpty || hargaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Nama Paket dan Harga wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int? hargaAwal;
    try {
      hargaAwal = int.parse(
        hargaController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Harga harus berupa angka"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = {
      'nama_paket': namaController.text.trim(),
      'deskripsi': deskripsiController.text.trim(),
      'harga_awal': hargaAwal,
      'diskon':
          int.tryParse(
            diskonController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0,
      'durasi':
          int.tryParse(
            durasiController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0,
      'tanggal_mulai_promo': _formatDateToString(tanggalMulaiPromo),
      'tanggal_selesai_promo': _formatDateToString(tanggalSelesaiPromo),
      'status': selectedStatus,
    };

    final result = await PaketLesService.updatePaket(id, data);

    if (mounted) {
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Paket berhasil diupdate"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        _clearControllers();
        _loadPaketList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${result['message'] ?? 'Gagal update paket'}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePaket(int id) async {
    final result = await PaketLesService.deletePaket(id);

    if (mounted) {
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Paket berhasil dihapus"),
            backgroundColor: Colors.green,
          ),
        );
        _loadPaketList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${result['message'] ?? 'Gagal hapus paket'}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTambahModal() {
    _clearControllers();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("➕ Tambah Paket Les"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nama Paket
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: "Nama Paket",
                  hintText: "Contoh: Kelas 10 SMA - 1 Semester",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Deskripsi
              TextField(
                controller: deskripsiController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Deskripsi",
                  hintText: "Deskripsikan paket les ini",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Durasi
              TextField(
                controller: durasiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Durasi (Semester)",
                  hintText: "Contoh: 1, 2, 3",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Harga Awal
              TextField(
                controller: hargaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Harga Awal (Rp)",
                  hintText: "Contoh: 4250000",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Diskon
              TextField(
                controller: diskonController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Diskon (%)",
                  hintText: "Contoh: 5, 10, 15",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Tanggal Mulai Promo
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tanggalMulaiPromo ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => tanggalMulaiPromo = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateForDisplay(
                          tanggalMulaiPromo,
                          "Pilih Tanggal Mulai Promo",
                          "Mulai",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tanggal Selesai Promo
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tanggalSelesaiPromo ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => tanggalSelesaiPromo = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateForDisplay(
                          tanggalSelesaiPromo,
                          "Pilih Tanggal Selesai Promo",
                          "Selesai",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                items: [
                  const DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                  const DropdownMenuItem(
                    value: 'nonaktif',
                    child: Text('Nonaktif'),
                  ),
                ].cast<DropdownMenuItem<String>>(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedStatus = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: "Status",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(onPressed: _createPaket, child: const Text("Simpan")),
        ],
      ),
    );
  }

  void _showEditModal(Map<String, dynamic> paket) {
    _clearControllers();
    namaController.text = paket['nama_paket'] ?? '';
    deskripsiController.text = paket['deskripsi'] ?? '';
    hargaController.text = paket['harga_awal'].toString();
    diskonController.text = (paket['diskon'] ?? 0).toString();
    durasiController.text = (paket['durasi'] ?? 0).toString();
    selectedStatus = paket['status'] ?? 'aktif';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("✏️ Edit Paket Les"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: "Nama Paket",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deskripsiController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Deskripsi",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durasiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Durasi (Semester)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hargaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Harga Awal (Rp)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: diskonController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Diskon (%)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                  DropdownMenuItem(value: 'nonaktif', child: Text('Nonaktif')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedStatus = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: "Status",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => _updatePaket(paket['id']),
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🗑️ Hapus Paket Les"),
        content: const Text("Apakah Anda yakin ingin menghapus paket ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePaket(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDetailModal(Map<String, dynamic> paket) {
    final hargaAwal = paket['harga_awal'] as int? ?? 0;
    final diskon = paket['diskon'] as int? ?? 0;
    final hargaSetelahDiskon = (hargaAwal * (100 - diskon) ~/ 100).toInt();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Paket Les'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paket['nama_paket']?.toString() ?? '-',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                paket['deskripsi']?.toString() ?? '-',
                style: const TextStyle(color: Color(0xFF667287)),
              ),
              const SizedBox(height: 14),
              Text('Harga: ${_formatCurrency(hargaAwal)}'),
              const SizedBox(height: 6),
              Text('Diskon: $diskon%'),
              const SizedBox(height: 6),
              Text('Harga Promo: ${_formatCurrency(hargaSetelahDiskon)}'),
              const SizedBox(height: 6),
              Text('Durasi: ${paket['durasi'] ?? 0} semester'),
              const SizedBox(height: 6),
              Text('Status: ${(paket['status'] ?? '-').toString()}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int value) {
    return 'Rp${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match.group(1)}.')}';
  }

  // Format DateTime to YYYY-MM-DD string
  String _formatDateToString(DateTime? date) {
    if (date == null) {
      return '';
    }

    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatDateForDisplay(
    DateTime? date,
    String placeholder,
    String prefix,
  ) {
    if (date == null) {
      return placeholder;
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$prefix: $day/$month/$year';
  }

  List<Map<String, dynamic>> _filteredPaketList() {
    return paketList.where((paket) {
      final name = (paket['nama_paket'] ?? '').toString().toLowerCase();
      final desc = (paket['deskripsi'] ?? '').toString().toLowerCase();
      final status = (paket['status'] ?? '').toString().toLowerCase();

      final matchesSearch =
          _searchText.isEmpty ||
          name.contains(_searchText.toLowerCase()) ||
          desc.contains(_searchText.toLowerCase());

      final paketKategori = _detectKategori(paket);
      final matchesKategori =
          _selectedKategori == 'Semua Kategori' || paketKategori == _selectedKategori;

      final matchesStatus =
          _selectedStatusFilter == 'Semua Status' ||
          (_selectedStatusFilter == 'Aktif' && status == 'aktif') ||
          (_selectedStatusFilter == 'Nonaktif' && status == 'nonaktif');

      return matchesSearch && matchesKategori && matchesStatus;
    }).toList();
  }

  String _detectKategori(Map<String, dynamic> paket) {
    final source = '${paket['nama_paket'] ?? ''} ${paket['deskripsi'] ?? ''}'.toLowerCase();
    if (source.contains('premium')) return 'Premium';
    if (source.contains('intensif')) return 'Intensif';
    return 'Reguler';
  }

  String _detectJenjang(Map<String, dynamic> paket) {
    final source = (paket['nama_paket'] ?? '').toString().toUpperCase();
    if (source.contains('UTBK')) return 'UTBK';
    if (source.contains('SMA')) return 'SMA';
    if (source.contains('SMP')) return 'SMP';
    return 'SMA';
  }

  int _semesterCount(Map<String, dynamic> paket) {
    final source = (paket['nama_paket'] ?? '').toString().toLowerCase();
    final match = RegExp(r'(\d+)\s*semester').firstMatch(source);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 1;
    }
    return 1;
  }

  int _sessionMinutes(Map<String, dynamic> paket) {
    final raw = paket['durasi_menit'];
    if (raw is int && raw > 0) return raw;
    return _detectKategori(paket) == 'Intensif' ? 180 : 120;
  }

  int _sessionsTotal(Map<String, dynamic> paket) {
    final raw = paket['jumlah_sesi'];
    if (raw is int && raw > 0) return raw;
    return _semesterCount(paket) * 72;
  }

  Color _headerColorFor(Map<String, dynamic> paket, int index) {
    final kategori = _detectKategori(paket);
    if (kategori == 'Premium') return const Color(0xFF7E22CE);
    if (kategori == 'Intensif') return const Color(0xFFEA580C);
    const palette = [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF3B82F6)];
    return palette[index % palette.length];
  }

  int _registeredCount(Map<String, dynamic> paket, int index) {
    final raw = paket['jumlah_siswa'] ?? paket['total_siswa'] ?? paket['siswa_terdaftar'];
    if (raw is int) return raw;
    return 6 + (index % 5);
  }

  int _capacityCount(Map<String, dynamic> paket, int index) {
    final raw = paket['kapasitas'] ?? paket['max_siswa'];
    if (raw is int && raw > 0) return raw;
    return 10;
  }

  String _shortDateLabel(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';
    try {
      final dt = DateTime.parse(value.toString());
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
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return value.toString();
    }
  }

  int _totalSiswaCount() {
    return paketList.fold<int>(0, (sum, p) => sum + _registeredCount(p, sum));
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required String value,
    required Color tone,
    required Color iconBg,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 98),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: _textMuted)),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: _textMuted),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _headerChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        if (narrow) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchText = value),
                  style: const TextStyle(fontSize: 12),
                  decoration: _filterDecoration(
                    hintText: 'Cari paket berdasarkan nama, deskripsi, atau kelas...',
                    withSearchIcon: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedKategori,
                        items: _kategoriOptions
                            .map((item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item, style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedKategori = value);
                        },
                        decoration: _filterDecoration(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedStatusFilter,
                        items: _statusOptions
                            .map((item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item, style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedStatusFilter = value);
                        },
                        decoration: _filterDecoration(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _resetFilter,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(82, 38),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.filter_alt_outlined, size: 14, color: _textDark),
                      label: const Text('Reset', style: TextStyle(fontSize: 12, color: _textDark)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchText = value),
                  style: const TextStyle(fontSize: 12),
                  decoration: _filterDecoration(
                    hintText: 'Cari paket berdasarkan nama, deskripsi, atau kelas...',
                    withSearchIcon: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 155,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedKategori,
                  items: _kategoriOptions
                      .map((item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedKategori = value);
                  },
                  decoration: _filterDecoration(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 135,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatusFilter,
                  items: _statusOptions
                      .map((item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedStatusFilter = value);
                  },
                  decoration: _filterDecoration(),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _resetFilter,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(84, 38),
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.filter_alt_outlined, size: 14, color: _textDark),
                label: const Text('Reset', style: TextStyle(fontSize: 12, color: _textDark)),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _filterDecoration({String? hintText, bool withSearchIcon = false}) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 12, color: _textMuted),
      prefixIcon: withSearchIcon
          ? const Icon(Icons.search, size: 16, color: _textMuted)
          : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  void _resetFilter() {
    setState(() {
      _searchController.clear();
      _searchText = '';
      _selectedKategori = 'Semua Kategori';
      _selectedStatusFilter = 'Semua Status';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredList = _filteredPaketList();
    final totalPaket = paketList.length;
    final paketAktif = paketList.where((p) => (p['status'] ?? '').toString() == 'aktif').length;
    final totalSiswa = _totalSiswaCount();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Kelola Paket Les',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Buat dan kelola paket bimbingan belajar BMC',
                      style: TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showTambahModal,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Paket Les'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(146, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Paket',
                  subtitle: 'Semua paket les',
                  value: '$totalPaket',
                  tone: const Color(0xFF2563EB),
                  iconBg: const Color(0xFF2563EB),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  title: 'Paket Aktif',
                  subtitle: 'Dapat dipilih siswa',
                  value: '$paketAktif',
                  tone: const Color(0xFF22C55E),
                  iconBg: const Color(0xFF16A34A),
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Siswa',
                  subtitle: 'Terdaftar di paket',
                  value: '$totalSiswa',
                  tone: const Color(0xFFA855F7),
                  iconBg: const Color(0xFF9333EA),
                  icon: Icons.groups_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _buildFilterBar(),
          const SizedBox(height: 12),

          if (filteredList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 38),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.school_outlined, size: 54, color: Color(0xFFB6C2D3)),
                  SizedBox(height: 10),
                  Text('Belum ada paket les', style: TextStyle(color: _textMuted)),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 14,
                childAspectRatio: 0.64,
              ),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final paket = filteredList[index];
                final hargaAwal = paket['harga_awal'] as int? ?? 0;
                final diskon = paket['diskon'] as int? ?? 0;
                final hargaSetelahDiskon = (hargaAwal * (100 - diskon) ~/ 100).toInt();
                final kategori = _detectKategori(paket);
                final jenjang = _detectJenjang(paket);
                final headerColor = _headerColorFor(paket, index);
                final registered = _registeredCount(paket, index);
                final capacity = _capacityCount(paket, index);
                final progress = capacity == 0 ? 0.0 : (registered / capacity).clamp(0.0, 1.0);
                final createdAt = _shortDateLabel(paket['created_at']);
                final period = '${_shortDateLabel(paket['tanggal_mulai_promo'])} - ${_shortDateLabel(paket['tanggal_selesai_promo'])}';

                return Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: headerColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _headerChip(kategori),
                                const SizedBox(width: 6),
                                _headerChip(jenjang),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              paket['nama_paket']?.toString() ?? '-',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.25,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              paket['deskripsi']?.toString() ?? '-',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFEAF0FF),
                                fontSize: 10,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatCurrency(diskon > 0 ? hargaSetelahDiskon : hargaAwal),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      period,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10, color: _textMuted),
                                    ),
                                  ),
                                ],
                              ),
                              if (diskon > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    '${_formatCurrency(hargaAwal)} sebelum diskon $diskon%',
                                    style: const TextStyle(fontSize: 10, color: _textMuted),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_sessionMinutes(paket)} menit/sesi',
                                      style: const TextStyle(fontSize: 10, color: _textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '3x/minggu',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10, color: _textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${_sessionsTotal(paket)} sesi',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 10, color: _textMuted),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Siswa terdaftar', style: TextStyle(fontSize: 10, color: _textMuted)),
                                  const Spacer(),
                                  Text(
                                    '$registered/$capacity',
                                    style: const TextStyle(fontSize: 10, color: _textDark, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFE9EFF8),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progress > 0.85 ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _chip('Matematika', const Color(0xFF4B5563)),
                                  _chip('Fisika', const Color(0xFF4B5563)),
                                  _chip('Kimia', const Color(0xFF4B5563)),
                                  _chip('+2', const Color(0xFF4B5563)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _chip(
                                    (paket['status'] ?? 'aktif').toString().toLowerCase() == 'aktif'
                                        ? 'Aktif'
                                        : 'Nonaktif',
                                    (paket['status'] ?? 'aktif').toString().toLowerCase() == 'aktif'
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFB91C1C),
                                  ),
                                  const Spacer(),
                                  Text('Dibuat: $createdAt', style: const TextStyle(fontSize: 10, color: _textMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showDetailModal(paket),
                                icon: const Icon(Icons.visibility_outlined, size: 14),
                                label: const Text('Detail'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 30),
                                  side: const BorderSide(color: _border),
                                  foregroundColor: _textDark,
                                  textStyle: const TextStyle(fontSize: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton(
                              onPressed: () => _showEditModal(paket),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(32, 30),
                                side: const BorderSide(color: _border),
                                padding: EdgeInsets.zero,
                                foregroundColor: _textDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Icon(Icons.edit_outlined, size: 14),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton(
                              onPressed: () => _showDeleteDialog(paket['id']),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(32, 30),
                                side: const BorderSide(color: Color(0xFFFCCACA)),
                                padding: EdgeInsets.zero,
                                foregroundColor: const Color(0xFFDC2626),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Icon(Icons.delete_outline, size: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    namaController.dispose();
    deskripsiController.dispose();
    hargaController.dispose();
    diskonController.dispose();
    durasiController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
