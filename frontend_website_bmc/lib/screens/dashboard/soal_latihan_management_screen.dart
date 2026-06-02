import 'package:flutter/material.dart';
// ignore_for_file: unused_element
import '../../models/latihan.dart';
import '../../models/soal_latihan.dart';
import '../../services/latihan_management_service.dart';
import '../../services/latihan_soal_service.dart';

class SoalLatihanManagementScreen extends StatefulWidget {
  const SoalLatihanManagementScreen({super.key});

  @override
  State<SoalLatihanManagementScreen> createState() =>
      _SoalLatihanManagementScreenState();
}

class _LatihanCreatePage extends StatefulWidget {
  final List<String> mapelOptions;

  const _LatihanCreatePage({required this.mapelOptions});

  @override
  State<_LatihanCreatePage> createState() => _LatihanCreatePageState();
}

class _LatihanCreatePageState extends State<_LatihanCreatePage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _jumlahSoalController = TextEditingController(
    text: '5',
  );
  final TextEditingController _durasiController = TextEditingController(
    text: '20',
  );
  final TextEditingController _jadwalController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  bool _saving = false;
  String _selectedMapel = 'Matematika';

  @override
  void initState() {
    super.initState();
    if (widget.mapelOptions.isNotEmpty &&
        widget.mapelOptions.contains(_selectedMapel)) {
      return;
    }
    if (widget.mapelOptions.isNotEmpty) {
      _selectedMapel = widget.mapelOptions.first;
    }
  }

  List<String> _buildMapelOptions() {
    const defaults = [
      'Matematika',
      'Fisika',
      'Kimia',
      'Biologi',
      'Bahasa Indonesia',
      'Bahasa Inggris',
    ];

    final options = <String>{
      ...defaults,
      ...widget.mapelOptions.where((value) => value != 'Semua Mapel'),
    }.toList();

    return options.isEmpty ? defaults : options;
  }

  @override
  void dispose() {
    _judulController.dispose();
    _jumlahSoalController.dispose();
    _durasiController.dispose();
    _jadwalController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickJadwalDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_jadwalController.text.trim()) ?? now;
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
    setState(() {
      _jadwalController.text = '$yyyy-$mm-$dd';
    });
  }

  Future<void> _submit({required bool publish}) async {
    final title = _judulController.text.trim();
    final totalSoal = int.tryParse(_jumlahSoalController.text.trim()) ?? 1;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul latihan tidak boleh kosong')),
      );
      return;
    }

    if (totalSoal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah soal harus lebih dari 0')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final result = await LatihanManagementService.createLatihan(
        title: title,
        mapel: _selectedMapel,
        totalSoal: totalSoal,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        if (publish && result['data'] is Latihan) {
          final createdLatihan = result['data'] as Latihan;
          await LatihanManagementService.publishLatihan(createdLatihan.id);
          if (!mounted) return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Latihan berhasil disimpan'),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan latihan'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _inputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildInfoCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.16),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu_book_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah Latihan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Isi form di bawah untuk membuat soal latihan',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Isi detail latihan di bawah',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _judulController,
                            decoration: InputDecoration(
                              labelText: 'Judul Latihan',
                              hintText: 'Latihan Matematika Bab 1',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: fieldBorder,
                              enabledBorder: fieldBorder,
                              focusedBorder: fieldBorder.copyWith(
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
                                  width: 1.4,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.title,
                                color: Color(0xFF2563EB),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue:
                                _buildMapelOptions().contains(_selectedMapel)
                                ? _selectedMapel
                                : _buildMapelOptions().first,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                            items: _buildMapelOptions()
                                .map(
                                  (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedMapel = value);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Mata Pelajaran',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: fieldBorder,
                              enabledBorder: fieldBorder,
                              focusedBorder: fieldBorder.copyWith(
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
                                  width: 1.4,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.menu_book_outlined,
                                color: Color(0xFF2563EB),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _jumlahSoalController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Jumlah Soal',
                                    hintText: '5',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: fieldBorder,
                                    enabledBorder: fieldBorder,
                                    focusedBorder: fieldBorder.copyWith(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2563EB),
                                        width: 1.4,
                                      ),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.description_outlined,
                                      color: Color(0xFF2563EB),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _durasiController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Durasi (Menit)',
                                    hintText: '20',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: fieldBorder,
                                    enabledBorder: fieldBorder,
                                    focusedBorder: fieldBorder.copyWith(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2563EB),
                                        width: 1.4,
                                      ),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.timer_outlined,
                                      color: Color(0xFF2563EB),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _jadwalController,
                            readOnly: true,
                            onTap: _pickJadwalDate,
                            decoration: InputDecoration(
                              labelText: 'Jadwal Pelaksanaan',
                              hintText: '30 April 2026',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: fieldBorder,
                              enabledBorder: fieldBorder,
                              focusedBorder: fieldBorder.copyWith(
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
                                  width: 1.4,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF2563EB),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _deskripsiController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Deskripsi / Catatan',
                              hintText:
                                  'Tambahkan deskripsi atau catatan untuk siswa...',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: fieldBorder,
                              enabledBorder: fieldBorder,
                              focusedBorder: fieldBorder.copyWith(
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
                                  width: 1.4,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.notes_outlined,
                                color: Color(0xFF2563EB),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _saving
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF64748B),
                                    side: const BorderSide(
                                      color: Color(0xFFD8E1EE),
                                    ),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text('Batal'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saving
                                      ? null
                                      : () => _submit(publish: false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Simpan'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoalLatihanManagementScreenState
    extends State<SoalLatihanManagementScreen> {
  bool _isLoading = true;
  List<Latihan> _allLatihan = [];
  List<SoalLatihan> _allSoal = [];
  List<Latihan> _filteredLatihan = [];
  String _searchQuery = '';
  String _selectedStatus = 'Semua Status';
  String _selectedMapel = 'Semua Mapel';
  final Set<String> _mapelOptions = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final latihan = await LatihanManagementService.getLatihan();
    final soal = await LatihanSoalService.getSoalLatihan();

    if (!mounted) return;

    _mapelOptions.clear();
    _mapelOptions.add('Semua Mapel');
    for (final item in latihan) {
      _mapelOptions.add(item.mapel);
    }

    setState(() {
      _allLatihan = latihan;
      _allSoal = soal;
      _filteredLatihan = latihan;
      _isLoading = false;
    });
  }

  void _filterData() {
    List<Latihan> filtered = _allLatihan;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Filter by status
    if (_selectedStatus != 'Semua Status') {
      filtered = filtered
          .where((item) => item.status == _selectedStatus)
          .toList();
    }

    // Filter by mapel
    if (_selectedMapel != 'Semua Mapel') {
      filtered = filtered
          .where((item) => item.mapel == _selectedMapel)
          .toList();
    }

    setState(() => _filteredLatihan = filtered);
  }

  Future<void> _pickStatusFilter() async {
    final options = ['Semua Status', 'Draft', 'Dipublikasikan'];
    final selected = await _showFilterSheet(options, _selectedStatus);
    if (selected == null) {
      return;
    }
    setState(() => _selectedStatus = selected);
    _filterData();
  }

  Future<void> _pickMapelFilter() async {
    final options = _mapelOptions.toList();
    final selected = await _showFilterSheet(options, _selectedMapel);
    if (selected == null) {
      return;
    }
    setState(() => _selectedMapel = selected);
    _filterData();
  }

  Future<String?> _showFilterSheet(List<String> options, String selectedValue) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final option = options[index];
                final selected = option == selectedValue;
                return ListTile(
                  dense: true,
                  title: Text(
                    option,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: Color(0xFF2563EB))
                      : null,
                  onTap: () => Navigator.of(context).pop(option),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _LatihanCreatePage(mapelOptions: _mapelOptions.toList()),
    );

    if (created == true) {
      await _loadData();
    }
  }

  void _showEditDialog(Latihan latihan) {
    final parentContext = context;
    final titleController = TextEditingController(text: latihan.title);
    String selectedMapel = latihan.mapel;
    final soalController = TextEditingController(
      text: latihan.totalSoal.toString(),
    );

    final mapelOptions = <String>{
      'Matematika',
      'Fisika',
      'Kimia',
      'Biologi',
      'Bahasa Indonesia',
      'Bahasa Inggris',
      latihan.mapel,
    }.toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Edit Latihan',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Judul Latihan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: mapelOptions.contains(selectedMapel)
                      ? selectedMapel
                      : mapelOptions.first,
                  decoration: InputDecoration(
                    labelText: 'Mata Pelajaran',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: mapelOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedMapel = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: soalController,
                  decoration: InputDecoration(
                    labelText: 'Total Soal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: soalController,
                  decoration: InputDecoration(
                    labelText: 'Total Soal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(parentContext);
                final messenger = ScaffoldMessenger.of(parentContext);

                final result = await LatihanManagementService.updateLatihan(
                  latihanId: latihan.id,
                  title: titleController.text,
                  mapel: selectedMapel,
                  totalSoal: int.tryParse(soalController.text) ?? 1,
                );

                if (!mounted) return;

                navigator.pop();

                if (result['success']) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(result['message'])),
                  );
                  _loadData();
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteLatihan(Latihan latihan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Latihan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        content: Text(
          'Hapus "${latihan.title}"?',
          style: const TextStyle(color: Color(0xFF6B7280), height: 1.45),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await LatihanManagementService.deleteLatihan(latihan.id);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'])));
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<SoalLatihan> _getSoalByLatihan(Latihan latihan) {
    return _allSoal
        .where((soal) => latihan.questionIds.contains(soal.id))
        .toList();
  }

  Map<String, List<Latihan>> _groupLatihanByMapel() {
    final grouped = <String, List<Latihan>>{};
    for (final latihan in _filteredLatihan) {
      if (!grouped.containsKey(latihan.mapel)) {
        grouped[latihan.mapel] = [];
      }
      grouped[latihan.mapel]!.add(latihan);
    }
    return grouped;
  }

  Widget _buildTopSummary() {
    final latihanTotal = _allLatihan.length;
    final totalMapel = _mapelOptions.length;
    final totalSoal = _allLatihan.fold<int>(
      0,
      (sum, item) => sum + item.totalSoal,
    );
    final published = _allLatihan.where((item) => item.isPublished).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 650
            ? 2
            : 1;
        final cardWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (16 * (columns - 1))) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildSummaryCard(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                value: '$latihanTotal',
                label: 'Total Latihan',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildSummaryCard(
                icon: Icons.check_circle_outline,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFDCFCE7),
                value: '$published',
                label: 'Dipublikasi',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildSummaryCard(
                icon: Icons.tag,
                iconColor: const Color(0xFFF97316),
                iconBg: const Color(0xFFFFEDD5),
                value: '$totalSoal',
                label: 'Total Soal',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildSummaryCard(
                icon: Icons.menu_book_outlined,
                iconColor: const Color(0xFF8B5CF6),
                iconBg: const Color(0xFFF3E8FF),
                value: '$totalMapel',
                label: 'Mata Pelajaran',
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildLatihanByMapelSections() {
    final grouped = _groupLatihanByMapel();
    final sections = <Widget>[];

    for (final mapel in grouped.keys) {
      final latihans = grouped[mapel]!;

      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latihan $mapel',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${latihans.fold<int>(0, (sum, item) => sum + item.totalSoal)} soal',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...latihans.map((latihan) {
              final soalList = _getSoalByLatihan(latihan);
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildDetailedLatihanCard(latihan, soalList),
              );
            }),
          ],
        ),
      );

      sections.add(const SizedBox(height: 32));
    }

    return sections;
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32 / 2,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
        ),
      ],
    );
  }

  Widget _buildDetailedLatihanCard(
    Latihan latihan,
    List<SoalLatihan> soalList,
  ) {
    final createdSoal = soalList.length;
    final totalSoal = latihan.totalSoal;
    final progressPercent = totalSoal > 0 ? createdSoal / totalSoal : 0.0;
    final tanggal = latihan.createdAt;
    final tanggalLabel =
        '${tanggal.day.toString().padLeft(2, '0')}/${tanggal.month.toString().padLeft(2, '0')}/${(tanggal.year % 100).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  latihan.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Row(
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () => _showEditDialog(latihan),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF6B7280),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () => _deleteLatihan(latihan),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  latihan.mapel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: latihan.isPublished
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  latihan.isPublished ? 'Dipublikasi' : 'Draft',
                  style: TextStyle(
                    fontSize: 12,
                    color: latihan.isPublished
                        ? const Color(0xFF065F46)
                        : const Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _infoItem('${latihan.totalSoal}', 'Soal')),
              Expanded(child: _infoItem('30', 'Menit')),
              Expanded(child: _infoItem(tanggalLabel, 'Dibuat')),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress Soal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                '$createdSoal/$totalSoal selesai',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(totalSoal.clamp(1, 20).toInt(), (index) {
              final number = index + 1;
              final isDone = index < createdSoal;
              return Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFFDDF6EE)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDone
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF6B7280),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Lihat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditDialog(latihan),
                  icon: const Icon(Icons.list_alt_outlined),
                  label: const Text('Kelola'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteLatihan(latihan),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoalCard(int nomorSoal, SoalLatihan soal) {
    final choices = [
      ('A', soal.pilihanA),
      ('B', soal.pilihanB),
      ('C', soal.pilihanC),
      ('D', soal.pilihanD),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      nomorSoal.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Soal Latihan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                'Kunci ${soal.jawaban}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            soal.pertanyaan,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ...choices.map((choice) {
            final label = choice.$1;
            final text = choice.$2;
            final isAnswer = label == soal.jawaban;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAnswer ? Colors.green[50] : Colors.grey[50],
                border: Border.all(
                  color: isAnswer ? Colors.green[300]! : Colors.grey[200]!,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isAnswer ? Colors.green[700] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                label: const Text(
                  'Hapus',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDipublikasikan = _allLatihan.where((e) => e.isPublished).length;
    final totalSoal = _allLatihan.fold<int>(
      0,
      (sum, item) => sum + item.totalSoal,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Soal Latihan'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kelola Soal Latihan',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buat dan kelola soal latihan untuk siswa Anda',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Stats Cards
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatCard(
                            label: 'Total Latihan',
                            value: _allLatihan.length.toString(),
                            icon: Icons.assignment,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            label: 'Dipublikasikan',
                            value: totalDipublikasikan.toString(),
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            label: 'Total Soal',
                            value: totalSoal.toString(),
                            icon: Icons.help,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            label: 'Mapel',
                            value: _mapelOptions.length.toString(),
                            icon: Icons.category,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Search and Filter
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              _searchQuery = value;
                              _filterData();
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari soal latihan...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _pickStatusFilter,
                          icon: const Icon(Icons.filter_alt_outlined, size: 18),
                          label: Text(_selectedStatus),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF111827),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _pickMapelFilter,
                          icon: const Icon(Icons.menu_book_outlined, size: 18),
                          label: Text(_selectedMapel),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF111827),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _showCreateDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Buat Latihan',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Grouped Latihan by Mapel
                    if (_filteredLatihan.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada latihan terdaftar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._buildLatihanByMapelSections(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
