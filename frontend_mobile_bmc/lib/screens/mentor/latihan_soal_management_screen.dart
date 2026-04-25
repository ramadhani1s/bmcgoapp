import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/models/mentor_latihan_model.dart';
import 'package:frontend_mobile_bmc/screens/mentor/add_latihan_soal_screen.dart';
import 'package:frontend_mobile_bmc/screens/mentor/soal_management_screen.dart';
import 'package:frontend_mobile_bmc/services/mentor_latihan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LatihanSoalManagementScreen extends StatefulWidget {
  const LatihanSoalManagementScreen({super.key});

  @override
  State<LatihanSoalManagementScreen> createState() =>
      _LatihanSoalManagementScreenState();
}

class _LatihanSoalManagementScreenState
    extends State<LatihanSoalManagementScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFD1D5DB);
  static const Color _accent = Color(0xFF2563EB);

  final TextEditingController _searchController = TextEditingController();

  String _profileInitial = 'M';
  bool _isLoading = true;
  String _kelasFilter = 'Semua Kelas';
  String _statusFilter = 'Semua Status';
  String _mapelFilter = 'Semua Mapel';
  List<MentorLatihanModel> _items = const [];

  @override
  void initState() {
    super.initState();
    _initScreen();
    _searchController.addListener(_rebuild);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initScreen() async {
    await Future.wait([_loadProfileInitial(), _loadItems()]);
  }

  Future<void> _loadProfileInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final name = (prefs.getString('user_name') ?? '').trim();
    if (!mounted) {
      return;
    }

    setState(() {
      _profileInitial = name.isEmpty ? 'M' : name[0].toUpperCase();
    });
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    final items = await MentorLatihanService.getAll();
    if (!mounted) {
      return;
    }

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  void _rebuild() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  List<MentorLatihanModel> get _filteredItems {
    final keyword = _searchController.text.trim().toLowerCase();

    return _items.where((item) {
      final kelasMatch =
          _kelasFilter == 'Semua Kelas' || item.kelas == _kelasFilter;
      final statusMatch =
          _statusFilter == 'Semua Status' ||
          (_statusFilter == 'Dipublikasi' && item.isPublished) ||
          (_statusFilter == 'Draft' && !item.isPublished);
      final mapelMatch =
          _mapelFilter == 'Semua Mapel' || item.mapel == _mapelFilter;
      final keywordMatch =
          keyword.isEmpty ||
          item.judul.toLowerCase().contains(keyword) ||
          item.mapel.toLowerCase().contains(keyword);

      return kelasMatch && statusMatch && mapelMatch && keywordMatch;
    }).toList();
  }

  Future<void> _chooseKelas() async {
    final values = ['Semua Kelas', ..._items.map((e) => e.kelas).toSet()];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: values.map(_sheetOption).toList(),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _kelasFilter = selected;
    });
  }

  Future<void> _openCreate() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddLatihanSoalScreen()));
    await _loadItems();
  }

  Future<void> _openEdit(MentorLatihanModel item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddLatihanSoalScreen(initialItem: item),
      ),
    );
    await _loadItems();
  }

  Future<void> _manageSoal(MentorLatihanModel item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SoalManagementScreen(latihan: item)),
    );
  }

  Future<void> _deleteItem(MentorLatihanModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus latihan?'),
          content: Text('Latihan "${item.judul}" akan dihapus.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await MentorLatihanService.deleteById(item.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Latihan dihapus')));
    await _loadItems();
  }

  void _showDetail(MentorLatihanModel item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Kelas: ${item.kelas}'),
                Text('Mapel: ${item.mapel}'),
                Text('Jumlah soal: ${item.jumlahSoal}'),
                Text('Durasi: ${item.durasiMenit} menit'),
                Text('Status: ${item.isPublished ? 'Dipublikasi' : 'Draft'}'),
                if (item.jadwalPelaksanaan.trim().isNotEmpty)
                  Text('Jadwal: ${item.jadwalPelaksanaan}'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _chooseStatus() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetOption('Semua Status'),
              _sheetOption('Dipublikasi'),
              _sheetOption('Draft'),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _statusFilter = selected;
    });
  }

  Future<void> _chooseMapel() async {
    final values = ['Semua Mapel', ..._items.map((e) => e.mapel).toSet()];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: values.map(_sheetOption).toList(),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _mapelFilter = selected;
    });
  }

  Widget _sheetOption(String value) {
    return ListTile(
      title: Text(value),
      onTap: () => Navigator.of(context).pop(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredItems;
    final totalSoal = _items.fold<int>(0, (sum, e) => sum + e.jumlahSoal);
    final publishedCount = _items.where((e) => e.isPublished).length;
    final mapelCount = _items.map((e) => e.mapel).toSet().length;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.menu),
                    visualDensity: VisualDensity.compact,
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF4F46E5),
                    child: Text(
                      _profileInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notifikasi aktif')),
                          );
                        },
                        icon: const Icon(Icons.notifications_none_outlined),
                      ),
                      const Positioned(
                        right: 13,
                        top: 11,
                        child: CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profil mentor')),
                      );
                    },
                    icon: const Icon(Icons.person_outline),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadItems,
                      child: ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          const Text(
                            'Kelola Soal Latihan',
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Buat dan kelola soal latihan untuk siswa Anda',
                            style: TextStyle(color: _textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 1.75,
                            shrinkWrap: true,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _statCard(
                                icon: Icons.description_outlined,
                                iconBg: const Color(0xFFDBEAFE),
                                iconColor: const Color(0xFF2563EB),
                                value: '${_items.length}',
                                label: 'Total Latihan',
                              ),
                              _statCard(
                                icon: Icons.check_circle_outline,
                                iconBg: const Color(0xFFDCFCE7),
                                iconColor: const Color(0xFF16A34A),
                                value: '$publishedCount',
                                label: 'Dipublikasi',
                              ),
                              _statCard(
                                icon: Icons.tag,
                                iconBg: const Color(0xFFFFEDD5),
                                iconColor: const Color(0xFFF97316),
                                value: '$totalSoal',
                                label: 'Total Soal',
                              ),
                              _statCard(
                                icon: Icons.menu_book_outlined,
                                iconBg: const Color(0xFFF3E8FF),
                                iconColor: const Color(0xFF9333EA),
                                value: '$mapelCount',
                                label: 'Mata Pelajaran',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Cari soal latihan...',
                                    prefixIcon: const Icon(Icons.search),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: _border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: _border,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _chooseKelas,
                                        child: Text(_kelasFilter),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _chooseStatus,
                                        icon: const Icon(
                                          Icons.filter_list,
                                          size: 16,
                                        ),
                                        label: Text(_statusFilter),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _chooseMapel,
                                        child: Text(_mapelFilter),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: 44,
                                    height: 34,
                                    child: ElevatedButton(
                                      onPressed: _openCreate,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _accent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (visibleItems.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _border),
                              ),
                              child: const Text(
                                'Belum ada latihan soal. Tekan tombol + untuk membuat latihan baru.',
                                style: TextStyle(color: _textMuted),
                              ),
                            ),
                          for (final item in visibleItems)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _latihanCard(item),
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

  Widget _statCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  color: _textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: _textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _latihanCard(MentorLatihanModel item) {
    final dateLabel =
        '${item.createdAt.day.toString().padLeft(2, '0')}/${item.createdAt.month.toString().padLeft(2, '0')}/${item.createdAt.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip(
                      item.kelas,
                      const Color(0xFFE0E7FF),
                      const Color(0xFF4338CA),
                    ),
                    _chip(
                      item.mapel,
                      const Color(0xFFDBEAFE),
                      const Color(0xFF2563EB),
                    ),
                    _chip(
                      item.isPublished ? 'Dipublikasi' : 'Draft',
                      item.isPublished
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF3F4F6),
                      item.isPublished
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF6B7280),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _infoBox(
                      Icons.description_outlined,
                      '${item.jumlahSoal}',
                      'Soal',
                    ),
                    const SizedBox(width: 8),
                    _infoBox(Icons.access_time, '${item.durasiMenit}', 'Menit'),
                    const SizedBox(width: 8),
                    _infoBox(
                      Icons.calendar_today_outlined,
                      dateLabel,
                      'Dibuat',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'Progress Soal',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      '${item.jumlahSoal}/${item.jumlahSoal} ✓',
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 1,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF22C55E),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    item.jumlahSoal,
                    (index) => Container(
                      width: 40,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      alignment: Alignment.center,
                      child: Text('${index + 1}'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDetail(item),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('Lihat'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _manageSoal(item),
                        icon: const Icon(
                          Icons.format_list_bulleted_outlined,
                          size: 16,
                        ),
                        label: const Text('Kelola'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _openEdit(item),
                      icon: const Icon(Icons.edit_outlined),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF9FAFB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: _border),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => _deleteItem(item),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFEF4444),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF9FAFB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: _border),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _infoBox(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: _textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
