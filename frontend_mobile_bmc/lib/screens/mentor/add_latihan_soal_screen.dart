import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/models/mentor_latihan_model.dart';
import 'package:frontend_mobile_bmc/services/mentor_latihan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddLatihanSoalScreen extends StatefulWidget {
  const AddLatihanSoalScreen({super.key, this.initialItem});

  final MentorLatihanModel? initialItem;

  @override
  State<AddLatihanSoalScreen> createState() => _AddLatihanSoalScreenState();
}

class _AddLatihanSoalScreenState extends State<AddLatihanSoalScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _accent = Color(0xFF2563EB);

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _jumlahSoalController = TextEditingController();
  final TextEditingController _durasiController = TextEditingController();
  final TextEditingController _jadwalController = TextEditingController();

  final List<String> _mapelOptions = const [
    'Matematika',
    'Fisika',
    'Kimia',
    'Biologi',
    'Bahasa Indonesia',
    'Bahasa Inggris',
  ];

  final List<String> _kelasOptions = const ['Kelas 10', 'Kelas 11', 'Kelas 12'];

  String _selectedKelas = 'Kelas 12';
  String _selectedMapel = 'Matematika';
  String _profileInitial = 'M';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _prefillData();
    _loadProfileInitial();
  }

  void _prefillData() {
    final item = widget.initialItem;
    if (item == null) {
      _judulController.text = 'Latihan Matematika Bab 1';
      _jumlahSoalController.text = '5';
      _durasiController.text = '20';
      _jadwalController.text = '30 April 2026';
      return;
    }

    _judulController.text = item.judul;
    _jumlahSoalController.text = item.jumlahSoal.toString();
    _durasiController.text = item.durasiMenit.toString();
    _jadwalController.text = item.jadwalPelaksanaan;
    _selectedKelas = _kelasOptions.contains(item.kelas)
        ? item.kelas
        : _kelasOptions.last;
    _selectedMapel = _mapelOptions.contains(item.mapel)
        ? item.mapel
        : _mapelOptions.first;
  }

  Future<void> _loadProfileInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = (prefs.getString('user_name') ?? '').trim();
    if (!mounted) {
      return;
    }

    setState(() {
      _profileInitial = userName.isEmpty ? 'M' : userName[0].toUpperCase();
    });
  }

  @override
  void dispose() {
    _judulController.dispose();
    _jumlahSoalController.dispose();
    _durasiController.dispose();
    _jadwalController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Future<void> _save({required bool publish}) async {
    final judul = _judulController.text.trim();
    final jumlah = int.tryParse(_jumlahSoalController.text.trim()) ?? 0;
    final durasi = int.tryParse(_durasiController.text.trim()) ?? 0;

    if (judul.isEmpty || jumlah <= 0 || durasi <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul, jumlah soal, dan durasi wajib valid.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await MentorLatihanService.createOrUpdate(
      id: widget.initialItem?.id,
      judul: judul,
      kelas: _selectedKelas,
      mapel: _selectedMapel,
      jumlahSoal: jumlah,
      durasiMenit: durasi,
      jadwalPelaksanaan: _jadwalController.text.trim(),
      isPublished: publish,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          publish
              ? 'Latihan berhasil dipublikasikan'
              : 'Draft berhasil disimpan',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.menu),
                      visualDensity: VisualDensity.compact,
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF4F46E5),
                      child: Text(
                        _profileInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notifikasi aktif')),
                            );
                          },
                          icon: const Icon(Icons.notifications_none_outlined),
                        ),
                        const Positioned(
                          right: 13,
                          top: 11,
                          child: CircleAvatar(
                            radius: 3,
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profil mentor')),
                        );
                      },
                      icon: const Icon(Icons.person_outline),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Kembali',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.initialItem == null
                          ? 'Buat Soal Latihan Baru'
                          : 'Edit Soal Latihan',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Isi form di bawah untuk membuat soal latihan',
                      style: TextStyle(color: _textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Judul Latihan', required: true),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _judulController,
                            decoration: _inputDecoration(
                              hintText: 'Contoh: Latihan Matematika Bab 1',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _label('Kelas', required: true),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedKelas,
                            items: _kelasOptions
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedKelas = value;
                              });
                            },
                            decoration: _inputDecoration(
                              hintText: 'Pilih kelas',
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Mata Pelajaran *',
                                        style: TextStyle(
                                          color: Color(0xFF374151),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFD1D5DB),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFE8FF),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.menu_book_outlined,
                                                color: Color(0xFF7C3AED),
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: DropdownButton<String>(
                                                isExpanded: true,
                                                value: _selectedMapel,
                                                underline: const SizedBox(),
                                                items: _mapelOptions
                                                    .map(
                                                      (
                                                        item,
                                                      ) => DropdownMenuItem<String>(
                                                        value: item,
                                                        child: Text(
                                                          item,
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF111827,
                                                                ),
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                                onChanged: (value) {
                                                  if (value == null) {
                                                    return;
                                                  }
                                                  setState(() {
                                                    _selectedMapel = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _label('Jumlah Soal', required: true),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _jumlahSoalController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(hintText: '5'),
                          ),
                          const SizedBox(height: 12),
                          _label('Durasi (Menit)', required: true),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _durasiController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(hintText: '20'),
                          ),
                          const SizedBox(height: 12),
                          _label('Jadwal Pelaksanaan'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _jadwalController,
                            decoration: _inputDecoration(
                              hintText: '30 April 2026',
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Kosongkan jika ingin menyimpan sebagai draft',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _save(publish: false),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Simpan sebagai Draft'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _save(publish: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Publikasikan'),
                            ),
                          ),
                        ],
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
