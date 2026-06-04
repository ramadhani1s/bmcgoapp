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
          final titleStyle = GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F9FF), Color(0xFFF3F6FB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: content,
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F9FF), Color(0xFFF3F6FB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: content,
      ),
    );
  }

  Widget _buildMainPanel({required bool embedded}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Kelola Alumni',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kelola dan tampilkan seluruh data alumni yang telah lulus dari BMC',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Alumni'),
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
                _statCard(
                  'Total Alumni',
                  _allAlumni.length.toString(),
                  const Color(0xFF2563EB),
                  Icons.groups_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6EDF7)),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.05),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Daftar Alumni',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Data alumni ditampilkan secara dinamis',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFDBEAFE),
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
                        _buildTableHeader(),
                        _buildListContent(embedded: true),
                      ],
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

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              'FOTO',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'NAMA',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'SEKOLAH',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'TAHUN LULUS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'PRESTASI',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'AKSI',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlumniRow(Alumni alumni) {
    final initial = alumni.nama.isNotEmpty ? alumni.nama[0].toUpperCase() : 'A';
    final photoUrl = _resolvePhotoUrl(alumni.foto);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackAvatar(initial),
                        )
                      : _buildFallbackAvatar(initial),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              alumni.nama,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1F2937),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              alumni.sekolah,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${alumni.tahunLulus}',
                  style: const TextStyle(
                    color: Color(0xFF7C6A2A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              (alumni.prestasi?.isNotEmpty == true) ? alumni.prestasi! : '-',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _openAlumniProfilePage(alumni),
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Detail',
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _openForm(alumni: alumni),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit',
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteAlumni(alumni),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent({required bool embedded}) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredAlumni.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Belum ada alumni',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredAlumni.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => _buildAlumniRow(_filteredAlumni[index]),
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
              hintStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFF9CA3AF),
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9AA4B6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
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
                vertical: 18,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
          ),
          child: Builder(builder: (_) {
            final items = _buildYearFilterOptions()
                .map((tahun) => DropdownMenuItem(
                      value: tahun,
                      child: Text(
                        tahun,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
      ],
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
            style: font?.copyWith(
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
