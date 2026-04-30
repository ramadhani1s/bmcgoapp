import 'package:flutter/material.dart';

import '../../models/mentor_competition_item.dart';
import '../../models/soal_kompetisi.dart';
import '../../services/soal_kompetisi_service.dart';

class OlimpiadseSoalManagementScreen extends StatefulWidget {
  final MentorCompetitionItem olimpiade;

  const OlimpiadseSoalManagementScreen({super.key, required this.olimpiade});

  @override
  State<OlimpiadseSoalManagementScreen> createState() =>
      _OlimpiadseSoalManagementScreenState();
}

class _OlimpiadseSoalManagementScreenState
    extends State<OlimpiadseSoalManagementScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<SoalKompetisi> _soalList = [];
  SoalKompetisi? _editingItem;

  final TextEditingController _pertanyaanController = TextEditingController();
  final TextEditingController _pilihanAController = TextEditingController();
  final TextEditingController _pilihanBController = TextEditingController();
  final TextEditingController _pilihanCController = TextEditingController();
  final TextEditingController _pilihanDController = TextEditingController();
  final TextEditingController _pilihanEController = TextEditingController();
  final TextEditingController _pembahasanController = TextEditingController();

  String _selectedJawaban = 'A';

  @override
  void initState() {
    super.initState();
    _loadSoal();
  }

  @override
  void dispose() {
    _pertanyaanController.dispose();
    _pilihanAController.dispose();
    _pilihanBController.dispose();
    _pilihanCController.dispose();
    _pilihanDController.dispose();
    _pilihanEController.dispose();
    _pembahasanController.dispose();
    super.dispose();
  }

  Future<void> _loadSoal() async {
    setState(() => _isLoading = true);
    final soal = await SoalKompetisiService.getSoalByKompetisi(
      widget.olimpiade.id,
      'olimpiade',
    );
    if (!mounted) return;
    setState(() {
      _soalList = soal;
      _isLoading = false;
    });
  }

  void _clearForm() {
    _pertanyaanController.clear();
    _pilihanAController.clear();
    _pilihanBController.clear();
    _pilihanCController.clear();
    _pilihanDController.clear();
    _pilihanEController.clear();
    _pembahasanController.clear();
    _selectedJawaban = 'A';
    _editingItem = null;
  }

  Future<void> _submitSoal() async {
    if (_pertanyaanController.text.trim().isEmpty) {
      _showSnackbar('Pertanyaan harus diisi', isError: true);
      return;
    }

    if (_pilihanAController.text.trim().isEmpty ||
        _pilihanBController.text.trim().isEmpty ||
        _pilihanCController.text.trim().isEmpty ||
        _pilihanDController.text.trim().isEmpty) {
      _showSnackbar('Pilihan A-D harus diisi', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Map<String, dynamic> response;

      if (_editingItem == null) {
        response = await SoalKompetisiService.createSoal(
          kompetisiId: widget.olimpiade.id,
          tipe: 'olimpiade',
          pertanyaan: _pertanyaanController.text.trim(),
          pilihanA: _pilihanAController.text.trim(),
          pilihanB: _pilihanBController.text.trim(),
          pilihanC: _pilihanCController.text.trim(),
          pilihanD: _pilihanDController.text.trim(),
          pilihanE: _pilihanEController.text.trim(),
          jawaban: _selectedJawaban,
          pembahasan: _pembahasanController.text.trim(),
        );
      } else {
        response = await SoalKompetisiService.updateSoal(
          soalId: _editingItem!.id,
          tipe: 'olimpiade',
          pertanyaan: _pertanyaanController.text.trim(),
          pilihanA: _pilihanAController.text.trim(),
          pilihanB: _pilihanBController.text.trim(),
          pilihanC: _pilihanCController.text.trim(),
          pilihanD: _pilihanDController.text.trim(),
          pilihanE: _pilihanEController.text.trim(),
          jawaban: _selectedJawaban,
          pembahasan: _pembahasanController.text.trim(),
        );
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response['success'] == true) {
        _showSnackbar(response['message'] ?? 'Soal berhasil disimpan');
        _clearForm();
        await _loadSoal();
      } else {
        _showSnackbar(
          response['message'] ?? 'Gagal menyimpan soal',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackbar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _deleteSoal(SoalKompetisi soal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Soal?'),
        content: const Text('Soal ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final response = await SoalKompetisiService.deleteSoal(
      soal.id,
      'olimpiade',
    );
    if (!mounted) return;

    if (response['success'] == true) {
      _showSnackbar('Soal berhasil dihapus');
      await _loadSoal();
    } else {
      _showSnackbar(
        response['message'] ?? 'Gagal menghapus soal',
        isError: true,
      );
    }
  }

  void _editSoal(SoalKompetisi soal) {
    setState(() {
      _editingItem = soal;
      _pertanyaanController.text = soal.pertanyaan;
      _pilihanAController.text = soal.pilihanA;
      _pilihanBController.text = soal.pilihanB;
      _pilihanCController.text = soal.pilihanC;
      _pilihanDController.text = soal.pilihanD;
      _pilihanEController.text = soal.pilihanE;
      _pembahasanController.text = soal.pembahasan;
      _selectedJawaban = soal.jawaban;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
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
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Kelola Soal Olimpiade'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        widget.olimpiade.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_soalList.length}/${widget.olimpiade.totalQuestions} soal dibuat',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _editingItem == null
                                  ? 'Tambah Soal Baru'
                                  : 'Edit Soal',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Pertanyaan
                            const Text(
                              'Pertanyaan',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _pertanyaanController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Masukkan pertanyaan soal...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Pilihan Jawaban
                            const Text(
                              'Pilihan Jawaban',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPilihanInput('A', _pilihanAController),
                            const SizedBox(height: 8),
                            _buildPilihanInput('B', _pilihanBController),
                            const SizedBox(height: 8),
                            _buildPilihanInput('C', _pilihanCController),
                            const SizedBox(height: 8),
                            _buildPilihanInput('D', _pilihanDController),
                            const SizedBox(height: 8),
                            _buildPilihanInput('E', _pilihanEController),
                            const SizedBox(height: 16),

                            // Jawaban Benar
                            const Text(
                              'Jawaban Benar',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedJawaban,
                              items: ['A', 'B', 'C', 'D', 'E']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedJawaban = value);
                                }
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Pembahasan
                            const Text(
                              'Pembahasan (Opsional)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _pembahasanController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Masukkan pembahasan soal...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Action Buttons
                            Row(
                              children: [
                                if (_editingItem != null)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => _clearForm(),
                                      child: const Text('Batal Edit'),
                                    ),
                                  ),
                                if (_editingItem != null)
                                  const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSubmitting
                                        ? null
                                        : _submitSoal,
                                    icon: const Icon(Icons.add, size: 16),
                                    label: Text(
                                      _editingItem == null
                                          ? 'Tambah Soal'
                                          : 'Simpan Perubahan',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFB5607),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Daftar Soal
                      if (_soalList.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Center(
                            child: Text(
                              'Belum ada soal',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _soalList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final soal = _soalList[index];
                            return _buildSoalCard(soal, index + 1);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPilihanInput(String label, TextEditingController controller) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Pilihan $label',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSoalCard(SoalKompetisi soal, int nomer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4D3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$nomer',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFFFB5607),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      soal.pertanyaan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kunci: ${soal.jawaban}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Edit'),
                    onTap: () => _editSoal(soal),
                  ),
                  PopupMenuItem(
                    child: const Text(
                      'Hapus',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => _deleteSoal(soal),
                  ),
                ],
              ),
            ],
          ),
          if (soal.pembahasan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pembahasan:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    soal.pembahasan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
