import 'package:flutter/material.dart';

import '../../models/mentor_competition_item.dart';
import '../../services/mentor_competition_service.dart';

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

  final List<String> _kelasOptions = const ['Kelas 10', 'Kelas 11', 'Kelas 12'];
  final List<String> _mapelOptions = const [
    'Matematika',
    'Fisika',
    'Kimia',
    'Biologi',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Try Out Online',
    'Olimpiade Akademik',
  ];

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
      final subjectMatch =
          _mapelFilter == 'Semua Mapel' || e.subject == _mapelFilter;
      final keywordMatch =
          keyword.isEmpty || e.title.toLowerCase().contains(keyword);
      return kelasMatch && subjectMatch && keywordMatch;
    }).toList();
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
    final selected = await _chooseFromSheet([
      'Semua Status',
      'Dipublikasi',
      'Draft',
    ]);
    if (selected == null || !mounted) return;
    setState(() => _statusFilter = selected);
  }

  Future<String?> _chooseFromSheet(List<String> options) async {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (label) => ListTile(
                  title: Text(label),
                  onTap: () => Navigator.of(context).pop(label),
                ),
              )
              .toList(),
        ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Proses selesai'),
      ),
    );
    if (result['success'] == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Cari data...',
                        ),
                      ),
                      const SizedBox(height: 12),
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
                            child: OutlinedButton(
                              onPressed: _chooseStatus,
                              child: Text(_statusFilter),
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
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Baru'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (visibleItems.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Belum ada data'),
                    ),
                  )
                else
                  ...visibleItems.map(
                    (item) => Card(
                      child: ListTile(
                        title: Text(item.title),
                        subtitle: Text('${item.classLevel} • ${item.subject}'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              onPressed: () => _openForm(item: item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () => _deleteItem(item),
                              icon: const Icon(Icons.delete_outline),
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
  final _durationController = TextEditingController();
  final _questionsController = TextEditingController(text: '0');
  final _classOptions = const ['Kelas 10', 'Kelas 11', 'Kelas 12'];
  final _mapelOptions = const [
    'Matematika',
    'Fisika',
    'Kimia',
    'Biologi',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Try Out Online',
    'Olimpiade Akademik',
  ];
  String _classLevel = 'Kelas 12';
  String _subject = 'Matematika';
  bool _saving = false;

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
      _subject = item.subject;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scheduleController.dispose();
    _durationController.dispose();
    _questionsController.dispose();
    super.dispose();
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
                value: _classLevel,
                items: _classOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _classLevel = v ?? _classLevel),
                decoration: const InputDecoration(labelText: 'Kelas'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _subject,
                items: _mapelOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _subject = v ?? _subject),
                decoration: const InputDecoration(
                  labelText: 'Mapel / Keterangan',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _scheduleController,
                decoration: const InputDecoration(labelText: 'Tanggal'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Durasi / Info'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _questionsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Soal'),
              ),
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
                  setState(() => _saving = true);
                  final response =
                      await MentorCompetitionService.createOrUpdate(
                        type: widget.type,
                        id: widget.initialItem?.id,
                        classLevel: _classLevel,
                        title: _titleController.text.trim(),
                        subject: _subject,
                        scheduleLabel: _scheduleController.text.trim(),
                        durationLabel: _durationController.text.trim(),
                        totalQuestions:
                            int.tryParse(_questionsController.text.trim()) ?? 0,
                      );
                  if (!mounted) return;
                  setState(() => _saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response['message']?.toString() ?? 'Proses selesai',
                      ),
                    ),
                  );
                  if (response['success'] == true) {
                    widget.onSaved();
                    Navigator.of(context).pop(true);
                  }
                },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
