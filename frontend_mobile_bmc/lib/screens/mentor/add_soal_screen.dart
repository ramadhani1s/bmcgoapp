import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/models/soal_model.dart';
import 'package:frontend_mobile_bmc/services/soal_service.dart';

class AddSoalScreen extends StatefulWidget {
  final String latihanId;
  final SoalModel? initialSoal;

  const AddSoalScreen({super.key, required this.latihanId, this.initialSoal});

  @override
  State<AddSoalScreen> createState() => _AddSoalScreenState();
}

class _AddSoalScreenState extends State<AddSoalScreen> {
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFD1D5DB);
  static const Color _accent = Color(0xFFFF6B35);
  static const Color _correct = Color(0xFF10B981);

  late TextEditingController _pertanyaanController;
  late TextEditingController _pilihanAController;
  late TextEditingController _pilihaBController;
  late TextEditingController _pilihanCController;
  late TextEditingController _pilihanDController;
  late TextEditingController _pembahasanController;

  String _kunciJawaban = 'A';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pertanyaanController = TextEditingController(
      text: widget.initialSoal?.pertanyaan ?? '',
    );
    _pilihanAController = TextEditingController(
      text: widget.initialSoal?.pilihan['A'] ?? '',
    );
    _pilihaBController = TextEditingController(
      text: widget.initialSoal?.pilihan['B'] ?? '',
    );
    _pilihanCController = TextEditingController(
      text: widget.initialSoal?.pilihan['C'] ?? '',
    );
    _pilihanDController = TextEditingController(
      text: widget.initialSoal?.pilihan['D'] ?? '',
    );
    _pembahasanController = TextEditingController(
      text: widget.initialSoal?.pembahasan ?? '',
    );
    _kunciJawaban = widget.initialSoal?.kunciJawaban ?? 'A';
  }

  @override
  void dispose() {
    _pertanyaanController.dispose();
    _pilihanAController.dispose();
    _pilihaBController.dispose();
    _pilihanCController.dispose();
    _pilihanDController.dispose();
    _pembahasanController.dispose();
    super.dispose();
  }

  Future<void> _saveSoal() async {
    if (_pertanyaanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pertanyaan tidak boleh kosong')),
      );
      return;
    }

    if (_pilihanAController.text.isEmpty ||
        _pilihaBController.text.isEmpty ||
        _pilihanCController.text.isEmpty ||
        _pilihanDController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua pilihan jawaban harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final soal =
          widget.initialSoal?.copyWith(
            pertanyaan: _pertanyaanController.text,
            pilihan: {
              'A': _pilihanAController.text,
              'B': _pilihaBController.text,
              'C': _pilihanCController.text,
              'D': _pilihanDController.text,
            },
            kunciJawaban: _kunciJawaban,
            pembahasan: _pembahasanController.text,
          ) ??
          SoalModel(
            id: 'soal_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}',
            latihanId: widget.latihanId,
            pertanyaan: _pertanyaanController.text,
            pilihan: {
              'A': _pilihanAController.text,
              'B': _pilihaBController.text,
              'C': _pilihanCController.text,
              'D': _pilihanDController.text,
            },
            kunciJawaban: _kunciJawaban,
            pembahasan: _pembahasanController.text,
            createdAt: DateTime.now(),
          );

      if (widget.initialSoal != null) {
        await SoalService.update(soal);
      } else {
        await SoalService.create(soal);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _answerOptionField(String label, TextEditingController controller) {
    final isSelected = _kunciJawaban == label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opsi $label *',
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: 'Tulis opsi $label...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: ElevatedButton(
                onPressed: () => setState(() => _kunciJawaban = label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? _correct
                      : const Color(0xFFE5E7EB),
                  foregroundColor: isSelected ? Colors.white : _textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  isSelected ? '✓ Kunci' : 'Set',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
        ),
        title: Text(
          widget.initialSoal != null ? 'Edit Soal' : 'Tambah Soal Baru',
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pertanyaan *',
                          style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pertanyaanController,
                          maxLines: null,
                          minLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Tulis pertanyaan di sini...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: _accent,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilihan Jawaban',
                          style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _answerOptionField('A', _pilihanAController),
                        const SizedBox(height: 12),
                        _answerOptionField('B', _pilihaBController),
                        const SizedBox(height: 12),
                        _answerOptionField('C', _pilihanCController),
                        const SizedBox(height: 12),
                        _answerOptionField('D', _pilihanDController),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pembahasan',
                          style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pembahasanController,
                          maxLines: null,
                          minLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Tulis pembahasan jawaban di sini...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: _accent,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSoal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              widget.initialSoal != null
                                  ? 'Perbarui Soal'
                                  : 'Tambah Soal',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
