import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/models/mentor_competition_item.dart';
import 'package:frontend_mobile_bmc/screens/mentor/add_olimpiade_screen.dart';
import 'package:frontend_mobile_bmc/services/mentor_competition_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OlimpiadeManagementScreen extends StatefulWidget {
  const OlimpiadeManagementScreen({super.key});

  @override
  State<OlimpiadeManagementScreen> createState() =>
      _OlimpiadeManagementScreenState();
}

class _OlimpiadeManagementScreenState extends State<OlimpiadeManagementScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFD1D5DB);
  static const Color _accent = Color(0xFFD99600);

  final TextEditingController _searchController = TextEditingController();

  String _profileInitial = 'M';
  String _kelasFilter = 'Semua Kelas';
  String _statusFilter = 'Semua Status';
  String _subjectFilter = 'Semua Mapel';
  bool _isLoading = true;
  List<MentorCompetitionItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = (prefs.getString('user_name') ?? '').trim();
      final items = await MentorCompetitionService.getByType('olimpiade');

      if (!mounted) {
        return;
      }

      setState(() {
        _profileInitial = name.isEmpty ? 'M' : name[0].toUpperCase();
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _items = const [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat olimpiade: $e')));
    }
  }

  Future<void> _reloadItems() async {
    try {
      final items = await MentorCompetitionService.getByType('olimpiade');
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal refresh olimpiade: $e')));
    }
  }

  void _refresh() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _openCreate() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddOlimpiadeScreen()));
    await _reloadItems();
  }

  Future<void> _openEdit(MentorCompetitionItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddOlimpiadeScreen(initialItem: item)),
    );
    await _reloadItems();
  }

  Future<void> _deleteItem(MentorCompetitionItem item) async {
    try {
      await MentorCompetitionService.deleteById(item.id, type: 'olimpiade');
      await _reloadItems();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus olimpiade: $e')));
    }
  }

  List<MentorCompetitionItem> get _visibleItems {
    final keyword = _searchController.text.trim().toLowerCase();
    return _items.where((e) {
      final statusMatch =
          _statusFilter == 'Semua Status' ||
          (_statusFilter == 'Dipublikasi' && e.isPublished) ||
          (_statusFilter == 'Draft' && !e.isPublished);
      final kelasMatch =
          _kelasFilter == 'Semua Kelas' || e.classLevel == _kelasFilter;
      final subjectMatch =
          _subjectFilter == 'Semua Mapel' || e.subject == _subjectFilter;
      final keywordMatch =
          keyword.isEmpty ||
          e.title.toLowerCase().contains(keyword) ||
          e.subject.toLowerCase().contains(keyword);
      return kelasMatch && statusMatch && subjectMatch && keywordMatch;
    }).toList();
  }

  Future<void> _chooseKelas() async {
    final options = ['Semua Kelas', ..._items.map((e) => e.classLevel).toSet()];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map(_sheetOption).toList(),
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

  Future<void> _chooseSubject() async {
    final options = ['Semua Mapel', ..._items.map((e) => e.subject).toSet()];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map(_sheetOption).toList(),
          ),
        );
      },
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _subjectFilter = selected;
    });
  }

  Widget _sheetOption(String label) {
    return ListTile(
      title: Text(label),
      onTap: () => Navigator.of(context).pop(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;
    final totalSoal = _items.fold<int>(0, (sum, e) => sum + e.totalQuestions);
    final publishedCount = _items.where((e) => e.isPublished).length;

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
                  const Icon(Icons.menu, size: 20),
                  const SizedBox(width: 10),
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
                  const Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.notifications_none_outlined),
                      ),
                      Positioned(
                        right: 3,
                        top: 4,
                        child: CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.person_outline),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(14),
                      children: [
                        const Text(
                          'Kelola Olimpiade Akademik',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            height: 1.02,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Buat dan kelola event olimpiade akademik untuk siswa',
                          style: TextStyle(color: _textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _statCard(
                              icon: Icons.description_outlined,
                              iconBg: const Color(0xFFDBEAFE),
                              iconColor: const Color(0xFF2563EB),
                              value: '${_items.length}',
                              label: 'Total Olimpiade',
                              width:
                                  (MediaQuery.of(context).size.width - 38) / 2,
                            ),
                            _statCard(
                              icon: Icons.check_circle_outline,
                              iconBg: const Color(0xFFDCFCE7),
                              iconColor: const Color(0xFF16A34A),
                              value: '$publishedCount',
                              label: 'Dipublikasi',
                              width:
                                  (MediaQuery.of(context).size.width - 38) / 2,
                            ),
                            _statCard(
                              icon: Icons.tag,
                              iconBg: const Color(0xFFFFEDD5),
                              iconColor: const Color(0xFFF97316),
                              value: '$totalSoal',
                              label: 'Total Soal',
                              width:
                                  (MediaQuery.of(context).size.width - 38) / 2,
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
                                      onPressed: _chooseSubject,
                                      child: Text(_subjectFilter),
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
                                        borderRadius: BorderRadius.circular(10),
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
                              'Belum ada data olimpiade. Tekan tombol tambah untuk membuat event baru.',
                              style: TextStyle(color: _textMuted),
                            ),
                          ),
                        for (final item in visibleItems)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _itemCard(item),
                          ),
                      ],
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
    required double width,
  }) {
    return Container(
      width: width,
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
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
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

  Widget _itemCard(MentorCompetitionItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _chip(
                item.classLevel,
                const Color(0xFFE0E7FF),
                const Color(0xFF4338CA),
              ),
              _chip(
                item.subject,
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
          Text(
            '${item.totalQuestions} soal • ${item.durationLabel} • ${item.scheduleLabel.isEmpty ? 'Tanpa jadwal' : item.scheduleLabel}',
            style: const TextStyle(color: _textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openEdit(item),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
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
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
