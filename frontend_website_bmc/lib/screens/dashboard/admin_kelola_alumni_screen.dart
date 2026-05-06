import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/alumni.dart';
import '../../services/alumni_service.dart';
import '../../services/auth_service.dart';
import '../../utils/upload_helper.dart'
    if (dart.library.html) '../../utils/upload_helper.dart';
// upload_helper exposes uploadFile(file) for web; stub on other platforms

class AdminKelolaAlumniScreen extends StatefulWidget {
  const AdminKelolaAlumniScreen({super.key, this.embeddedInDashboard = false});

  final bool embeddedInDashboard;

  @override
  State<AdminKelolaAlumniScreen> createState() =>
      _AdminKelolaAlumniScreenState();
}

class _AdminKelolaAlumniScreenState extends State<AdminKelolaAlumniScreen> {
  List<Alumni> _allAlumni = [];
  List<Alumni> _filteredAlumni = [];
  bool _isLoading = true;
  final Map<int, bool> _uploadingFoto = {};
  String _selectedTahun = 'Semua Tahun';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tahunList = [
    'Semua Tahun',
    '2020',
    '2021',
    '2022',
    '2023',
    '2024',
    '2025',
    '2026',
  ];

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
    if (mounted) {
      setState(() {
        _allAlumni = alumni;
        _isLoading = false;
      });
      _applyFilters();
    }
    if (!_isLoading && _allAlumni.isEmpty) {
      // show hint to admin that load returned empty — helps diagnose connectivity
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data alumni atau gagal memuat data'),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final keyword = _searchController.text.trim().toLowerCase();

    _filteredAlumni = _allAlumni.where((alumni) {
      final nameMatch =
          keyword.isEmpty || alumni.nama.toLowerCase().contains(keyword);
      final tahunMatch =
          _selectedTahun == 'Semua Tahun' ||
          alumni.tahunLulus == int.parse(_selectedTahun);

      return nameMatch && tahunMatch;
    }).toList();

    if (mounted) setState(() {});
  }

  Future<void> _openForm({Alumni? alumni}) async {
    final result = await _showFormModal(alumni: alumni);

    // If form returned created item details, append locally and refresh
    if (result is Map && result['success'] == true && result['id'] != null) {
      final newId = (result['id'] as num).toInt();
      final created = Alumni(
        id: newId,
        nama: (result['nama'] ?? '') as String,
        sekolah: (result['sekolah'] ?? '') as String,
        tahunLulus: (result['tahun_lulus'] is int)
            ? result['tahun_lulus'] as int
            : int.tryParse((result['tahun_lulus'] ?? '').toString()) ??
                  DateTime.now().year,
        prestasi: result['prestasi']?.toString(),
        foto: result['foto']?.toString(),
      );
      setState(() {
        _allAlumni.insert(0, created);
        _applyFilters();
      });

      try {
        final fresh = await AlumniService.getAllAlumni();
        if (fresh.isNotEmpty && mounted) {
          setState(() {
            _allAlumni = fresh;
            _applyFilters();
          });
        }
      } catch (_) {}
    } else if (result == true) {
      _loadAlumni();
    }
  }

  Future<dynamic> _showFormModal({Alumni? alumni}) async {
    final namaController = TextEditingController(
      text: alumni?.nama ?? '',
    );
    final sekolahController = TextEditingController(
      text: alumni?.sekolah ?? '',
    );
    final prestasiController = TextEditingController(
      text: alumni?.prestasi ?? '',
    );
    final tahunOptions = <int>[2020, 2021, 2022, 2023, 2024, 2025, 2026];
    int selectedTahun = tahunOptions.contains(alumni?.tahunLulus)
        ? alumni!.tahunLulus
        : DateTime.now().year.clamp(2020, 2026);
    String? selectedFotoUrl = alumni?.foto;
    bool isSaving = false;

    final result = await showDialog<dynamic>(
      context: context,
      barrierColor: Colors.black.withAlpha(107),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final messenger = ScaffoldMessenger.of(ctx);

          Future<void> submit() async {
            if (namaController.text.trim().isEmpty ||
                sekolahController.text.trim().isEmpty) {
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Harap isi nama dan sekolah'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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

            final result = alumni == null
                ? await AlumniService.createAlumni(alumniObj)
                : await AlumniService.updateAlumni(alumniObj);

            setStateDialog(() => isSaving = false);

            if (!mounted) return;
            if (!ctx.mounted) return;

            messenger.showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: result['success'] ? Colors.green : Colors.red,
              ),
            );

            if (result['success']) {
              final ret = <String, dynamic>{
                'success': true,
                'id': result['id'],
              };
              ret.addAll({
                'nama': alumniObj.nama,
                'sekolah': alumniObj.sekolah,
                'tahun_lulus': alumniObj.tahunLulus,
                'prestasi': alumniObj.prestasi,
                'foto': alumniObj.foto,
              });
              Navigator.of(ctx).pop(ret);
            }
          }

          final titleStyle = GoogleFonts.dmSerifDisplay(
            color: Colors.white,
            fontSize: 22,
            height: 1.05,
          );
          final bodyFont = GoogleFonts.plusJakartaSans();

          InputDecoration inputDecoration = InputDecoration(
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
              borderSide: const BorderSide(color: Color(0xFF4B73F5), width: 1.5),
            ),
          );

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
                            colors: [Color(0xFF1A3FA8), Color(0xFF2F57D0), Color(0xFF4B73F5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 4),
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
                              mainAxisSize: MainAxisSize.min,
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
                                    initialValue: selectedTahun,
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
                                      setStateDialog(() => selectedTahun = value);
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
                                            borderRadius: BorderRadius.circular(12),
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  color: const Color(0xFF334155),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'JPG atau PNG. Disarankan ukuran foto wajah yang jelas.',
                                                style: bodyFont.copyWith(
                                                  fontSize: 12,
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final url = await pickAndUpload();
                                            if (url != null && url.isNotEmpty) {
                                              setStateDialog(() {
                                                selectedFotoUrl = url;
                                              });
                                              if (mounted) {
                                                messenger.showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Foto berhasil diupload'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                            } else {
                                              if (mounted) {
                                                messenger.showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Gagal upload foto'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF22C55E),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 11,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(9),
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
                                const SizedBox(height: 8),
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
                              onPressed: isSaving ? null : submit,
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
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );

    if (result['success']) {
      _loadAlumni();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInDashboard) {
      return Container(
        color: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildFilterBar()),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Alumni'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildListContent(),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Kelola Profil Alumni',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Alumni'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterBar(),
            const SizedBox(height: 20),
            Expanded(child: _buildListContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 16),
              Text(
                'Memuat data alumni...',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredAlumni.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.badge_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada alumni ditemukan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coba ubah filter atau tambahkan alumni baru',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredAlumni.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final alumni = _filteredAlumni[index];
        return _buildAlumniListItem(alumni);
      },
    );
  }

  Widget _buildFilterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari nama alumni...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9AA4B6)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButton<String>(
                  value: _selectedTahun,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.expand_more, color: Color(0xFF6B7280)),
                  items: _tahunList
                      .map(
                        (tahun) => DropdownMenuItem(
                          value: tahun,
                          child: Text(
                            tahun,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTahun = value);
                      _applyFilters();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedTahun = 'Semua Tahun';
                  _searchController.clear();
                });
                _applyFilters();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
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
          // Photo
          Stack(
            alignment: Alignment.center,
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
                          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(initial),
                        )
                      : _buildFallbackAvatar(initial),
                ),
              ),
              Positioned(
                right: -6,
                bottom: -6,
                child: SizedBox(
                  width: 36,
                  height: 36,
                          child: _uploadingFoto[alumni.id] == true
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          color: const Color(0xFF2563EB),
                          tooltip: 'Upload Foto',
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _uploadingFoto[alumni.id] = true);
                            final url = await pickAndUpload();
                            if (url != null && url.isNotEmpty) {
                              final updated = Alumni(
                                id: alumni.id,
                                nama: alumni.nama,
                                sekolah: alumni.sekolah,
                                tahunLulus: alumni.tahunLulus,
                                prestasi: alumni.prestasi,
                                foto: url,
                              );
                              final res = await AlumniService.updateAlumni(
                                updated,
                              );
                              if (res['success'] == true) {
                                // update local list
                                setState(() {
                                  final idx = _allAlumni.indexWhere(
                                    (a) => a.id == alumni.id,
                                  );
                                  if (idx != -1) {
                                    _allAlumni[idx] = updated;
                                  }
                                  _applyFilters();
                                });
                                if (mounted) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Foto berhasil diperbarui'),
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res['message'] ?? 'Gagal memperbarui foto',
                                      ),
                                    ),
                                  );
                                }
                              }
                            } else {
                              if (mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Gagal upload foto'),
                                  ),
                                );
                              }
                            }
                            setState(() => _uploadingFoto.remove(alumni.id));
                          },
                        ),
                ),
              ),
            ],
          ),
              const SizedBox(width: 12),
          // Info
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
          // Actions
          SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.visibility_outlined,
                    tooltip: 'Detail',
                    onPressed: () => _showDetailModal(alumni),
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

  void _showDetailModal(Alumni alumni) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(alumni.nama),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (alumni.sekolah.isNotEmpty) Text('Sekolah: ${alumni.sekolah}'),
            const SizedBox(height: 6),
            Text('Tahun Lulus: ${alumni.tahunLulus}'),
            const SizedBox(height: 6),
            if (alumni.prestasi != null && alumni.prestasi!.isNotEmpty)
              Text('Prestasi: ${alumni.prestasi}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
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
        : const Color(0xFF8B5E57);
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
    if (value.startsWith('/uploads/')) {
      return '${AuthService.baseUrl}$value';
    }
    return '${AuthService.baseUrl}/uploads/$value';
  }
}
