import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/jadwal_pembelajaran_service.dart';
import '../../widgets/mentor_sidebar_shell.dart';
import 'mentor_attendance_screen.dart';
import 'mentor_olimpiade_screen.dart';
import '../mentor/materi_pembelajaran_screen.dart';

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
  final bool mentorView;

  const JadwalPembelajaranScreen({super.key, this.mentorView = false});

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
        widget.mentorView
            ? JadwalService.getMentorJadwalList()
            : JadwalService.getJadwalList(),
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
      final mentorMatch = widget.mentorView
          ? true
          : selectedMentorFilterId == null ||
                jadwal['mentor_id'] == selectedMentorFilterId;
      return hariMatch && mentorMatch;
    }).toList();
  }

  void _onSidebarMenuTap(String title) {
  if (title == 'Dashboard') {
    Navigator.pushReplacementNamed(context, AppRoutes.mentorDashboard);
    return;
  }
  if (title == 'Jadwal Mengajar') {
    // TODO: Tambahkan navigasi ke Jadwal Mengajar
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (_) => const JadwalMengajarScreen()),
    // );
    return;
  }
  if (title == 'Absensi Kelas') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MentorAttendanceScreen()),
    );
    return;
  }
  if (title == 'Soal Latihan') {
    Navigator.pushReplacementNamed(context, AppRoutes.mentorExercise);
    return;
  }
  if (title == 'Try Out') {
    Navigator.pushReplacementNamed(context, AppRoutes.mentorTryout);
    return;
  }
  if (title == 'Materi Pembelajaran') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MateriPembelajaranScreen(initialClass: null),
      ),
    );
    return;
  }
  if (title == 'Olimpiade Akademik') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MentorOlimpiadeScreen(),
      ),
    );
    return;
  }
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
        if (!widget.mentorView)
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
          )
        else
          const DataCell(Text('Lihat saja')),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  String _dayName(DateTime date) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    return days[date.weekday - 1];
  }

  String _formatIndoDate(DateTime date) {
    return '${_dayName(date)}, ${date.day} ${_monthName(date.month)} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: Container(
        decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _headerBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _headerBlue.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.mentorView
                                ? 'Jadwal Mengajar Saya'
                                : 'Kelola Jadwal Pembelajaran',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.mentorView
                                ? 'Jadwal yang ditetapkan admin untuk mentor yang sedang login'
                                : 'Jadwal utama yang berlaku setiap minggu secara berkelanjutan',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 64,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              
              // Tombol Tambah Jadwal
              if (!widget.mentorView)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
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
                ),
              const SizedBox(height: 20),
              
              // Stat Cards
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
                      subtitle: _formatIndoDate(DateTime.now()),
                      color: const Color(0xFF16A34A),
                      backgroundColor: const Color(0xFFE0F4E8),
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Filter Section
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
                        value: selectedHari.isEmpty ? null : selectedHari,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                        ),
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
                          prefixIcon: const Icon(
                            Icons.event_outlined,
                            size: 18,
                            color: Color(0xFF2563EB),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 1.4,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    if (!widget.mentorView) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: selectedMentorFilterId,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w600,
                          ),
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
                            prefixIcon: const Icon(
                              Icons.person_search_outlined,
                              size: 18,
                              color: Color(0xFF2563EB),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.4,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // TABLE SECTION - DIPERBAIKI AGAR FULL WIDTH
              Container(
                width: double.infinity, // Memastikan container full width
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE6EDF7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table Header
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
                    
                    // TABLE - DIBUAT RESPONSIVE DAN FULL WIDTH
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Hitung lebar minimal tabel berdasarkan konten
                        final double screenWidth = constraints.maxWidth;
                        
                        // Tentukan lebar kolom secara proporsional
                        final double hariWidth = 80.0;
                        final double waktuWidth = 120.0;
                        final double kelasWidth = 140.0;
                        final double mapelWidth = 140.0;
                        final double mentorWidth = 120.0;
                        final double ruangWidth = 80.0;
                        final double aksiWidth = widget.mentorView ? 0 : 100.0;
                        
                        final double totalWidth = hariWidth + waktuWidth + kelasWidth + mapelWidth + mentorWidth + ruangWidth + aksiWidth;
                        
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: SizedBox(
                            width: totalWidth > screenWidth ? totalWidth : screenWidth,
                            child: DataTable(
                              columnSpacing: 12, // Kurangi jarak antar kolom
                              horizontalMargin: 16,
                              headingRowHeight: 48,
                              dataRowMaxHeight: 56,
                              dataRowMinHeight: 48,
                              headingTextStyle: const TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                              columns: [
                                const DataColumn(label: SizedBox(width: 70, child: Text('HARI', overflow: TextOverflow.visible))),
                                const DataColumn(label: SizedBox(width: 110, child: Text('WAKTU', overflow: TextOverflow.visible))),
                                const DataColumn(label: SizedBox(width: 130, child: Text('KELAS', overflow: TextOverflow.visible))),
                                const DataColumn(label: SizedBox(width: 130, child: Text('MATA PELAJARAN', overflow: TextOverflow.visible))),
                                const DataColumn(label: SizedBox(width: 110, child: Text('MENTOR', overflow: TextOverflow.visible))),
                                const DataColumn(label: SizedBox(width: 70, child: Text('RUANG', overflow: TextOverflow.visible))),
                                if (!widget.mentorView)
                                  const DataColumn(label: SizedBox(width: 90, child: Text('AKSI', overflow: TextOverflow.visible))),
                              ],
                              rows: _filteredRows
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => _buildRow(entry.value, entry.key),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      },
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
  String _selectedClass = 'Kelas 12';
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
    _selectedClass = 'Kelas 12';
    final existingClass = existing?['class_level']?.toString();
    if (existingClass != null &&
        ['Kelas 10', 'Kelas 11', 'Kelas 12'].contains(existingClass)) {
      _selectedClass = existingClass;
    } else if (existing != null && existingPaketIdRaw != null) {
      final paket = widget.paketList.firstWhere(
        (p) => p['id'] == existingPaketIdRaw,
        orElse: () => {},
      );
      final title = (paket['nama_paket'] ?? paket['nama'] ?? '').toString().toLowerCase();
      if (title.contains('kelas 10') || title.contains('10')) {
        _selectedClass = 'Kelas 10';
      } else if (title.contains('kelas 11') || title.contains('11')) {
        _selectedClass = 'Kelas 11';
      } else if (title.contains('kelas 12') || title.contains('12')) {
        _selectedClass = 'Kelas 12';
      }
    }
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
        'class_level': _selectedClass,
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
        ScaffoldMessenger.of(context).showSnackBar(
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
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    );
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.18),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
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
                          borderRadius: BorderRadius.circular(14),
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
                                fontSize: 20,
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
                                height: 1.3,
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
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonFormField<int>(
                              initialValue: _selectedPaketId,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
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
                              decoration: InputDecoration(
                                labelText: 'Paket Les',
                                prefixIcon: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: _selectedMentorId,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
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
                              decoration: InputDecoration(
                                labelText: 'Mentor',
                                prefixIcon: const Icon(
                                  Icons.badge_outlined,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedHariValue,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
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
                              decoration: InputDecoration(
                                labelText: 'Hari',
                                prefixIcon: const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
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
                              decoration: InputDecoration(
                                labelText: 'Jam Mulai',
                                hintText: '08:00',
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
                                  Icons.access_time_rounded,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
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
                              decoration: InputDecoration(
                                labelText: 'Jam Selesai',
                                hintText: '09:30',
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
                                  Icons.access_time_rounded,
                                  size: 18,
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
                              initialValue: _selectedClass,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
                              items: const ['Kelas 10', 'Kelas 11', 'Kelas 12']
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(
                                () => _selectedClass = v ?? _selectedClass,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Kelas',
                                prefixIcon: const Icon(
                                  Icons.class_outlined,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _mataPelajaranController,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Mata pelajaran wajib diisi'
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Mata Pelajaran',
                                hintText: 'Matematika',
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
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _ruangController,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Ruang wajib diisi'
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Ruang',
                                hintText: 'Ruang A',
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
                                  Icons.meeting_room_outlined,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
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
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFD8E1EE)),
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
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dialogHeaderBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
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