import 'package:flutter/material.dart';
import '../../services/paket_les_service.dart';

class PaketLesScreen extends StatefulWidget {
  const PaketLesScreen({super.key});

  @override
  State<PaketLesScreen> createState() => _PaketLesScreenState();
}

class _PaketLesScreenState extends State<PaketLesScreen> {
  // STATE
  List<Map<String, dynamic>> paketList = [];
  Map<String, dynamic> stats = {'total_paket': 0, 'paket_aktif': 0};
  bool isLoading = true;
  String selectedStatus = 'aktif';

  // CONTROLLERS
  final namaController = TextEditingController();
  final hargaController = TextEditingController();
  final diskonController = TextEditingController();
  final durasiController = TextEditingController();
  final deskripsiController = TextEditingController();
  DateTime? tanggalMulaiPromo;
  DateTime? tanggalSelesaiPromo;

  @override
  void initState() {
    super.initState();
    _loadPaketList();
    _loadStats();
  }

  Future<void> _loadPaketList() async {
    setState(() => isLoading = true);
    final list = await PaketLesService.getPaketLesList();
    setState(() {
      paketList = list;
      isLoading = false;
    });
  }

  Future<void> _loadStats() async {
    final newStats = await PaketLesService.getPaketStats();
    setState(() => stats = newStats);
  }

  void _clearControllers() {
    namaController.clear();
    hargaController.clear();
    diskonController.clear();
    durasiController.clear();
    deskripsiController.clear();
    tanggalMulaiPromo = null;
    tanggalSelesaiPromo = null;
    selectedStatus = 'aktif';
  }

  @override
  void dispose() {
    namaController.dispose();
    hargaController.dispose();
    diskonController.dispose();
    durasiController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _createPaket() async {
    // Validasi field required
    if (namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Γ¥î Nama Paket wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (hargaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Γ¥î Harga Awal wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Parse harga
    int? hargaAwal;
    try {
      hargaAwal = int.parse(
        hargaController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Γ¥î Harga harus berupa angka"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (hargaAwal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Γ¥î Harga harus lebih dari 0"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final data = {
        "nama_paket": namaController.text.trim(),
        "harga_awal": hargaAwal,
        "diskon":
            int.tryParse(
              diskonController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0,
        "durasi":
            int.tryParse(
              durasiController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0,
        "deskripsi": deskripsiController.text.trim().isNotEmpty
            ? deskripsiController.text.trim()
            : null,
        "tanggal_mulai_promo": tanggalMulaiPromo != null
            ? "${tanggalMulaiPromo!.year.toString().padLeft(4, '0')}-${tanggalMulaiPromo!.month.toString().padLeft(2, '0')}-${tanggalMulaiPromo!.day.toString().padLeft(2, '0')}"
            : null,
        "tanggal_selesai_promo": tanggalSelesaiPromo != null
            ? "${tanggalSelesaiPromo!.year.toString().padLeft(4, '0')}-${tanggalSelesaiPromo!.month.toString().padLeft(2, '0')}-${tanggalSelesaiPromo!.day.toString().padLeft(2, '0')}"
            : null,
        "status": selectedStatus,
      };

      print("≡ƒÜÇ CREATE PAKET: $data");

      final response = await PaketLesService.createPaket(data);

      if (mounted) {
        if (response['status'] == 'success') {
          _clearControllers();
          await _loadPaketList();
          await _loadStats();
          if (mounted) Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Γ£à Paket les berhasil dibuat"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Γ¥î ${response['message'] ?? 'Gagal membuat paket'} (${response['detail'] ?? ''})",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Γ¥î Exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Γ¥î Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updatePaket(int paketId) async {
    // Validasi field required
    if (namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Γ¥î Nama Paket wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (hargaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Γ¥î Harga Awal wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Parse harga
    int? hargaAwal;
    try {
      hargaAwal = int.parse(
        hargaController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Γ¥î Harga harus berupa angka"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (hargaAwal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Γ¥î Harga harus lebih dari 0"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final data = {
        "nama_paket": namaController.text.trim(),
        "harga_awal": hargaAwal,
        "diskon":
            int.tryParse(
              diskonController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0,
        "durasi":
            int.tryParse(
              durasiController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0,
        "deskripsi": deskripsiController.text.trim().isNotEmpty
            ? deskripsiController.text.trim()
            : null,
        "tanggal_mulai_promo": tanggalMulaiPromo != null
            ? "${tanggalMulaiPromo!.year.toString().padLeft(4, '0')}-${tanggalMulaiPromo!.month.toString().padLeft(2, '0')}-${tanggalMulaiPromo!.day.toString().padLeft(2, '0')}"
            : null,
        "tanggal_selesai_promo": tanggalSelesaiPromo != null
            ? "${tanggalSelesaiPromo!.year.toString().padLeft(4, '0')}-${tanggalSelesaiPromo!.month.toString().padLeft(2, '0')}-${tanggalSelesaiPromo!.day.toString().padLeft(2, '0')}"
            : null,
        "status": selectedStatus,
      };

      print("Γ£Å∩╕Å UPDATE PAKET $paketId: $data");

      final response = await PaketLesService.updatePaket(paketId, data);

      if (mounted) {
        if (response['status'] == 'success') {
          await _loadPaketList();
          await _loadStats();
          if (mounted) Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Γ£à Paket les berhasil diupdate"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Γ¥î ${response['message'] ?? 'Gagal update paket'} (${response['detail'] ?? ''})",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Γ¥î Exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Γ¥î Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePaket(int paketId) async {
    try {
      final response = await PaketLesService.deletePaket(paketId);

      if (mounted) {
        if (response['status'] == 'success') {
          await _loadPaketList();
          await _loadStats();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Γ£à Paket les berhasil dihapus"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Γ¥î ${response['message'] ?? 'Gagal hapus paket'}",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Γ¥î Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showTambahModal() {
    _clearControllers();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 840,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.18),
                    blurRadius: 30,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 18, 20),
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.library_add_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tambah Paket Les Baru',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Buat paket les baru yang dapat dipilih siswa saat pendaftaran',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                        child: SingleChildScrollView(
                          child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    'Nama Paket *',
                                    namaController,
                                    hint: 'Nama paket les...',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildDialogStatusDropdown(
                                    setStateDialog,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Harga Awal *',
                                    hargaController,
                                    hint: '0',
                                    isNumber: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildTextField(
                                    'Diskon (%)',
                                    diskonController,
                                    hint: '0',
                                    isNumber: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildTextField(
                                    'Durasi (menit)',
                                    durasiController,
                                    hint: '90',
                                    isNumber: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              'Deskripsi',
                              deskripsiController,
                              hint: 'Deskripsi paket les...',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDialogDateField(
                                    'Tanggal Mulai Promo',
                                    tanggalMulaiPromo,
                                    (date) => setStateDialog(
                                      () => tanggalMulaiPromo = date,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildDialogDateField(
                                    'Tanggal Selesai Promo',
                                    tanggalSelesaiPromo,
                                    (date) => setStateDialog(
                                      () => tanggalSelesaiPromo = date,
                                    ),
                                  ),
                                ),
                              ],
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
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(color: Color(0xFFD6DEEA)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _createPaket,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Buat Paket'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
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
        ),
      ),
    );
  }

  Widget _buildDialogDateField(
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) onChanged(date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFD8E1EC)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null
                      ? value.toString().split(' ')[0]
                      : 'Pilih tanggal',
                  style: TextStyle(
                    fontSize: 14,
                    color: value != null
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogStatusDropdown(StateSetter setStateDialog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Status",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: selectedStatus,
          items: ['aktif', 'nonaktif']
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e == 'aktif' ? 'Segera Hadir' : 'Nonaktif'),
                ),
              )
              .toList(),
          onChanged: (val) =>
              setStateDialog(() => selectedStatus = val ?? 'aktif'),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD8E1EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD8E1EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
        ),
      ],
    );
  }

  void _showEditModal(Map<String, dynamic> paket) {
    namaController.text = paket['nama_paket'] ?? '';
    hargaController.text = paket['harga_awal']?.toString() ?? '';
    diskonController.text = paket['diskon']?.toString() ?? '0';
    durasiController.text = paket['durasi']?.toString() ?? '';
    deskripsiController.text = paket['deskripsi'] ?? '';
    selectedStatus = paket['status'] ?? 'aktif';
    tanggalMulaiPromo = null;
    tanggalSelesaiPromo = null;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 840,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.18),
                    blurRadius: 30,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 18, 20),
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Paket Les',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Perbarui informasi paket les yang sudah tersimpan',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                        child: SingleChildScrollView(
                          child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    'Nama Paket *',
                                    namaController,
                                    hint: 'Nama paket les...',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildDialogStatusDropdown(
                                    setStateDialog,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Harga Awal *',
                                    hargaController,
                                    hint: '0',
                                    isNumber: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildTextField(
                                    'Diskon (%)',
                                    diskonController,
                                    hint: '0',
                                    isNumber: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildTextField(
                                    'Durasi (menit)',
                                    durasiController,
                                    hint: '90',
                                    isNumber: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              'Deskripsi',
                              deskripsiController,
                              hint: 'Deskripsi paket les...',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDialogDateField(
                                    'Tanggal Mulai Promo',
                                    tanggalMulaiPromo,
                                    (date) => setStateDialog(
                                      () => tanggalMulaiPromo = date,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildDialogDateField(
                                    'Tanggal Selesai Promo',
                                    tanggalSelesaiPromo,
                                    (date) => setStateDialog(
                                      () => tanggalSelesaiPromo = date,
                                    ),
                                  ),
                                ),
                              ],
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
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(color: Color(0xFFD6DEEA)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _updatePaket(paket['id']),
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: const Text('Simpan Perubahan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
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
        ),
      ),
    );
  }

  void _showDetailModal(Map<String, dynamic> paket) {
    int hargaPromo = PaketLesService.calculateHargaPromo(
      paket['harga_awal'] ?? 0,
      paket['diskon'] ?? 0,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(paket['nama_paket'] ?? 'Detail Paket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                "Status",
                "${paket['status'] ?? 'N/A'} ${paket['status'] == 'aktif' ? 'Γ£à' : 'Γ¥î'}",
              ),
              _buildDetailRow(
                "Harga Normal",
                PaketLesService.formatRupiah(paket['harga_awal'] ?? 0),
              ),
              if ((paket['diskon'] ?? 0) > 0) ...[
                _buildDetailRow("Diskon", "${paket['diskon']}% ≡ƒö┤"),
                _buildDetailRow(
                  "Harga Promo",
                  PaketLesService.formatRupiah(hargaPromo),
                ),
              ],
              const Divider(),
              _buildDetailRow("Durasi", "${paket['durasi'] ?? '-'} menit"),
              _buildDetailRow("Deskripsi", paket['deskripsi'] ?? '-'),
              if (paket['tanggal_mulai_promo'] != null)
                _buildDetailRow(
                  "Promo Dari",
                  paket['tanggal_mulai_promo'] ?? '-',
                ),
              if (paket['tanggal_selesai_promo'] != null)
                _buildDetailRow(
                  "Promo Sampai",
                  paket['tanggal_selesai_promo'] ?? '-',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> paket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΓÜá∩╕Å Hapus Paket"),
        content: Text("Yakin ingin menghapus paket '${paket['nama_paket']}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePaket(paket['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Ya, Hapus"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7F9FF), Color(0xFFF3F6FB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelola Paket Les',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Buat dan atur paket les bimbingan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showTambahModal,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Paket Les'),
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
                _buildStatCard(
                  'Total Paket',
                  stats['total_paket']?.toString() ?? '0',
                  const Color(0xFF2563EB),
                  const Color(0xFFDCEBFF),
                  Icons.inventory_2_rounded,
                ),
                const SizedBox(width: 14),
                _buildStatCard(
                  'Paket Aktif',
                  stats['paket_aktif']?.toString() ?? '0',
                  const Color(0xFF16A34A),
                  const Color(0xFFE0F4E8),
                  Icons.verified_rounded,
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (paketList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 72),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE6EDF7)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.inbox_rounded,
                        size: 34,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Belum ada paket les',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Klik tombol Tambah Paket Les untuk membuat paket baru.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.02,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                ),
                itemCount: paketList.length,
                itemBuilder: (context, index) {
                  final paket = paketList[index];
                  final hargaPromo = PaketLesService.calculateHargaPromo(
                    paket['harga_awal'] ?? 0,
                    paket['diskon'] ?? 0,
                  );
                  final isActive = paket['status'] == 'aktif';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE6EDF7)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(15, 23, 42, 0.08),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isActive
                                    ? [
                                        const Color(0xFFBDEDC9),
                                        const Color(0xFFD8F2DF),
                                      ]
                                    : [
                                        const Color(0xFFF5D5D5),
                                        const Color(0xFFFBE7E7),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paket['nama_paket'] ?? 'N/A',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      isActive
                                          ? Icons.check_circle_rounded
                                          : Icons.remove_circle_rounded,
                                      size: 14,
                                      color: isActive
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isActive ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              PaketLesService.formatRupiah(
                                                paket['harga_awal'] ?? 0,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF94A3B8),
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                            if ((paket['diskon'] ?? 0) > 0)
                                              Text(
                                                '${paket['diskon']}% OFF',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFEF4444),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            const SizedBox(height: 2),
                                            Text(
                                              PaketLesService.formatRupiah(
                                                hargaPromo,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.schedule_rounded,
                                        size: 14,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${paket['durasi'] ?? '-'} menit',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _chip(
                                        '${paket['status'] ?? '-'}',
                                        isActive
                                            ? const Color(0xFFE8F7ED)
                                            : const Color(0xFFFDECEC),
                                        isActive
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFFB91C1C),
                                      ),
                                      if ((paket['diskon'] ?? 0) > 0)
                                        _chip(
                                          '${paket['diskon']}% OFF',
                                          const Color(0xFFFEE2E2),
                                          const Color(0xFFB91C1C),
                                        ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _actionPill(
                                          label: 'Detail',
                                          icon: Icons.visibility_outlined,
                                          onPressed: () =>
                                              _showDetailModal(paket),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _actionPill(
                                          label: 'Edit',
                                          icon: Icons.edit_outlined,
                                          onPressed: () =>
                                              _showEditModal(paket),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _actionPill(
                                          label: 'Hapus',
                                          icon: Icons.delete_outline,
                                          onPressed: () =>
                                              _showDeleteConfirmation(paket),
                                          danger: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color accentColor,
    Color backgroundColor,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: accentColor.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _actionPill({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    final Color color = danger
        ? const Color(0xFFEF4444)
        : const Color(0xFF8B5E57);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.28)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
