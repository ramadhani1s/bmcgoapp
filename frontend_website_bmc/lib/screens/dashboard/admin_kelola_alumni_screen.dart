import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/alumni.dart';
import '../../services/alumni_service.dart';
import '../../services/auth_service.dart';
import 'alumni_profile_screen.dart';
import '../../utils/upload_helper.dart';

class AdminKelolaAlumniScreen extends StatefulWidget {
  const AdminKelolaAlumniScreen({super.key, this.embeddedInDashboard = false});

  final bool embeddedInDashboard;

  @override
  State<AdminKelolaAlumniScreen> createState() =>
      _AdminKelolaAlumniScreenState();
}

class _AdminKelolaAlumniScreenState extends State<AdminKelolaAlumniScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Alumni> _allAlumni = [];
  List<Alumni> _filteredAlumni = [];
  bool _isLoading = true;
  String _selectedTahun = 'Semua Tahun';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadAlumni();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlumni() async {
    setState(() => _isLoading = true);
    final alumni = await AlumniService.getAllAlumni();
    if (!mounted) return;

    setState(() {
      _allAlumni = alumni;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final keyword = _searchController.text.trim().toLowerCase();
    final selectedYear = int.tryParse(_selectedTahun);
    _filteredAlumni = _allAlumni.where((alumni) {
      final nameMatch =
          keyword.isEmpty || alumni.nama.toLowerCase().contains(keyword);
      final tahunMatch = _selectedTahun == 'Semua Tahun' ||
          (selectedYear != null && alumni.tahunLulus == selectedYear);
      return nameMatch && tahunMatch;
    }).toList();

    if (mounted) setState(() {});
  }

  Future<void> _openForm({Alumni? alumni}) async {
    final result = await _showFormModal(alumni: alumni);
    if (result is Map && result['success'] == true) {
      await _loadAlumni();
    }
  }

  List<String> _buildYearFilterOptions() {
    final years = <int>{
      2020,
      2021,
      2022,
      2023,
      2024,
      2025,
      2026,
      ..._allAlumni.map((alumni) => alumni.tahunLulus),
    };

    final sortedYears = years.toList()..sort();
    return [
      'Semua Tahun',
      ...sortedYears.map((year) => year.toString()),
    ];
  }

  Future<dynamic> _showFormModal({Alumni? alumni}) async {
    final namaController = TextEditingController(text: alumni?.nama ?? '');
    final sekolahController = TextEditingController(
      text: alumni?.sekolah ?? '',
    );
    final prestasiController = TextEditingController(
      text: alumni?.prestasi ?? '',
    );
    final tahunOptions = <int>[2020, 2021, 2022, 2023, 2024, 2025, 2026];
    int selectedTahun =
        alumni?.tahunLulus ?? DateTime.now().year.clamp(2020, 2026).toInt();
    if (!tahunOptions.contains(selectedTahun)) {
      tahunOptions.add(selectedTahun);
      tahunOptions.sort();
    }
    String? selectedFotoUrl = alumni?.foto;
    bool isSaving = false;

    final result = await showDialog<dynamic>(
      context: context,
      barrierColor: Colors.black.withAlpha(107),
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setStateDialog) {
          final messenger = ScaffoldMessenger.of(ctx);
          final bodyFont = GoogleFonts.plusJakartaSans();
          final titleStyle = GoogleFonts.dmSerifDisplay(
            color: Colors.white,
            fontSize: 22,
            height: 1.05,
          );

          final inputDecoration = InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF4B73F5),
                width: 1.5,
              ),
            ),
          );

          Future<void> submit(StateSetter setStateDialog) async {
            if (namaController.text.trim().isEmpty ||
                sekolahController.text.trim().isEmpty) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Harap isi nama dan sekolah'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            setStateDialog(() => isSaving = true);

            final alumniObj = Alumni(
              id: alumni?.id ?? 0,
              nama: namaController.text.trim(),
              sekolah: sekolahController.text.trim(),
              tahunLulus: selectedTahun,
              prestasi: prestasiController.text.trim().isEmpty
                  ? null
                  : prestasiController.text.trim(),
              foto: selectedFotoUrl,
            );

            final apiResult = alumni == null
                ? await AlumniService.createAlumni(alumniObj)
                : await AlumniService.updateAlumni(alumniObj);

            if (!ctx.mounted) return;
            setStateDialog(() => isSaving = false);

            messenger.showSnackBar(
              SnackBar(
                content: Text(apiResult['message'] ?? 'Selesai'),
                backgroundColor: apiResult['success'] == true
                    ? Colors.green
                    : Colors.red,
              ),
            );

            if (apiResult['success'] == true) {
              Navigator.of(
                ctx,
              ).pop(<String, dynamic>{'success': true, 'id': apiResult['id']});
            }
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            backgroundColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 700,
                maxHeight: MediaQuery.of(ctx).size.height * 0.9,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(15, 23, 42, 0.18),
                      blurRadius: 30,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(32, 28, 20, 24),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF1A3FA8),
                              Color(0xFF2F57D0),
                              Color(0xFF4B73F5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alumni == null
                                        ? 'Tambah Profil Alumni'
                                        : 'Edit Profil Alumni',
                                    style: titleStyle,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    alumni == null
                                        ? 'Isi detail alumni untuk ditampilkan pada halaman alumni'
                                        : 'Perbarui data alumni',
                                    style: bodyFont.copyWith(
                                      color: Colors.white.withAlpha(184),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _fieldWithLabel(
                                        font: bodyFont,
                                        label: 'Nama Alumni',
                                        requiredField: true,
                                        child: TextField(
                                          controller: namaController,
                                          style: bodyFont.copyWith(
                                            fontSize: 14,
                                            color: const Color(0xFF111827),
                                          ),
                                          decoration: inputDecoration.copyWith(
                                            hintText: 'Masukkan nama lengkap',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _fieldWithLabel(
                                        font: bodyFont,
                                        label: 'Sekolah',
                                        requiredField: true,
                                        child: TextField(
                                          controller: sekolahController,
                                          style: bodyFont.copyWith(
                                            fontSize: 14,
                                            color: const Color(0xFF111827),
                                          ),
                                          decoration: inputDecoration.copyWith(
                                            hintText: 'Nama sekolah asal',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _fieldWithLabel(
                                  font: bodyFont,
                                  label: 'Tahun Lulus',
                                  child: DropdownButtonFormField<int>(
                                    initialValue: tahunOptions.contains(selectedTahun)
                                      ? selectedTahun
                                      : tahunOptions.first,
                                    decoration: inputDecoration,
                                    style: bodyFont.copyWith(
                                      fontSize: 14,
                                      color: const Color(0xFF111827),
                                    ),
                                    items: tahunOptions
                                        .map(
                                          (year) => DropdownMenuItem<int>(
                                            value: year,
                                            child: Text('$year'),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setStateDialog(
                                        () => selectedTahun = value,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _fieldWithLabel(
                                  font: bodyFont,
                                  label: 'Foto',
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      border: Border.all(
                                        color: const Color(0xFFD1D5DB),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.image_outlined,
                                            color: Color(0xFF64748B),
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                (selectedFotoUrl?.isEmpty ??
                                                        true)
                                                    ? 'Belum ada foto'
                                                    : 'Foto sudah dipilih',
                                                style: bodyFont.copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF334155,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'JPG atau PNG. Disarankan ukuran foto wajah yang jelas.',
                                                style: bodyFont.copyWith(
                                                  fontSize: 12,
                                                  color: const Color(
                                                    0xFF64748B,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final url = await pickAndUpload();
                                            if (!ctx.mounted) return;
                                            if (url != null && url.isNotEmpty) {
                                              setStateDialog(() {
                                                selectedFotoUrl = url;
                                              });
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Foto berhasil diupload',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else {
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Gagal upload foto',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF22C55E,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 11,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text('Upload Foto'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _fieldWithLabel(
                                  font: bodyFont,
                                  label: 'Prestasi',
                                  child: TextField(
                                    controller: prestasiController,
                                    maxLines: 4,
                                    style: bodyFont.copyWith(
                                      fontSize: 14,
                                      color: const Color(0xFF111827),
                                    ),
                                    decoration: inputDecoration.copyWith(
                                      hintText:
                                          'Tuliskan prestasi atau pencapaian alumni...',
                                      alignLabelWithHint: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Batal'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => submit(setStateDialog),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2F57D0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 26,
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                alumni == null
                                    ? 'Tambah Alumni'
                                    : 'Simpan Perubahan',
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
        },
      ),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildMainPanel(embedded: widget.embeddedInDashboard);

    if (widget.embeddedInDashboard) {
      return Container(
        color: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.all(20),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Alumni'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildMainPanel({required bool embedded}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelola Alumni',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 32,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Buat, kelola, dan tampilkan profil alumni yang sudah lulus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Alumni'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 300,
            child: _statCard(
              title: 'Total Alumni',
              value: _allAlumni.length.toString(),
              icon: Icons.groups_outlined,
              backgroundColor: const Color(0xFFE6F0FF),
              valueColor: const Color(0xFF2563EB),
              iconBackground: const Color(0xFFD5E4FF),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.06),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daftar Alumni',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola dan lihat semua profil alumni yang telah dibuat',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withAlpha(220),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildFilterBar(),
                      const SizedBox(height: 16),
                      embedded
                          ? _buildListContent(embedded: true)
                          : SizedBox(
                              height: 520,
                              child: _buildListContent(embedded: false),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color backgroundColor,
    required Color valueColor,
    required Color iconBackground,
  }) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: valueColor.withAlpha(42)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: valueColor, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent({required bool embedded}) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Memuat data alumni...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredAlumni.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.badge_outlined,
                size: 36,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Belum ada alumni',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Klik tombol Tambah Alumni untuk menambahkan profil baru.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredAlumni.length,
      shrinkWrap: embedded,
      physics: embedded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildAlumniListItem(_filteredAlumni[index]),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama alumni...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9AA4B6)),
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
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 170,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Builder(builder: (_) {
              final items = _buildYearFilterOptions()
                  .map((tahun) => DropdownMenuItem(
                        value: tahun,
                        child: Text(tahun, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList();
              final hasSelected = items.any((it) => it.value == _selectedTahun);

              return DropdownButton<String>(
                value: hasSelected ? _selectedTahun : null,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.expand_more, color: Color(0xFF6B7280)),
                items: items,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTahun = value);
                    _applyFilters();
                  }
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildAlumniListItem(Alumni alumni) {
    final initial = alumni.nama.isNotEmpty ? alumni.nama[0].toUpperCase() : 'A';
    final photoUrl = _resolvePhotoUrl(alumni.foto);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              color: Colors.white,
            ),
            child: ClipOval(
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackAvatar(initial),
                    )
                  : _buildFallbackAvatar(initial),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  alumni.nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  alumni.sekolah,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _chip(
                      'Tahun ${alumni.tahunLulus}',
                      const Color(0xFFF3F0E7),
                      const Color(0xFF7C6A2A),
                    ),
                    if (alumni.prestasi != null &&
                        alumni.prestasi!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alumni.prestasi!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4B5563),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.visibility_outlined,
                    tooltip: 'Detail',
                    onPressed: () => _openAlumniProfilePage(alumni),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _actionButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    onPressed: () => _openForm(alumni: alumni),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _actionButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Hapus',
                    onPressed: () => _deleteAlumni(alumni),
                    danger: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAlumniProfilePage(Alumni alumni) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AlumniProfileScreen(alumni: alumni)),
    );
  }

  Future<void> _deleteAlumni(Alumni alumni) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Alumni'),
        content: Text(
          'Yakin ingin menghapus ${alumni.nama} dari daftar alumni?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await AlumniService.deleteAlumni(alumni.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Selesai'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );

    if (result['success'] == true) {
      _loadAlumni();
    }
  }

  Widget _chip(String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    final Color color = danger
        ? const Color(0xFFEF4444)
        : const Color(0xFF2563EB);
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.28)),
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          minimumSize: const Size(36, 36),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _fieldWithLabel({
    required TextStyle? font,
    required String label,
    required Widget child,
    bool requiredField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style:
                font?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ) ??
                const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
            children: [
              TextSpan(text: label),
              if (requiredField)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFE53E3E)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildFallbackAvatar(String initial) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, color: Colors.white, size: 20),
          const SizedBox(height: 2),
          Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  String? _resolvePhotoUrl(String? foto) {
    final value = foto?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/uploads/')) return '${AuthService.baseUrl}$value';
    return '${AuthService.baseUrl}/uploads/$value';
  }
}
