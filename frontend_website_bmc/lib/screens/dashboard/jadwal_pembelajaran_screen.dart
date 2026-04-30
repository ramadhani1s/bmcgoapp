import 'package:flutter/material.dart';
import '../../services/jadwal_pembelajaran_service.dart';

class JadwalPembelajaranScreen extends StatefulWidget {
  const JadwalPembelajaranScreen({super.key});

  @override
  State<JadwalPembelajaranScreen> createState() =>
      _JadwalPembelajaranScreenState();
}

class _JadwalPembelajaranScreenState extends State<JadwalPembelajaranScreen> {
  static const Color _headerBlue = Color(0xFF175CFF);

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
          content: Text('❌ Gagal memuat data jadwal: $e'),
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

  Future<void> _createOrUpdateJadwal({Map<String, dynamic>? existing}) async {
    final formKey = GlobalKey<FormState>();

    int? selectedPaketId = existing == null
        ? null
        : existing['paket_id'] as int?;
    int? selectedMentorId = existing == null
        ? null
        : existing['mentor_id'] as int?;
    String? selectedHariValue = existing == null
        ? null
        : existing['hari']?.toString();
    final mataPelajaranController = TextEditingController(
      text: existing?['mata_pelajaran']?.toString() ?? '',
    );
    final jamMulaiController = TextEditingController(
      text: existing == null ? '' : _timeToString(existing['jam_mulai']),
    );
    final jamSelesaiController = TextEditingController(
      text: existing == null ? '' : _timeToString(existing['jam_selesai']),
    );
    final ruangController = TextEditingController(
      text: existing?['ruang']?.toString() ?? '',
    );
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickAndSetTime(
              TextEditingController controller,
            ) async {
              final picked = await showTimePicker(
                context: dialogContext,
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
              if (picked != null) {
                setModalState(() {
                  controller.text =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
              }
            }

            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              if (selectedPaketId == null || selectedMentorId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Paket dan mentor wajib dipilih'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setModalState(() => isSubmitting = true);

              final payload = <String, dynamic>{
                'paket_id': selectedPaketId,
                'mentor_id': selectedMentorId,
                'hari': selectedHariValue ?? '',
                'jam_mulai': jamMulaiController.text.trim(),
                'jam_selesai': jamSelesaiController.text.trim(),
                'mata_pelajaran': mataPelajaranController.text.trim(),
                'ruang': ruangController.text.trim(),
              };

              final result = existing == null
                  ? await JadwalService.createJadwal(payload)
                  : await JadwalService.updateJadwal(
                      existing['id'] as int,
                      payload,
                    );

              if (!mounted) return;

              setModalState(() => isSubmitting = false);

              if (result['status'] == 'success') {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      existing == null
                          ? '✅ Jadwal berhasil dibuat'
                          : '✅ Jadwal berhasil diupdate',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadInitialData();
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      '❌ ${result['message'] ?? 'Gagal menyimpan jadwal'}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              title: Text(
                existing == null ? '➕ Tambah Jadwal' : '✏️ Edit Jadwal',
              ),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<int>(
                          value: selectedPaketId,
                          items: paketList
                              .map(
                                (paket) => DropdownMenuItem<int>(
                                  value: paket['id'] as int,
                                  child: Text(_packageLabel(paket)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setModalState(() => selectedPaketId = value);
                          },
                          validator: (value) =>
                              value == null ? 'Paket wajib dipilih' : null,
                          decoration: const InputDecoration(
                            labelText: 'Paket Les',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedMentorId,
                          items: mentorList
                              .map(
                                (mentor) => DropdownMenuItem<int>(
                                  value: mentor['id'] as int,
                                  child: Text(_mentorLabel(mentor)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setModalState(() => selectedMentorId = value);
                          },
                          validator: (value) =>
                              value == null ? 'Mentor wajib dipilih' : null,
                          decoration: const InputDecoration(
                            labelText: 'Mentor',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedHariValue,
                          items: hariList
                              .map(
                                (hari) => DropdownMenuItem<String>(
                                  value: hari,
                                  child: Text(hari),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setModalState(() => selectedHariValue = value);
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Hari wajib dipilih'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Hari',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: jamMulaiController,
                          readOnly: true,
                          onTap: () => pickAndSetTime(jamMulaiController),
                          validator: (value) => value == null || value.isEmpty
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
                          controller: jamSelesaiController,
                          readOnly: true,
                          onTap: () => pickAndSetTime(jamSelesaiController),
                          validator: (value) => value == null || value.isEmpty
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
                          controller: mataPelajaranController,
                          validator: (value) => value == null || value.isEmpty
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
                          controller: ruangController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Ruang wajib diisi'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Ruang',
                            border: OutlineInputBorder(),
                            hintText: 'Ruang A',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE4EAF3)),
                          ),
                          child: Text(
                            'Data yang disimpan akan masuk ke tabel jadwal dengan FK paket_id dan mentor_id.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(backgroundColor: _headerBlue),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(existing == null ? 'Simpan' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );

    mataPelajaranController.dispose();
    jamMulaiController.dispose();
    jamSelesaiController.dispose();
    ruangController.dispose();
  }

  Future<void> _showDeleteDialog(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Hapus Jadwal'),
        content: const Text('Apakah Anda yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await JadwalService.deleteJadwal(id);
      if (!mounted) return;
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Jadwal berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadInitialData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message'] ?? 'Gagal hapus jadwal'}'),
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
        const DataCell(Text('0')),
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _headerBlue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(23, 92, 255, 0.22),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
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
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelola Jadwal Pembelajaran',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Jadwal utama yang berlaku setiap minggu secara berkelanjutan',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _createOrUpdateJadwal(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Jadwal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _headerBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Jadwal Mingguan',
                    value: jadwalList.length.toString(),
                    subtitle: 'Kelas aktif per minggu',
                    color: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFEAF2FF),
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
                    backgroundColor: const Color(0xFFEAF8EF),
                    icon: Icons.schedule_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE4EAF3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedHari.isEmpty ? null : selectedHari,
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: selectedMentorFilterId,
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4EAF3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      color: _headerBlue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
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
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 28,
                      horizontalMargin: 18,
                      columns: const [
                        DataColumn(label: Text('HARI')),
                        DataColumn(label: Text('WAKTU')),
                        DataColumn(label: Text('KELAS')),
                        DataColumn(label: Text('MATA PELAJARAN')),
                        DataColumn(label: Text('MENTOR')),
                        DataColumn(label: Text('RUANG')),
                        DataColumn(label: Text('SISWA')),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
