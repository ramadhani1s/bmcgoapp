import 'package:flutter/material.dart';

import '../../models/mentor_competition_item.dart';
import '../../services/mentor_competition_service.dart';
import '../mentor/tryout_soal_management_screen.dart';
import '../mentor/olimpiade_soal_management_screen.dart';

class MentorCompetitionManagement extends StatefulWidget {
  final String type;
  final String title;
  final String subtitle;
  final Color accentColor;

  const MentorCompetitionManagement({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  State<MentorCompetitionManagement> createState() =>
      _MentorCompetitionManagementState();
}

class _MentorCompetitionManagementState
    extends State<MentorCompetitionManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _kelasFilter = 'Semua Kelas';
  String _statusFilter = 'Semua Status';
  String _mapelFilter = 'Semua Mapel';
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
    setState(() => _isLoading = true);
    final items = await MentorCompetitionService.getByType(widget.type);
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  List<MentorCompetitionItem> get _visibleItems {
    final keyword = _searchController.text.trim().toLowerCase();
    return _items.where((e) {
      final kelasMatch =
          _kelasFilter == 'Semua Kelas' || e.classLevel == _kelasFilter;
      final statusMatch =
          _statusFilter == 'Semua Status' ||
          (_statusFilter == 'Dipublikasi' && e.isPublished) ||
          (_statusFilter == 'Draft' && !e.isPublished);
      final subjectMatch =
          _mapelFilter == 'Semua Mapel' || e.subject == _mapelFilter;
      final keywordMatch =
          keyword.isEmpty || e.title.toLowerCase().contains(keyword);
      return kelasMatch && statusMatch && subjectMatch && keywordMatch;
    }).toList();
  }

  String get _pageTag => widget.type == 'tryout' ? 'Try Out' : 'Olimpiade';

  List<MentorCompetitionItem> get _publishedItems =>
      _items.where((item) => item.isPublished).toList();

  Widget _buildTryoutCard(MentorCompetitionItem item) {
    final categories = item.categoryQuestions;
    final total = item.totalQuestions > 0
        ? item.totalQuestions
        : categories.values.fold<int>(
            0,
            (previousValue, element) => previousValue + element,
          );
    final completed = 0;
    final progress = total <= 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

    final shortCategories = <MapEntry<String, String>>[
      const MapEntry('PU', 'Penalaran Umum'),
      const MapEntry('PPU', 'Pemahaman dan Penulisan Umum'),
      const MapEntry('PBM', 'Pengetahuan dan Pemahaman Bacaan Matematika'),
      const MapEntry('PK', 'Pengetahuan Kuantitatif'),
      const MapEntry('PM', 'Penalaran Matematika'),
      const MapEntry('Literasi', 'Literasi Bahasa Indonesia'),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: item.isPublished
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.isPublished ? 'Dipublikasikan' : 'Draft',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Text(
                  item.scheduleLabel.isEmpty ? '-' : item.scheduleLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Text(
                  '${item.durationLabel} menit',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '0/$total soal',
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Progress Soal',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: shortCategories.map((entry) {
              final value = categories[entry.value] ?? 0;
              return IntrinsicWidth(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.key,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '0/$value',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openTryoutSoalManagement(item),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_outlined, size: 16),
                  label: const Text(
                    'Kelola Soal',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: OutlinedButton(
                  onPressed: () => _openForm(item: item),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9FAFB),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 40,
                height: 40,
                child: OutlinedButton(
                  onPressed: () => _deleteItem(item),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF1F2),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOlimpiadCard(MentorCompetitionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF0EA5E9),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: item.isPublished
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.isPublished ? 'Dipublikasikan' : 'Draft',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                item.classLevel,
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Text(
                  item.scheduleLabel.isEmpty ? '-' : item.scheduleLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (item.subject.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  item.subject,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openOlimpiadseSoalManagement(item),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_outlined, size: 16),
                  label: const Text(
                    'Kelola Soal',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: OutlinedButton(
                  onPressed: () => _openForm(item: item),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 40,
                height: 40,
                child: OutlinedButton(
                  onPressed: () => _deleteItem(item),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _chooseKelas() async {
    final selected = await _chooseFromSheet([
      'Semua Kelas',
      ..._items.map((e) => e.classLevel).toSet(),
    ]);
    if (selected == null || !mounted) return;
    setState(() => _kelasFilter = selected);
  }

  Future<void> _chooseMapel() async {
    final selected = await _chooseFromSheet([
      'Semua Mapel',
      ..._items.map((e) => e.subject).toSet(),
    ]);
    if (selected == null || !mounted) return;
    setState(() => _mapelFilter = selected);
  }

  Future<void> _chooseStatus() async {
    final selected = await _chooseFromSheet(['Semua Status', 'Dipublikasi']);
    if (selected == null || !mounted) return;
    setState(() => _statusFilter = selected);
  }

  Future<String?> _chooseFromSheet(List<String> options) async {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Options
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: options.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 12, color: Color(0xFFF3F4F6)),
                itemBuilder: (context, index) {
                  final label = options[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(label),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTryoutSoalManagement(MentorCompetitionItem tryout) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TryoutSoalManagementScreen(tryout: tryout),
      ),
    );
  }

  Future<void> _openOlimpiadseSoalManagement(
    MentorCompetitionItem olimpiade,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            OlimpiadseSoalManagementScreen(olimpiade: olimpiade),
      ),
    );
  }

  Future<void> _openForm({MentorCompetitionItem? item}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _CompetitionFormDialog(
        type: widget.type,
        accentColor: widget.accentColor,
        initialItem: item,
        onSaved: _load,
      ),
    );

    if (result == true) {
      await _load();
    }
  }

  Future<void> _deleteItem(MentorCompetitionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus data?'),
        content: Text('Yakin hapus ${item.title}?'),
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
      ),
    );

    if (confirmed != true) return;

    final result = await MentorCompetitionService.deleteById(
      widget.type,
      item.id,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Proses selesai'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    if (result['success'] == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;
    final isTryout = widget.type == 'tryout';
    final totalItems = _items.length;
    final publishedCount = _publishedItems.length;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accentColor.withOpacity(0.12),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pageTag,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.accentColor,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kelola data ${widget.type == 'tryout' ? 'try out' : 'olimpiade'} dengan alur yang rapi, cepat, dan konsisten.',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatChip(
                            label: 'Total Data',
                            value: totalItems.toString(),
                            icon: Icons.dataset_outlined,
                            color: widget.accentColor,
                          ),
                          _StatChip(
                            label: 'Publish',
                            value: publishedCount.toString(),
                            icon: Icons.verified_outlined,
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: isTryout
                                    ? 'Cari try out...'
                                    : 'Cari data...',
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: widget.accentColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 156,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () => _openForm(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                'Tambah Baru',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isTryout) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _chooseKelas,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: widget.accentColor,
                                  side: BorderSide(color: widget.accentColor),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.school_outlined,
                                  size: 18,
                                ),
                                label: Text(_kelasFilter),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _chooseStatus,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: widget.accentColor,
                                  side: BorderSide(color: widget.accentColor),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.verified_outlined,
                                  size: 18,
                                ),
                                label: Text(_statusFilter),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _chooseMapel,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: widget.accentColor,
                                  side: BorderSide(color: widget.accentColor),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.menu_book_outlined,
                                  size: 18,
                                ),
                                label: Text(_mapelFilter),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Daftar ${_pageTag.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                if (visibleItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Text('Belum ada data'),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int columns = 4;
                      final w = constraints.maxWidth;
                      if (w < 600) {
                        columns = 1;
                      } else if (w < 900) {
                        columns = 2;
                      } else if (w < 1200) {
                        columns = 3;
                      } else {
                        columns = 4;
                      }

                      final itemWidth = (w - (columns - 1) * 12) / columns;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: visibleItems.map((item) {
                          return SizedBox(
                            width: itemWidth,
                            child: isTryout
                                ? _buildTryoutCard(item)
                                : _buildOlimpiadCard(item),
                          );
                        }).toList(),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompetitionFormDialog extends StatefulWidget {
  final String type;
  final Color accentColor;
  final MentorCompetitionItem? initialItem;
  final VoidCallback onSaved;

  const _CompetitionFormDialog({
    required this.type,
    required this.accentColor,
    required this.initialItem,
    required this.onSaved,
  });

  @override
  State<_CompetitionFormDialog> createState() => _CompetitionFormDialogState();
}

class _CompetitionFormDialogState extends State<_CompetitionFormDialog> {
  final _titleController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _questionsController = TextEditingController(text: '0');
  final _classOptions = const ['Kelas 10', 'Kelas 11', 'Kelas 12'];
  final Map<String, TextEditingController> _categoryControllers = {
    'Penalaran Umum': TextEditingController(text: '0'),
    'Pemahaman dan Penulisan Umum': TextEditingController(text: '0'),
    'Pengetahuan dan Pemahaman Bacaan Matematika': TextEditingController(
      text: '0',
    ),
    'Pengetahuan Kuantitatif': TextEditingController(text: '0'),
    'Penalaran Matematika': TextEditingController(text: '0'),
    'Literasi Bahasa Indonesia': TextEditingController(text: '0'),
  };
  String _classLevel = 'Kelas 12';
  bool _saving = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_scheduleController.text.trim()) ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) {
      return;
    }

    final yyyy = selected.year.toString().padLeft(4, '0');
    final mm = selected.month.toString().padLeft(2, '0');
    final dd = selected.day.toString().padLeft(2, '0');
    _scheduleController.text = '$yyyy-$mm-$dd';
  }

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _titleController.text = item.title;
      _scheduleController.text = item.scheduleLabel;
      _durationController.text = item.durationLabel;
      _questionsController.text = item.totalQuestions.toString();
      _classLevel = item.classLevel;
      _locationController.text = item.subject == '-' ? '' : item.subject;

      for (final entry in _categoryControllers.entries) {
        final value = item.categoryQuestions[entry.key] ?? 0;
        entry.value.text = value.toString();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scheduleController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _questionsController.dispose();
    for (final c in _categoryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _sumTryoutQuestions() {
    var total = 0;
    for (final controller in _categoryControllers.values) {
      total += int.tryParse(controller.text.trim()) ?? 0;
    }
    return total;
  }

  Map<String, int> _collectCategoryQuestions() {
    final result = <String, int>{};
    for (final entry in _categoryControllers.entries) {
      result[entry.key] = int.tryParse(entry.value.text.trim()) ?? 0;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialItem == null ? 'Tambah Data' : 'Edit Data'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul / Nama'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _classLevel,
                items: _classOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _classLevel = v ?? _classLevel),
                decoration: const InputDecoration(labelText: 'Kelas'),
              ),
              const SizedBox(height: 8),
              if (widget.type == 'olimpiade') ...[
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi',
                    hintText: 'Isi lokasi sesuai kebutuhan mentor',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _scheduleController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Pelaksanaan',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
              ],
              if (widget.type == 'tryout') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _scheduleController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Pelaksanaan',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Waktu (menit)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Latihan Soal',
                  ),
                  child: Text(
                    '${_sumTryoutQuestions()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Jumlah Soal per Kategori',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ..._categoryControllers.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 88,
                          child: TextField(
                            controller: entry.value,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: '0',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
          onPressed: _saving
              ? null
              : () async {
                  if (_titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Judul/Nama wajib diisi'),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 80,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    return;
                  }
                  if (_scheduleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Tanggal wajib dipilih'),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 80,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    return;
                  }
                  if (widget.type == 'olimpiade' &&
                      _locationController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Lokasi wajib diisi'),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 80,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    return;
                  }
                  if (widget.type == 'tryout' &&
                      _durationController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Waktu wajib diisi'),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 80,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  setState(() => _saving = true);
                  final totalQuestions = widget.type == 'tryout'
                      ? _sumTryoutQuestions()
                      : int.tryParse(_questionsController.text.trim()) ?? 0;
                  final response =
                      await MentorCompetitionService.createOrUpdate(
                        type: widget.type,
                        id: widget.initialItem?.id,
                        classLevel: _classLevel,
                        title: _titleController.text.trim(),
                        subject: _locationController.text.trim(),
                        scheduleLabel: _scheduleController.text.trim(),
                        durationLabel: _durationController.text.trim(),
                        totalQuestions: totalQuestions,
                        categoryQuestions: _collectCategoryQuestions(),
                      );
                  if (!mounted) return;
                  setState(() => _saving = false);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        response['message']?.toString() ?? 'Proses selesai',
                      ),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 80,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  if (response['success'] == true) {
                    widget.onSaved();
                    navigator.pop(true);
                  }
                },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
