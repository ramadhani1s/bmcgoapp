import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';
import '../../services/jadwal_pembelajaran_service.dart';
import '../../widgets/mentor_sidebar_shell.dart';
import 'mentor_attendance_screen.dart';
import 'mentor_olimpiade_screen.dart';
import '../mentor/materi_pembelajaran_screen.dart';

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
  final bool embeddedInDashboard;
  final int? initialEditJadwalId;

  const JadwalPembelajaranScreen({
    super.key,
    this.mentorView = false,
    this.embeddedInDashboard = false,
    this.initialEditJadwalId,
  });

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
  bool _hasTriggeredInitialEdit = false;
  User? _currentUser;

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
      final user = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }

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

      if (widget.initialEditJadwalId != null && !_hasTriggeredInitialEdit) {
        _hasTriggeredInitialEdit = true;
        final targetId = widget.initialEditJadwalId;
        final target = jadwalList.firstWhere(
          (j) {
            final idRaw = j['id'];
            final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
            return id == targetId;
          },
          orElse: () => <String, dynamic>{},
        );
        if (target.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _createOrUpdateJadwal(existing: target);
          });
        }
      }
      
      print('========== DATA PAKET LIST ==========');
      for (var paket in paketList) {
        print('ID: ${paket['id']}, Nama: ${paket['nama_paket'] ?? paket['nama']}, Kelas: ${paket['class_level']}');
      }
      print('======================================');
      
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
      if (paket['id'] == id) {
        return paket;
      }
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
    if (widget.mentorView) {
      if (_currentUser != null && _currentUser!.nama.isNotEmpty) {
        return _currentUser!.nama;
      }
      return 'Mentor';
    }
    final mentor = _findMentorById(mentorId);
    return mentor == null ? 'Mentor #$mentorId' : _mentorLabel(mentor);
  }

  String _resolveKelasFromJadwal(Map<String, dynamic> j) {
    final classLevel = j['class_level']?.toString();
    if (classLevel != null && classLevel.isNotEmpty && classLevel != 'null') {
      if (classLevel.contains('Kelas')) {
        return classLevel;
      }
      return 'Kelas $classLevel';
    }

    final paketId = j['paket_id'] as int?;
    if (paketId != null) {
      final paket = _findPaketById(paketId);
      if (paket != null) {
        final pkgClass = paket['class_level']?.toString();
        if (pkgClass != null && pkgClass.isNotEmpty && pkgClass != 'null') {
          if (pkgClass.contains('Kelas')) return pkgClass;
          return 'Kelas $pkgClass';
        }
        final title = _packageLabel(paket);
        if (title.toLowerCase().contains('kelas')) {
          return title.toLowerCase().startsWith('kelas') ? title : 'Kelas $title';
        }
        return 'Kelas ${paket['id']}';
      }
      return 'Kelas $paketId';
    }

    return '-';
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: const Text(
          'Hapus Jadwal?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda yakin ingin menghapus jadwal pembelajaran ini?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.warning, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aksi ini tidak bisa dibatalkan. Data absensi dan rekaman kehadiran terkait juga akan dihapus secara permanen dari sistem.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4B5563),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Hapus'),
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

    const warnaChip = Color(0xFF2563EB);

    final hariCell = DataCell(
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
    );

    final waktuCell = DataCell(Text('$jamMulai - $jamSelesai'));

    final kelasCell = DataCell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _resolveKelasFromJadwal(jadwal),
          style: const TextStyle(
            color: warnaChip,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );

    final mapelCell = DataCell(Text((jadwal['mata_pelajaran'] ?? '-').toString()));
    final mentorCell = DataCell(Text(_resolveMentorName(mentorId ?? 0)));
    final ruangCell = DataCell(Text((jadwal['ruang'] ?? '-').toString()));

    if (widget.mentorView) {
      return DataRow(
        cells: [
          hariCell,
          waktuCell,
          kelasCell,
          mapelCell,
          mentorCell,
          ruangCell,
        ],
      );
    } else {
      final aksiCell = DataCell(
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.blue),
              onPressed: () => _createOrUpdateJadwal(existing: jadwal),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () => _showDeleteDialog(jadwal['id'] as int),
            ),
          ],
        ),
      );
      return DataRow(
        cells: [
          hariCell,
          waktuCell,
          kelasCell,
          mapelCell,
          mentorCell,
          ruangCell,
          aksiCell,
        ],
      );
    }
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

    final mainContent = Container(
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
      child: SingleChildScrollView(
        physics: widget.embeddedInDashboard
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== HEADER INLINE ROW ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.mentorView
                            ? 'Jadwal yang ditetapkan admin untuk mentor yang sedang login'
                            : 'Jadwal utama yang berlaku setiap minggu secara berkelanjutan',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.mentorView)
                  ElevatedButton.icon(
                    onPressed: () => _createOrUpdateJadwal(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Jadwal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // ==================== STAT CARDS ====================
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Jadwal',
                    value: jadwalList.length.toString(),
                    subtitle: 'Kelas aktif per minggu',
                    color: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFEFF6FF),
                    icon: Icons.calendar_month_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    title: 'Jadwal Hari Ini',
                    value: _countJadwalHariIni().toString(),
                    subtitle: _formatIndoDate(DateTime.now()),
                    color: const Color(0xFF10B981),
                    backgroundColor: const Color(0xFFECFDF5),
                    icon: Icons.schedule_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ==================== FILTER SECTION ====================
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
                    child: _buildSafeDropdown(
                      value: selectedHari.isEmpty ? null : selectedHari,
                      hint: 'Semua Hari',
                      items: hariList,
                      onChanged: (value) {
                        setState(() => selectedHari = value ?? '');
                      },
                    ),
                  ),
                  if (!widget.mentorView) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSafeDropdown(
                        value: selectedMentorFilterId,
                        hint: 'Semua Mentor',
                        items: mentorList.map((m) => _mentorLabel(m)).toList(),
                        values: mentorList.map((m) => m['id'] as int).toList(),
                        onChanged: (value) {
                          setState(() => selectedMentorFilterId = value as int?);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==================== TABLE SECTION ====================
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6EDF7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Header dengan gradient biru
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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

                  // TABLE
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double screenWidth = constraints.maxWidth;
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
                            columnSpacing: 12,
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
    );

    if (widget.embeddedInDashboard) {
      return mainContent;
    }

    return MentorSidebarShell(
      activeMenuTitle: 'Jadwal Mengajar',
      onMenuTap: _onSidebarMenuTap,
      child: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: mainContent,
      ),
    );
  }

  Widget _buildSafeDropdown<T>({
    required T? value,
    required String hint,
    required List<String> items,
    List<T>? values,
    required void Function(T?) onChanged,
  }) {
    String displayLabel = hint;
    if (value != null) {
      if (values != null && values.isNotEmpty) {
        final idx = values.indexOf(value);
        if (idx >= 0 && idx < items.length) {
          displayLabel = items[idx];
        }
      } else {
        displayLabel = value.toString();
      }
    }

    final popupItems = (values != null && values.isNotEmpty)
        ? List.generate(items.length, (index) {
            return PopupMenuItem<T>(
              value: values[index],
              height: 38,
              child: Text(
                items[index],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
            );
          })
        : items.map((item) {
            return PopupMenuItem<T>(
              value: item as T,
              height: 38,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
            );
          }).toList();

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: PopupMenuButton<T>(
            tooltip: '',
            offset: const Offset(0, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            onSelected: onChanged,
            itemBuilder: (BuildContext context) => popupItems,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displayLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _StatCard
// =============================================================================

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
        gradient: LinearGradient(
          colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _JadwalFormDialog
// =============================================================================

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
  late TextEditingController _jamMulaiController;
  late TextEditingController _jamSelesaiController;
  late TextEditingController _ruangController;
  late String _selectedClass;
  late String _selectedMataPelajaran;
  bool _isSubmitting = false;

  final List<String> _classOptions = [
    '10 IPA',
    '11 IPA',
    '12 IPA',
    '10 IPS',
    '11 IPS',
    '12 IPS'
  ];

  final List<String> _mataPelajaranOptions = [
    'Matematika',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Fisika',
    'Kimia',
    'Biologi',
    'Sosiologi',
    'Ekonomi',
    'Geografi'
  ];

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
    _jamMulaiController = TextEditingController(
      text: existing == null ? '' : _timeToString(existing['jam_mulai']),
    );
    _jamSelesaiController = TextEditingController(
      text: existing == null ? '' : _timeToString(existing['jam_selesai']),
    );
    _ruangController = TextEditingController(
      text: existing?['ruang']?.toString() ?? '',
    );

    var existingClass = existing?['class_level']?.toString() ?? '';
    if (existingClass.isNotEmpty) {
      if (existingClass == 'Kelas 10') existingClass = '10 IPA';
      if (existingClass == 'Kelas 11') existingClass = '11 IPA';
      if (existingClass == 'Kelas 12') existingClass = '12 IPA';
      if (!_classOptions.contains(existingClass)) {
        _classOptions.add(existingClass);
      }
      _selectedClass = existingClass;
    } else {
      _selectedClass = '10 IPA';
    }

    final existingMapel = existing?['mata_pelajaran']?.toString() ?? '';
    if (existingMapel.isNotEmpty) {
      if (!_mataPelajaranOptions.contains(existingMapel)) {
        _mataPelajaranOptions.add(existingMapel);
      }
      _selectedMataPelajaran = existingMapel;
    } else {
      _selectedMataPelajaran = 'Matematika';
    }
  }

  @override
  void dispose() {
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
        minute: 0,
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
        'mata_pelajaran': _selectedMataPelajaran,
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

      if (result['success'] == true || _isSuccessResponseDynamic(result)) {
        Navigator.of(context).pop(true);
      } else {
        final msg = _extractResultMessageDynamic(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.isNotEmpty ? msg : 'Gagal menyimpan jadwal')),
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildSafeFormDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required List<String> labels,
    required void Function(T?) onChanged,
  }) {
    String displayLabel = hint;
    if (value != null) {
      final idx = items.indexOf(value);
      if (idx >= 0 && idx < labels.length) {
        displayLabel = labels[idx];
      }
    }

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: PopupMenuButton<T>(
            tooltip: '',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            onSelected: onChanged,
            itemBuilder: (BuildContext context) {
              return List.generate(items.length, (index) {
                return PopupMenuItem<T>(
                  value: items[index],
                  height: 38,
                  child: Text(
                    labels[index],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                );
              }).toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displayLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    );

    final screenHeight = MediaQuery.of(context).size.height;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 500,
          maxWidth: 500,
          maxHeight: screenHeight * 0.85,
        ),
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
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
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
                          existing == null ? 'Tambah Jadwal' : 'Edit Jadwal',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSafeFormDropdown<int>(
                        value: _selectedPaketId,
                        hint: 'Pilih Paket Les',
                        items: widget.paketList.map((p) => p['id'] as int).toList(),
                        labels: widget.paketList.map((p) => (p['nama_paket'] ?? p['nama'] ?? 'Paket').toString()).toList(),
                        onChanged: (v) => setState(() => _selectedPaketId = v),
                      ),
                      const SizedBox(height: 12),
                      _buildSafeFormDropdown<int>(
                        value: _selectedMentorId,
                        hint: 'Pilih Mentor',
                        items: widget.mentorList.map((m) => m['id'] as int).toList(),
                        labels: widget.mentorList.map((m) => (m['nama_mentor'] ?? m['nama'] ?? 'Mentor').toString()).toList(),
                        onChanged: (v) => setState(() => _selectedMentorId = v),
                      ),
                      const SizedBox(height: 12),
                      _buildSafeFormDropdown<String>(
                        value: _selectedHariValue,
                        hint: 'Pilih Hari',
                        items: _dialogHariList,
                        labels: _dialogHariList,
                        onChanged: (v) => setState(() => _selectedHariValue = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _jamMulaiController,
                        readOnly: true,
                        onTap: () => _pickAndSetTime(_jamMulaiController),
                        validator: (v) => v == null || v.isEmpty ? 'Jam mulai wajib diisi' : null,
                        decoration: InputDecoration(
                          labelText: 'Jam Mulai',
                          hintText: '08:00',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: fieldBorder,
                          enabledBorder: fieldBorder,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                          prefixIcon: const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF2563EB)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _jamSelesaiController,
                        readOnly: true,
                        onTap: () => _pickAndSetTime(_jamSelesaiController),
                        validator: (v) => v == null || v.isEmpty ? 'Jam selesai wajib diisi' : null,
                        decoration: InputDecoration(
                          labelText: 'Jam Selesai',
                          hintText: '09:30',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: fieldBorder,
                          enabledBorder: fieldBorder,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                          prefixIcon: const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF2563EB)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSafeFormDropdown<String>(
                        value: _selectedClass,
                        hint: 'Pilih Kelas',
                        items: _classOptions,
                        labels: _classOptions,
                        onChanged: (v) => setState(() => _selectedClass = v ?? _selectedClass),
                      ),
                      const SizedBox(height: 12),
                      _buildSafeFormDropdown<String>(
                        value: _selectedMataPelajaran,
                        hint: 'Pilih Mata Pelajaran',
                        items: _mataPelajaranOptions,
                        labels: _mataPelajaranOptions,
                        onChanged: (v) => setState(() => _selectedMataPelajaran = v ?? _selectedMataPelajaran),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ruangController,
                        validator: (v) => v == null || v.isEmpty ? 'Ruang wajib diisi' : null,
                        decoration: InputDecoration(
                          labelText: 'Ruang',
                          hintText: 'Ruang A',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: fieldBorder,
                          enabledBorder: fieldBorder,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                          prefixIcon: const Icon(Icons.meeting_room_outlined, size: 18, color: Color(0xFF2563EB)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ],
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
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD8E1EE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dialogHeaderBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(existing == null ? 'Simpan' : 'Update'),
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