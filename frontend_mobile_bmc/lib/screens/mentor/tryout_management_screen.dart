import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/models/mentor_competition_item.dart';
import 'package:frontend_mobile_bmc/screens/mentor/add_tryout_screen.dart';
import 'package:frontend_mobile_bmc/screens/mentor/tryout_question_management_screen.dart';
import 'package:frontend_mobile_bmc/services/mentor_competition_service.dart';

class TryoutManagementScreen extends StatefulWidget {
  const TryoutManagementScreen({super.key});

  @override
  State<TryoutManagementScreen> createState() => _TryoutManagementScreenState();
}

class _TryoutManagementScreenState extends State<TryoutManagementScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFD1D5DB);
  static const Color _accent = Color(0xFF2563EB);

  final TextEditingController _searchController = TextEditingController();
  String _kelasFilter = 'Semua Kelas';
  bool _isLoading = true;
  List<MentorCompetitionItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await MentorCompetitionService.getByType('tryout');
      if (!mounted) return;
      setState(() {
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
      ).showSnackBar(SnackBar(content: Text('Gagal memuat try out: $e')));
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openCreate() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddTryoutScreen()));
    await _load();
  }

  Future<void> _openEdit(MentorCompetitionItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTryoutScreen(initialItem: item)),
    );
    await _load();
  }

  Future<void> _openManageQuestions(MentorCompetitionItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TryoutQuestionManagementScreen(item: item),
      ),
    );
    await _load();
  }

  Future<void> _deleteItem(MentorCompetitionItem item) async {
    try {
      await MentorCompetitionService.deleteById(item.id, type: 'tryout');
      await _load();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus try out: $e')));
    }
  }

  List<MentorCompetitionItem> get _visibleItems {
    final keyword = _searchController.text.trim().toLowerCase();
    return _items.where((e) {
      final kelasMatch =
          _kelasFilter == 'Semua Kelas' || e.classLevel == _kelasFilter;
      final keywordMatch =
          keyword.isEmpty || e.title.toLowerCase().contains(keyword);
      return kelasMatch && keywordMatch;
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
            children: options
                .map(
                  (e) => ListTile(
                    title: Text(e),
                    onTap: () => Navigator.of(context).pop(e),
                  ),
                )
                .toList(),
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

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              color: Colors.white,
              child: Row(
                children: const [
                  Icon(Icons.menu, size: 20),
                  SizedBox(width: 10),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF4F46E5),
                    child: Text(
                      'M',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.notifications_none_outlined, size: 20),
                  SizedBox(width: 10),
                  Icon(Icons.person_outline, size: 20),
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
                          'Kelola Try Out',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Buat dan kelola try out untuk siswa',
                          style: TextStyle(color: _textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 34,
                                child: OutlinedButton(
                                  onPressed: _chooseKelas,
                                  child: Text(_kelasFilter),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Cari try out...',
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 18,
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: _border,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 30,
                                height: 30,
                                child: ElevatedButton(
                                  onPressed: _openCreate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (visibleItems.isEmpty)
                          const Text(
                            'Belum ada try out. Tekan tombol + untuk membuat.',
                            style: TextStyle(color: _textMuted),
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

  Widget _itemCard(MentorCompetitionItem item) {
    final created = item.createdAt;
    final createdLabel =
        '${created.day.toString().padLeft(2, '0')}/${created.month.toString().padLeft(2, '0')}/${created.year}';
    final totalMade = item.categoryQuestions.values.fold<int>(
      0,
      (sum, e) => sum + e,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.isPublished ? 'Published' : 'Draft',
                  style: const TextStyle(color: _textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.classLevel,
            style: const TextStyle(
              color: Color(0xFF4338CA),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$createdLabel • ${item.durationLabel} menit • ${item.totalQuestions} soal',
            style: const TextStyle(color: _textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
            'Progress Soal',
            style: TextStyle(color: _textMuted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: item.totalQuestions <= 0
                ? 0
                : (totalMade / item.totalQuestions).clamp(0, 1),
            minHeight: 6,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: item.categoryQuestions.entries
                .map(
                  (e) => Text(
                    '${e.key} (${e.value}/${e.value})',
                    style: const TextStyle(fontSize: 11, color: _textMuted),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openManageQuestions(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    minimumSize: const Size(0, 34),
                  ),
                  icon: const Icon(
                    Icons.format_list_bulleted,
                    size: 15,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Kelola Soal',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _openEdit(item),
                icon: const Icon(Icons.edit_outlined, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF9FAFB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: _border),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _deleteItem(item),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF9FAFB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
}
