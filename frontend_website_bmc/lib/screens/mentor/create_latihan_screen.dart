import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/materi_service.dart';
import '../../models/materi_pembelajaran.dart';

import 'mengelola_soal_screen.dart';

class CreateLatihanScreen extends StatefulWidget {
  final String mapel;
  final int? materiId;

  const CreateLatihanScreen({super.key, required this.mapel, this.materiId});

  @override
  State<CreateLatihanScreen> createState() => _CreateLatihanScreenState();
}

class _CreateLatihanScreenState extends State<CreateLatihanScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _jumlahSoalController = TextEditingController();
  final TextEditingController _durasiController = TextEditingController();

  final List<String> _mapelOptions = const [
    'Matematika',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Fisika',
    'Kimia',
    'Biologi',
    'Sosiologi',
    'Ekonomi',
    'Geografi',
  ];

  final List<String> _classOptions = const [
    '10 IPA IPS',
    '11 IPA IPS',
    '12 IPA IPS',
  ];

  String? _selectedMapel;
  String? _selectedClass;
  bool _isSubmitting = false;

  List<MateriPembelajaran> _materiList = [];
  bool _isLoadingMateri = true;
  int? _selectedMateriId;

  @override
  void initState() {
    super.initState();
    _selectedMapel = _mapelOptions.contains(widget.mapel)
        ? widget.mapel
        : _mapelOptions.first;
    _selectedMateriId = widget.materiId;
    _loadMateri();
  }

  Future<void> _loadMateri() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        final data = await MateriService.getMateri(user.id);
        if (mounted) {
          setState(() {
            _materiList = data;
            // If we don't have a pre-selected materi but we have options, select the first one
            if (_selectedMateriId == null && data.isNotEmpty) {
              _selectedMateriId = data.first.id;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load materi: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMateri = false);
      }
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _jumlahSoalController.dispose();
    _durasiController.dispose();
    super.dispose();
  }

  int _parseJumlahSoal() {
    final value = int.tryParse(_jumlahSoalController.text.trim());
    if (value == null || value <= 0) return 5;
    return value.clamp(1, 50);
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedMateriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materi Pembelajaran wajib dipilih'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final jumlah = _parseJumlahSoal();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MengelolaSoalScreen(
          mapel: _selectedMapel!,
          latihanTitle: _judulController.text.trim(),
          targetSoal: jumlah,
          kelas: _selectedClass,
          materiId: _selectedMateriId,
        ),
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  InputDecoration _fieldDecoration({
    required String label,
    required OutlineInputBorder base,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: base,
      enabledBorder: base,
      focusedBorder: base.copyWith(
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    );

    return Scaffold(
      backgroundColor: const Color.fromRGBO(17, 24, 39, 0.32),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
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
                            _buildHeader(),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                                child: SingleChildScrollView(
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
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

                                        // Judul
                                        TextFormField(
                                          controller: _judulController,
                                          validator: (v) =>
                                              v == null || v.trim().isEmpty
                                                  ? 'Judul latihan wajib diisi'
                                                  : null,
                                          decoration: _fieldDecoration(
                                            label: 'Judul Latihan',
                                            hint: 'Masukkan judul latihan',
                                            base: fieldBorder,
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // Mata Pelajaran
                                        DropdownButtonFormField<String>(
                                          value: _selectedMapel,
                                          hint: const Text('Pilih Mata Pelajaran'),
                                          dropdownColor: Colors.white,
                                          style: const TextStyle(
                                            color: Color(0xFF111827),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                                  ? 'Mata pelajaran wajib dipilih'
                                                  : null,
                                          items: _mapelOptions
                                              .map((mapel) => DropdownMenuItem(
                                                    value: mapel,
                                                    child: Text(mapel),
                                                  ))
                                              .toList(),
                                          onChanged: (v) {
                                            if (v == null) return;
                                            setState(() => _selectedMapel = v);
                                          },
                                          decoration: _fieldDecoration(
                                            label: 'Mata Pelajaran',
                                            base: fieldBorder,
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // Materi Pembelajaran
                                        if (_isLoadingMateri)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 8),
                                            child: Center(child: CircularProgressIndicator()),
                                          )
                                        else
                                          DropdownButtonFormField<int>(
                                            value: _selectedMateriId,
                                            hint: const Text('Pilih Materi Pembelajaran'),
                                            dropdownColor: Colors.white,
                                            isExpanded: true,
                                            style: const TextStyle(
                                              color: Color(0xFF111827),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            validator: (v) =>
                                                v == null
                                                    ? 'Materi Pembelajaran wajib dipilih'
                                                    : null,
                                            items: _materiList.map((materi) {
                                              return DropdownMenuItem<int>(
                                                value: materi.id,
                                                child: Text(
                                                  materi.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (v) {
                                              if (v == null) return;
                                              setState(() => _selectedMateriId = v);
                                            },
                                            decoration: _fieldDecoration(
                                              label: 'Materi Pembelajaran',
                                              base: fieldBorder,
                                            ),
                                          ),
                                        const SizedBox(height: 10),

                                        // Durasi
                                        TextFormField(
                                          controller: _durasiController,
                                          keyboardType: TextInputType.number,
                                          validator: (v) {
                                            final value = v?.trim() ?? '';
                                            if (value.isEmpty) return 'Durasi wajib diisi';
                                            if (int.tryParse(value) == null) {
                                              return 'Durasi harus berupa angka';
                                            }
                                            return null;
                                          },
                                          decoration: _fieldDecoration(
                                            label: 'Durasi (Menit)',
                                            hint: 'Masukkan durasi',
                                            base: fieldBorder,
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // Jumlah Soal
                                        TextFormField(
                                          controller: _jumlahSoalController,
                                          keyboardType: TextInputType.number,
                                          validator: (v) {
                                            final value = int.tryParse((v ?? '').trim());
                                            if (value == null || value <= 0) {
                                              return 'Jumlah soal harus lebih dari 0';
                                            }
                                            return null;
                                          },
                                          decoration: _fieldDecoration(
                                            label: 'Total Soal',
                                            hint: 'Masukkan jumlah soal',
                                            base: fieldBorder,
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // Kelas
                                        DropdownButtonFormField<String>(
                                          value: _selectedClass,
                                          hint: const Text('Pilih Kelas'),
                                          dropdownColor: Colors.white,
                                          style: const TextStyle(
                                            color: Color(0xFF111827),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                                  ? 'Kelas wajib dipilih'
                                                  : null,
                                          items: _classOptions
                                              .map((c) => DropdownMenuItem(
                                                    value: c,
                                                    child: Text(c),
                                                  ))
                                              .toList(),
                                          onChanged: (v) {
                                            if (v == null) return;
                                            setState(() => _selectedClass = v);
                                          },
                                          decoration: _fieldDecoration(
                                            label: 'Kelas',
                                            base: fieldBorder,
                                          ),
                                        ),
                                        const SizedBox(height: 18),

                                        // Tombol aksi
                                        _buildActionButtons(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
            child: const Icon(Icons.add, color: Colors.white, size: 20),
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
                  'Form Latihan',
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
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                _isSubmitting ? null : () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFD8E1EE)),
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
            onPressed: _isSubmitting ? null : _publish,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Simpan'),
          ),
        ),
      ],
    );
  }
}