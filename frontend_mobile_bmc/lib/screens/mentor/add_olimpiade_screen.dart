import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/models/mentor_competition_item.dart';
import 'package:frontend_mobile_bmc/services/mentor_competition_service.dart';

class AddOlimpiadeScreen extends StatefulWidget {
  const AddOlimpiadeScreen({super.key, this.initialItem});

  final MentorCompetitionItem? initialItem;

  @override
  State<AddOlimpiadeScreen> createState() => _AddOlimpiadeScreenState();
}

class _AddOlimpiadeScreenState extends State<AddOlimpiadeScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFD1D5DB);
  static const Color _accent = Color(0xFF2563EB);

  final _judulController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _durasiController = TextEditingController();
  final _jadwalController = TextEditingController();

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialItem;
    if (initial == null) {
      _judulController.text = '';
      _jumlahController.text = '150';
      _durasiController.text = '2 Jam';
      _jadwalController.text = '';
      return;
    }

    _judulController.text = initial.title;
    _jumlahController.text = initial.totalQuestions.toString();
    _durasiController.text = initial.durationLabel;
    _jadwalController.text = initial.scheduleLabel;
    _selectedKelas = _kelasOptions.contains(initial.classLevel)
        ? initial.classLevel
        : _kelasOptions.last;
    _selectedMapel = _mapelOptions.contains(initial.subject)
        ? initial.subject
        : _mapelOptions.first;
  }

  @override
  void dispose() {
    _judulController.dispose();
    _jumlahController.dispose();
    _durasiController.dispose();
    _jadwalController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent, width: 1.6),
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

  Future<void> _save(bool publish) async {
    final title = _judulController.text.trim();
    final total = int.tryParse(_jumlahController.text.trim()) ?? 0;
    final duration = _durasiController.text.trim();

    if (title.isEmpty || total <= 0 || duration.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul, jumlah soal, dan durasi wajib diisi.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final item = MentorCompetitionItem(
      id:
          widget.initialItem?.id ??
          'olimpiade_${DateTime.now().millisecondsSinceEpoch}',
      type: 'olimpiade',
      classLevel: _selectedKelas,
      title: title,
      subject: _selectedMapel,
      totalQuestions: total,
      durationLabel: duration,
      scheduleLabel: _jadwalController.text.trim(),
      isPublished: publish,
      createdAt: widget.initialItem?.createdAt ?? DateTime.now(),
      categoryQuestions: const {},
    );

    await MentorCompetitionService.createOrUpdate(item);
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 2),
                const Text(
                  'Kembali',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.initialItem == null
                  ? 'Buat Soal Olimpiade Akademik'
                  : 'Edit Olimpiade Akademik',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 36,
                height: 1.05,
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
                    decoration: _fieldDecoration(
                      'Contoh: Latihan Matematika Bab 1',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _label('Kelas', required: true),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedKelas,
                    decoration: _fieldDecoration('Pilih Kelas'),
                    items: _kelasOptions
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
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
                  ),
                  const SizedBox(height: 12),
                  _label('Mata Pelajaran', required: true),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMapel,
                    decoration: _fieldDecoration('Pilih Mata Pelajaran'),
                    items: _mapelOptions
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
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
                  const SizedBox(height: 12),
                  _label('Jumlah Soal', required: true),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration('150'),
                  ),
                  const SizedBox(height: 12),
                  _label('Durasi', required: true),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _durasiController,
                    decoration: _fieldDecoration('2 Jam'),
                  ),
                  const SizedBox(height: 12),
                  _label('Jadwal Pelaksanaan'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _jadwalController,
                    decoration: _fieldDecoration('mm/dd/yyyy'),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kosongkan jika ingin menyimpan sebagai draft',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => _save(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      child: const Text('Simpan sebagai Draft'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _save(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text(
                        'Publikasikan',
                        style: TextStyle(color: Colors.white),
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
