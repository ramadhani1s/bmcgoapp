import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../models/soal_latihan.dart';
import '../dashboard/jadwal_pembelajaran_screen.dart';
import '../dashboard/mentor_attendance_screen.dart';
import '../dashboard/mentor_olimpiade_screen.dart';
import '../mentor/materi_pembelajaran_screen.dart';
import '../../services/latihan_soal_service.dart';
import '../../widgets/mentor_sidebar_shell.dart';
import 'create_latihan_screen.dart';
import 'mengelola_soal_screen.dart';

class LatihanSoalScreen extends StatefulWidget {
  const LatihanSoalScreen({super.key});

  @override
  State<LatihanSoalScreen> createState() => _LatihanSoalScreenState();
}

class _LatihanSoalScreenState extends State<LatihanSoalScreen> {
  bool _isLoading = true;
  List<SoalLatihan> _items = const [];
  final TextEditingController _searchController = TextEditingController();

  final List<String> _mapelOptions = const [
    'Matematika',
    'Fisika',
    'Kimia',
    'Biologi',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Ekonomi',
    'Geografi',
    'Sosiologi',
    'Sejarah',
  ];

  String _selectedClass = 'Semua Kelas';
  final List<String> _classOptions = const [
    'Semua Kelas',
    'Kelas 10 IPA',
    'Kelas 10 IPS',
    'Kelas 11 IPA',
    'Kelas 11 IPS',
    'Kelas 12 IPA',
    'Kelas 12 IPS',
  ];

  static const Color _primaryBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    final items = await LatihanSoalService.getSoalLatihan();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  void _onSidebarMenuTap(String title) {
    if (title == 'Dashboard') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorDashboard);
      return;
    }
    if (title == 'Jadwal Mengajar') {
      Navigator.pushReplacement(
        context,
        InstantPageRoute(
          child: const JadwalPembelajaranScreen(mentorView: true),
        ),
      );
      return;
    }
    if (title == 'Absensi Kelas') {
      Navigator.pushReplacement(
        context,
        InstantPageRoute(child: const MentorAttendanceScreen()),
      );
      return;
    }
    if (title == 'Soal Latihan') {
      return;
    }
    if (title == 'Try Out') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorTryout);
      return;
    }
    if (title == 'Materi Pembelajaran') {
      Navigator.pushReplacement(
        context,
        InstantPageRoute(
          child: const MateriPembelajaranScreen(initialClass: null),
        ),
      );
      return;
    }
    if (title == 'Olimpiade Akademik') {
      Navigator.pushReplacement(
        context,
        InstantPageRoute(child: const MentorOlimpiadeScreen()),
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openCreateForm() async {
    final result = await Navigator.push<bool?>(
      context,
      PageRouteBuilder<bool?>(
        opaque: false,
        pageBuilder: (ctx, animation, secondaryAnimation) =>
            CreateLatihanScreen(mapel: _mapelOptions.first),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );

    if (result == true) {
      await _loadItems();
      _showMessage('Latihan berhasil dibuat. Klik "Kelola Soal" untuk mengisi soal.');
    }
  }

  Future<void> _openEditLatihanDialog(
    String oldTitle,
    String mapel,
    String kelas,
    int durasi,
    int targetSoal,
    List<SoalLatihan> groupItems,
  ) async {
    final titleController = TextEditingController(text: oldTitle);
    final durationController = TextEditingController(text: durasi.toString());
    final targetController = TextEditingController(text: targetSoal.toString());
    String selectedClass = kelas;
    if (selectedClass == 'Kelas 10') selectedClass = 'Kelas 10 IPA';
    if (selectedClass == 'Kelas 11') selectedClass = 'Kelas 11 IPA';
    if (selectedClass == 'Kelas 12') selectedClass = 'Kelas 12 IPA';
    String selectedMapel = mapel;

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Informasi Latihan',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Judul Latihan',
                          border: fieldBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedMapel,
                        dropdownColor: Colors.white,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                        items: _mapelOptions
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setState(() => selectedMapel = v!),
                        decoration: InputDecoration(
                          labelText: 'Mata Pelajaran',
                          border: fieldBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedClass,
                        dropdownColor: Colors.white,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                        items: const [
                          'Kelas 10 IPA',
                          'Kelas 10 IPS',
                          'Kelas 11 IPA',
                          'Kelas 11 IPS',
                          'Kelas 12 IPA',
                          'Kelas 12 IPS'
                        ]
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => selectedClass = v!),
                        decoration: InputDecoration(
                          labelText: 'Kelas',
                          border: fieldBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: durationController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Durasi (menit)',
                                border: fieldBorder,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: targetController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Target Soal',
                                border: fieldBorder,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Simpan'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (saved != true) return;

    final newTitle = titleController.text.trim();
    final newDurasi = int.tryParse(durationController.text.trim()) ?? durasi;
    final newTarget = int.tryParse(targetController.text.trim()) ?? targetSoal;

    setState(() => _isLoading = true);
    try {
      int successCount = 0;
      for (final soal in groupItems) {
        final cleanText = soal.cleanPertanyaan;
        final newPertanyaan = SoalLatihan.buildPertanyaan(
          text: cleanText,
          kelas: selectedClass,
          mapel: selectedMapel,
          latihanTitle: newTitle,
          durasi: newDurasi,
          target: newTarget,
          isSkeletonFlag: soal.isSkeleton,
        );

        final res = await LatihanSoalService.updateSoalLatihan(
          soalId: soal.id,
          pertanyaan: newPertanyaan,
          pilihanA: soal.pilihanA,
          pilihanB: soal.pilihanB,
          pilihanC: soal.pilihanC,
          pilihanD: soal.pilihanD,
          jawaban: soal.jawaban,
          pembahasan: soal.pembahasan,
        );
        if (res['success'] == true) {
          successCount++;
        }
      }
      _showMessage('Latihan berhasil diperbarui ($successCount soal)');
    } catch (e) {
      _showMessage('Gagal memperbarui latihan: $e', isError: true);
    }
    await _loadItems();
  }

  Future<void> _deleteLatihan(String title, List<SoalLatihan> groupItems) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Hapus Latihan?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$title"? Semua soal di dalamnya akan dihapus permanen.',
            style: const TextStyle(color: Color(0xFF6B7280), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      int successCount = 0;
      for (final soal in groupItems) {
        final res = await LatihanSoalService.deleteSoalLatihan(soal.id);
        if (res['success'] == true) {
          successCount++;
        }
      }
      _showMessage('Berhasil menghapus latihan "$title" ($successCount soal)');
    } catch (e) {
      _showMessage('Gagal menghapus latihan: $e', isError: true);
    }
    await _loadItems();
  }

  Map<String, List<SoalLatihan>> _groupByLatihan(List<SoalLatihan> items) {
    final map = <String, List<SoalLatihan>>{};
    for (final item in items) {
      map.putIfAbsent(item.latihanTitle, () => <SoalLatihan>[]).add(item);
    }
    return map;
  }

  List<SoalLatihan> _filteredItems() {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesSearch = query.isEmpty ||
          item.pertanyaan.toLowerCase().contains(query) ||
          item.pilihanA.toLowerCase().contains(query) ||
          item.pilihanB.toLowerCase().contains(query) ||
          item.pilihanC.toLowerCase().contains(query) ||
          item.pilihanD.toLowerCase().contains(query) ||
          item.mapel.toLowerCase().contains(query) ||
          item.latihanTitle.toLowerCase().contains(query);

      final matchesClass = _selectedClass == 'Semua Kelas' ||
          item.pertanyaan.contains('[$_selectedClass]');

      return matchesSearch && matchesClass;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MentorSidebarShell(
      activeMenuTitle: 'Soal Latihan',
      onMenuTap: _onSidebarMenuTap,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 20),
                    _buildTopSummary(),
                    const SizedBox(height: 20),
                    _buildFilterAndList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Soal Latihan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Atur daftar latihan soal, detail soal, dan jadwal latihan secara konsisten.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          const Icon(Icons.menu_book_outlined, color: Colors.white, size: 64),
        ],
      ),
    );
  }

  Widget _buildTopSummary() {
    final filtered = _filteredItems();
    final grouped = _groupByLatihan(filtered);
    final totalLatihan = grouped.keys.length;
    final totalSoal = filtered.where((s) => !s.isSkeleton).length;
    final totalKelas = filtered.map((s) => s.kelas).toSet().length;
    final totalMapel = filtered.map((s) => s.mapel).toSet().length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 900) {
          final cardWidth = (width - (16 * 3)) / 4;
          return Row(
            children: [
              SizedBox(
                width: cardWidth,
                child: _buildSummaryCard(
                  Icons.view_list_outlined,
                  'Total Latihan',
                  totalLatihan.toString(),
                  _primaryBlue,
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: cardWidth,
                child: _buildSummaryCard(
                  Icons.help_outline,
                  'Total Soal',
                  totalSoal.toString(),
                  const Color(0xFF10B981),
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: cardWidth,
                child: _buildSummaryCard(
                  Icons.class_outlined,
                  'Kelas',
                  totalKelas.toString(),
                  const Color(0xFFF59E0B),
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: cardWidth,
                child: _buildSummaryCard(
                  Icons.menu_book_outlined,
                  'Mata Pelajaran',
                  totalMapel.toString(),
                  const Color(0xFF8B5CF6),
                  width: double.infinity,
                ),
              ),
            ],
          );
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSummaryCard(
                  Icons.view_list_outlined,
                  'Total Latihan',
                  totalLatihan.toString(),
                  _primaryBlue,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  Icons.help_outline,
                  'Total Soal',
                  totalSoal.toString(),
                  const Color(0xFF10B981),
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  Icons.class_outlined,
                  'Kelas',
                  totalKelas.toString(),
                  const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  Icons.menu_book_outlined,
                  'Mata Pelajaran',
                  totalMapel.toString(),
                  const Color(0xFF8B5CF6),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildSummaryCard(IconData icon, String label, String value, Color color, {double? width}) {
    return Container(
      width: width ?? 230,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
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
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndList() {
    final filtered = _filteredItems();
    final grouped = _groupByLatihan(filtered);
    final latihanKeys = grouped.keys.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        InputDecoration inputDecoration({
          String? hintText,
          Widget? prefixIcon,
        }) {
          return InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            filled: true,
            isDense: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.5,
              ),
            ),
          );
        }

        final searchField = TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: inputDecoration(
            hintText: 'Cari latihan...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
          ),
        );

        final classField = DropdownButtonFormField<String>(
          value: _selectedClass,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6B7280),
            size: 20,
          ),
          items: _classOptions
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                ),
              )
              .toList(),
          onChanged: (value) =>
              setState(() => _selectedClass = value ?? 'Semua Kelas'),
          decoration: inputDecoration(
            prefixIcon: const Icon(
              Icons.class_outlined,
              size: 18,
              color: Color(0xFF2563EB),
            ),
          ),
        );

        final addButton = ElevatedButton.icon(
          onPressed: _openCreateForm,
          icon: const Icon(Icons.add, size: 18),
          label: const Text(
            'Tambah Latihan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size(160, 48),
            maximumSize: const Size(200, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        );

        final filterRow = isWide
            ? Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 16),
                  SizedBox(width: 240, child: classField),
                  const SizedBox(width: 16),
                  addButton,
                ],
              )
            : Column(
                children: [
                  searchField,
                  const SizedBox(height: 10),
                  classField,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: addButton),
                ],
              );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              filterRow,
              const SizedBox(height: 24),
              if (latihanKeys.isEmpty)
                _buildEmptyState()
              else
                _buildCardGrid(grouped),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.assignment_late_outlined, size: 48, color: Color(0xFF9CA3AF)),
            SizedBox(height: 12),
            Text(
              'Tidak ada latihan ditemukan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
            ),
            SizedBox(height: 4),
            Text(
              'Silakan tambah latihan baru atau ubah filter pencarian.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGrid(Map<String, List<SoalLatihan>> grouped) {
    return LayoutBuilder(
      builder: (context, listConstraints) {
        final width = listConstraints.maxWidth;
        final keys = grouped.keys.toList();
        final columns = width >= 1500 ? 4 : (width >= 1100 ? 3 : (width >= 700 ? 2 : 1));
        final cardWidth = (width - ((columns - 1) * 16)) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: keys.map((key) {
            final list = grouped[key] ?? [];
            return SizedBox(
              width: cardWidth,
              child: _buildLatihanCard(key, list),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLatihanCard(String title, List<SoalLatihan> groupItems) {
    final first = groupItems.first;
    final mapel = first.mapel;
    final kelas = first.kelas;
    final durasi = first.durasi;
    final target = first.targetSoal;

    final realQuestions = groupItems.where((s) => !s.isSkeleton).toList();
    final progressCount = realQuestions.length;
    final progressValue = target <= 0 ? 0.0 : (progressCount / target).clamp(0.0, 1.0);
    final progressPercent = (progressValue * 100).round();
    final isPublished = progressCount >= target && target > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPublished ? 'Dipublikasikan' : 'Draft',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPublished ? const Color(0xFF065F46) : const Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                mapel,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  kelas,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$durasi menit',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$target soal',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.class_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        kelas,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$durasi mnt',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$progressCount/$target',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                '$progressPercent%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(_primaryBlue),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => MengelolaSoalScreen(
                            mapel: mapel,
                            latihanTitle: title,
                            targetSoal: target,
                            kelas: kelas,
                          ),
                        ),
                      ).then((_) => _loadItems());
                    },
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Kelola Soal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildActionIconButton(
                icon: Icons.edit_outlined,
                iconColor: const Color(0xFF6B7280),
                borderColor: const Color(0xFFD1D5DB),
                onPressed: () => _openEditLatihanDialog(title, mapel, kelas, durasi, target, groupItems),
                tooltip: 'Edit',
              ),
              const SizedBox(width: 8),
              _buildActionIconButton(
                icon: Icons.delete_outline,
                iconColor: const Color(0xFFEF4444),
                borderColor: const Color(0xFFFECACA),
                onPressed: () => _deleteLatihan(title, groupItems),
                tooltip: 'Hapus',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback? onPressed,
    required String tooltip,
    Color backgroundColor = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(child: Icon(icon, size: 18, color: iconColor)),
        ),
      ),
    );
  }
}
