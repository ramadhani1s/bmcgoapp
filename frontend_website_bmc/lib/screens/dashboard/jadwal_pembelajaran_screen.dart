import 'package:flutter/material.dart';
import '../../services/jadwal_pembelajaran_service.dart';

// Helpers used by dialog widget (kept local to avoid referencing state methods)
const Color _dialogHeaderBlue = Color(0xFF2563EB);
const List<String> _dialogHariList = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

bool _isSuccessResponseDynamic(dynamic result) {
  if (result is Map<String, dynamic>) {
    final status = (result['status'] ?? '').toString().toLowerCase();
    if (status == 'success' || status == 'ok') return true;
    final message = (result['message'] ?? '').toString().toLowerCase();
    return message.contains('berhasil') || message.contains('success');
  }
  if (result is String) {
    final text = result.toLowerCase();
    return text == 'ok' ||
        text.contains('berhasil') ||
        text.contains('success');
  }
  return false;
}

String _extractResultMessageDynamic(dynamic result) {
  if (result is Map<String, dynamic>) {
    return (result['message'] ?? result['detail'] ?? result['error'] ?? '')
        .toString();
  }
  return result?.toString() ?? '';
}

class JadwalPembelajaranScreen extends StatefulWidget {
  const JadwalPembelajaranScreen({super.key});

  @override
  State<JadwalPembelajaranScreen> createState() =>
      _JadwalPembelajaranScreenState();
}

class _JadwalPembelajaranScreenState extends State<JadwalPembelajaranScreen> {
  static const Color _headerBlue = Color(0xFF2563EB);

  List<Map<String, dynamic>> jadwalList = [];
  List<Map<String, dynamic>> paketList = [];
  List<Map<String, dynamic>> mentorList = [];

  bool isLoading = true;
  String selectedHari = '';
  int? selectedMentorFilterId;

  static const List<String> hariList = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        JadwalService.getPaketList(),
        JadwalService.getMentorList(),
        JadwalService.getJadwalList(),
      ]);

      if (!mounted) return;

      setState(() {
        paketList = results[0];
        mentorList = results[1];
        jadwalList = results[2];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        jadwalList = [];
        paketList = [];
        mentorList = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data jadwal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredRows {
    return jadwalList.where((jadwal) {
      final hariMatch = selectedHari.isEmpty || jadwal['hari'] == selectedHari;
      final mentorMatch =
          selectedMentorFilterId == null ||
          jadwal['mentor_id'] == selectedMentorFilterId;
      return hariMatch && mentorMatch;
    }).toList();
  }

  String _timeToString(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    if (text.isEmpty) return '';

    if (text.contains('T')) {
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
    }

    final parts = text.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return text;
  }

  String _packageLabel(Map<String, dynamic> paket) {
    return (paket['nama_paket'] ?? paket['nama'] ?? 'Paket').toString();
  }

  String _mentorLabel(Map<String, dynamic> mentor) {
    return (mentor['nama_mentor'] ?? mentor['nama'] ?? 'Mentor').toString();
  }

  Map<String, dynamic>? _findPaketById(int? id) {
    if (id == null) return null;
    for (final paket in paketList) {
      if (paket['id'] == id) return paket;
    }
    return null;
  }

  Map<String, dynamic>? _findMentorById(int? id) {
    if (id == null) return null;
    for (final mentor in mentorList) {
      if (mentor['id'] == id) return mentor;
    }
    return null;
  }

  String _resolveMentorName(int mentorId) {
    final mentor = _findMentorById(mentorId);
    return mentor == null ? 'Mentor #$mentorId' : _mentorLabel(mentor);
  }

  String _resolveKelas(int paketId) {
    final paket = _findPaketById(paketId);
    if (paket == null) return '-';
    final title = _packageLabel(paket);
    if (title.toLowerCase().contains('kelas')) {
      return title;
    }
    return title;
  }

  bool _isSuccessResponse(dynamic result) {
    if (result is Map<String, dynamic>) {
      final status = (result['status'] ?? '').toString().toLowerCase();
      if (status == 'success' || status == 'ok') return true;

      final message = (result['message'] ?? '').toString().toLowerCase();
      return message.contains('berhasil') || message.contains('success');
    }

    if (result is String) {
      final text = result.toLowerCase();
      return text == 'ok' ||
          text.contains('berhasil') ||
          text.contains('success');
    }

    return false;
  }

  String _extractResultMessage(dynamic result) {
    if (result is Map<String, dynamic>) {
      return (result['message'] ?? result['detail'] ?? result['error'] ?? '')
          .toString();
    }
    return result?.toString() ?? '';
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _createOrUpdateJadwal({Map<String, dynamic>? existing}) async {
    final didSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _JadwalFormDialog(
        parentContext: context,
        existing: existing,
        paketList: paketList,
        mentorList: mentorList,
      ),
    );

    if (didSave == true && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _loadInitialData();
        if (!mounted) return;
        _showSnackBar(
          existing == null
              ? 'Jadwal berhasil dibuat'
              : 'Jadwal berhasil diupdate',
          backgroundColor: Colors.green,
        );
      });
    }
  }

  Future<void> _showDeleteDialog(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: const Text('Apakah Anda yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await JadwalService.deleteJadwal(id);
      if (!mounted) return;
      if (_isSuccessResponse(result)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadInitialData();
      } else {
        final msg = _extractResultMessage(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.isNotEmpty ? msg : 'Gagal hapus jadwal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _countJadwalHariIni() {
    final now = DateTime.now();
    final hariIni = hariList[now.weekday - 1];
    return jadwalList.where((jadwal) => jadwal['hari'] == hariIni).length;
  }

  DataRow _buildRow(Map<String, dynamic> jadwal, int index) {
    final paketId = jadwal['paket_id'] as int?;
    final mentorId = jadwal['mentor_id'] as int?;
    final jamMulai = _timeToString(jadwal['jam_mulai']);
    final jamSelesai = _timeToString(jadwal['jam_selesai']);

    final warnaChip = [
      const Color(0xFF4C7DFF),
      const Color(0xFF1CB58A),
      const Color(0xFFF2A44B),
      const Color(0xFF8B6EF6),
    ][index % 4];

    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              (jadwal['hari'] ?? '-').toString(),
              style: const TextStyle(
                color: Color(0xFF2C63FF),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(Text('$jamMulai - $jamSelesai')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: warnaChip.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _resolveKelas(paketId ?? 0),
              style: TextStyle(
                color: warnaChip,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(Text((jadwal['mata_pelajaran'] ?? '-').toString())),
        DataCell(Text(_resolveMentorName(mentorId ?? 0))),
        DataCell(Text((jadwal['ruang'] ?? '-').toString())),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                onPressed: () => _createOrUpdateJadwal(existing: jadwal),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                onPressed: () => _showDeleteDialog(jadwal['id'] as int),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F9FF), Color(0xFFF3F6FB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kelola Jadwal Pembelajaran',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Jadwal utama yang berlaku setiap minggu secara berkelanjutan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _createOrUpdateJadwal(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Jadwal'),
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
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Jadwal Mingguan',
                      value: jadwalList.length.toString(),
                      subtitle: 'Kelas aktif per minggu',
                      color: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFFDCEBFF),
                      icon: Icons.calendar_month_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      title: 'Jadwal Hari Ini',
                      value: _countJadwalHariIni().toString(),
                      subtitle: 'Contoh: Hari Senin',
                      color: const Color(0xFF16A34A),
                      backgroundColor: const Color(0xFFE0F4E8),
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE6EDF7)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedHari.isEmpty
                            ? null
                            : selectedHari,
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('Semua Hari'),
                          ),
                          ...hariList.map(
                            (hari) => DropdownMenuItem<String>(
                              value: hari,
                              child: Text(hari),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => selectedHari = value ?? '');
                        },
                        decoration: InputDecoration(
                          labelText: 'Filter Hari',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: selectedMentorFilterId,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua Mentor'),
                          ),
                          ...mentorList.map(
                            (mentor) => DropdownMenuItem<int?>(
                              value: mentor['id'] as int,
                              child: Text(_mentorLabel(mentor)),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => selectedMentorFilterId = value);
                        },
                        decoration: InputDecoration(
                          labelText: 'Filter Mentor',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE6EDF7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: _headerBlue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jadwal Utama (Berlaku Setiap Minggu)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Jadwal ini digunakan secara berkelanjutan hingga ada perubahan',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 45,
                        horizontalMargin: 19,
                        columns: const [
                          DataColumn(label: Text('HARI')),
                          DataColumn(label: Text('WAKTU')),
                          DataColumn(label: Text('KELAS')),
                          DataColumn(label: Text('MATA PELAJARAN')),
                          DataColumn(label: Text('MENTOR')),
                          DataColumn(label: Text('RUANG')),
                          DataColumn(label: Text('AKSI')),
                        ],
                        rows: _filteredRows
                            .asMap()
                            .entries
                            .map((entry) => _buildRow(entry.value, entry.key))
                            .toList(),
                      ),
                    ),
                    if (_filteredRows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Belum ada jadwal yang sesuai filter.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
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
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }
}

class _JadwalFormDialog extends StatefulWidget {
  final BuildContext parentContext;
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> paketList;
  final List<Map<String, dynamic>> mentorList;

  const _JadwalFormDialog({
    required this.parentContext,
    this.existing,
    required this.paketList,
    required this.mentorList,
  });

  @override
  State<_JadwalFormDialog> createState() => _JadwalFormDialogState();
}

class _JadwalFormDialogState extends State<_JadwalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late int? _selectedPaketId;
  late int? _selectedMentorId;
  late String? _selectedHariValue;
  late TextEditingController _mataPelajaranController;
  late TextEditingController _jamMulaiController;
  late TextEditingController _jamSelesaiController;
  late TextEditingController _ruangController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final existingPaketIdRaw = existing?['paket_id'];
    final existingMentorIdRaw = existing?['mentor_id'];
    _selectedPaketId = existingPaketIdRaw is int
        ? existingPaketIdRaw
        : int.tryParse(existingPaketIdRaw?.toString() ?? '');
    _selectedMentorId = existingMentorIdRaw is int
        ? existingMentorIdRaw
        : int.tryParse(existingMentorIdRaw?.toString() ?? '');
    _selectedHariValue = existing?['hari']?.toString();
    _mataPelajaranController = TextEditingController(
      text: existing?['mata_pelajaran']?.toString() ?? '',
    );
    _jamMulaiController = TextEditingController(
      text: existing == null ? '' : _timeToString(existing['jam_mulai']),
    );
    _jamSelesaiController = TextEditingController(
      text: existing == null ? '' : _timeToString(existing['jam_selesai']),
    );
    _ruangController = TextEditingController(
      text: existing?['ruang']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _mataPelajaranController.dispose();
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
    _ruangController.dispose();
    super.dispose();
  }

  String _timeToString(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    if (text.isEmpty) return '';
    if (text.contains('T')) {
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
    }
    final parts = text.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return text;
  }

  Future<void> _pickAndSetTime(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(controller.text.split(':').first) ?? 8,
        minute:
            int.tryParse(
              controller.text.split(':').length > 1
                  ? controller.text.split(':')[1]
                  : '0',
            ) ??
            0,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        controller.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedPaketId == null || _selectedMentorId == null) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(content: Text('Paket dan mentor wajib dipilih')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'paket_id': _selectedPaketId,
        'mentor_id': _selectedMentorId,
        'hari': _selectedHariValue ?? '',
        'jam_mulai': _jamMulaiController.text.trim(),
        'jam_selesai': _jamSelesaiController.text.trim(),
        'mata_pelajaran': _mataPelajaranController.text.trim(),
        'ruang': _ruangController.text.trim(),
      };

      final existingIdRaw = widget.existing?['id'];
      final existingId = existingIdRaw is int
          ? existingIdRaw
          : int.tryParse(existingIdRaw?.toString() ?? '');

      if (widget.existing != null && existingId == null) {
        throw Exception('ID jadwal tidak valid');
      }

      final result = widget.existing == null
          ? await JadwalService.createJadwal(payload)
          : await JadwalService.updateJadwal(existingId!, payload);

      if (!mounted) return;

      if (_isSuccessResponseDynamic(result)) {
        Navigator.of(context).pop(true);
      } else {
        final msg = _extractResultMessageDynamic(result);
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text(msg.isNotEmpty ? msg : 'Gagal menyimpan jadwal'),
          ),
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        widget.parentContext,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 840,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.18),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 18, 20),
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          existing == null ? Icons.add : Icons.edit_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              existing == null
                                  ? 'Tambah Jadwal'
                                  : 'Edit Jadwal',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              existing == null
                                  ? 'Buat jadwal baru yang akan muncul pada jadwal mingguan.'
                                  : 'Perbarui jadwal yang sudah tersimpan.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonFormField<int>(
                              value: _selectedPaketId,
                              items: widget.paketList
                                  .map(
                                    (paket) => DropdownMenuItem<int>(
                                      value: paket['id'] as int,
                                      child: Text(
                                        (paket['nama_paket'] ??
                                                paket['nama'] ??
                                                'Paket')
                                            .toString(),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedPaketId = v),
                              validator: (v) =>
                                  v == null ? 'Paket wajib dipilih' : null,
                              decoration: const InputDecoration(
                                labelText: 'Paket Les',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              value: _selectedMentorId,
                              items: widget.mentorList
                                  .map(
                                    (mentor) => DropdownMenuItem<int>(
                                      value: mentor['id'] as int,
                                      child: Text(
                                        (mentor['nama_mentor'] ??
                                                mentor['nama'] ??
                                                'Mentor')
                                            .toString(),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedMentorId = v),
                              validator: (v) =>
                                  v == null ? 'Mentor wajib dipilih' : null,
                              decoration: const InputDecoration(
                                labelText: 'Mentor',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedHariValue,
                              items: _dialogHariList
                                  .map(
                                    (hari) => DropdownMenuItem<String>(
                                      value: hari,
                                      child: Text(hari),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedHariValue = v),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Hari wajib dipilih'
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Hari',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _jamMulaiController,
                              readOnly: true,
                              onTap: () => _pickAndSetTime(_jamMulaiController),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Jam mulai wajib diisi'
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Jam Mulai',
                                hintText: '08:00',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.access_time_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _jamSelesaiController,
                              readOnly: true,
                              onTap: () =>
                                  _pickAndSetTime(_jamSelesaiController),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Jam selesai wajib diisi'
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Jam Selesai',
                                hintText: '09:30',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.access_time_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _mataPelajaranController,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Mata pelajaran wajib diisi'
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Mata Pelajaran',
                                border: OutlineInputBorder(),
                                hintText: 'Matematika',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _ruangController,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Ruang wajib diisi'
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Ruang',
                                border: OutlineInputBorder(),
                                hintText: 'Ruang A',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFD6DEEA)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dialogHeaderBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.existing == null ? 'Simpan' : 'Update',
                              ),
                      ),
                    ],
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
