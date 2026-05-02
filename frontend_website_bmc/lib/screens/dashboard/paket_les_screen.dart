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
          content: Text("❌ Nama Paket wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (hargaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Harga Awal wajib diisi"),
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
            content: Text("❌ Harga harus berupa angka"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (hargaAwal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Harga harus lebih dari 0"),
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

      print("🚀 CREATE PAKET: $data");

      final response = await PaketLesService.createPaket(data);

      if (mounted) {
        if (response['status'] == 'success') {
          _clearControllers();
          await _loadPaketList();
          await _loadStats();
          if (mounted) Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Paket les berhasil dibuat"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "❌ ${response['message'] ?? 'Gagal membuat paket'} (${response['detail'] ?? ''})",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updatePaket(int paketId) async {
    // Validasi field required
    if (namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Nama Paket wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (hargaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Harga Awal wajib diisi"),
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
            content: Text("❌ Harga harus berupa angka"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (hargaAwal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Harga harus lebih dari 0"),
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

      print("✏️ UPDATE PAKET $paketId: $data");

      final response = await PaketLesService.updatePaket(paketId, data);

      if (mounted) {
        if (response['status'] == 'success') {
          await _loadPaketList();
          await _loadStats();
          if (mounted) Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Paket les berhasil diupdate"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "❌ ${response['message'] ?? 'Gagal update paket'} (${response['detail'] ?? ''})",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
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
              content: Text("✅ Paket les berhasil dihapus"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ ${response['message'] ?? 'Gagal hapus paket'}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showTambahModal() {
    _clearControllers();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("+ Tambah Paket Les Baru"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  "Nama Paket *",
                  namaController,
                  hint: "Contoh: Kelas 10 SMA - 1 Semester",
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  "Harga Awal *",
                  hargaController,
                  hint: "Contoh: 4250000",
                  isNumber: true,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  "Diskon (%)",
                  diskonController,
                  hint: "Contoh: 5",
                  isNumber: true,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  "Durasi (menit)",
                  durasiController,
                  hint: "Contoh: 120",
                  isNumber: true,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  "Deskripsi",
                  deskripsiController,
                  hint: "Deskripsi paket",
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _buildDialogDateField(
                  "Tanggal Mulai Promo",
                  tanggalMulaiPromo,
                  (date) => setStateDialog(() => tanggalMulaiPromo = date),
                ),
                const SizedBox(height: 12),
                _buildDialogDateField(
                  "Tanggal Selesai Promo",
                  tanggalSelesaiPromo,
                  (date) => setStateDialog(() => tanggalSelesaiPromo = date),
                ),
                const SizedBox(height: 12),
                _buildDialogStatusDropdown(setStateDialog),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: _createPaket,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Buat Paket"),
            ),
          ],
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
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
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
                    color: value != null ? Colors.black : Colors.grey,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
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
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedStatus,
          items: [
            'aktif',
            'nonaktif',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) =>
              setStateDialog(() => selectedStatus = val ?? 'aktif'),
          decoration: InputDecoration(
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
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("✏️ Edit Paket Les"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField("Nama Paket *", namaController),
                const SizedBox(height: 12),
                _buildTextField(
                  "Harga Awal *",
                  hargaController,
                  isNumber: true,
                ),
                const SizedBox(height: 12),
                _buildTextField("Diskon (%)", diskonController, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(
                  "Durasi (menit)",
                  durasiController,
                  isNumber: true,
                ),
                const SizedBox(height: 12),
                _buildTextField("Deskripsi", deskripsiController, maxLines: 3),
                const SizedBox(height: 12),
                _buildDialogDateField(
                  "Tanggal Mulai Promo",
                  tanggalMulaiPromo,
                  (date) => setStateDialog(() => tanggalMulaiPromo = date),
                ),
                const SizedBox(height: 12),
                _buildDialogDateField(
                  "Tanggal Selesai Promo",
                  tanggalSelesaiPromo,
                  (date) => setStateDialog(() => tanggalSelesaiPromo = date),
                ),
                const SizedBox(height: 12),
                _buildDialogStatusDropdown(setStateDialog),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => _updatePaket(paket['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text("Simpan Perubahan"),
            ),
          ],
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
                "${paket['status'] ?? 'N/A'} ${paket['status'] == 'aktif' ? '✅' : '❌'}",
              ),
              _buildDetailRow(
                "Harga Normal",
                PaketLesService.formatRupiah(paket['harga_awal'] ?? 0),
              ),
              if ((paket['diskon'] ?? 0) > 0) ...[
                _buildDetailRow("Diskon", "${paket['diskon']}% 🔴"),
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
        title: const Text("⚠️ Hapus Paket"),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Kelola Paket Les",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Buat dan atur paket les bimbingan",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showTambahModal,
                icon: const Icon(Icons.add),
                label: const Text("Tambah Paket Les"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A58F2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ================= STATS CARDS =================
          Row(
            children: [
              _buildStatCard(
                "Total Paket",
                stats['total_paket']?.toString() ?? '0',
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                "Paket Aktif",
                stats['paket_aktif']?.toString() ?? '0',
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ================= PAKET LIST =================
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : paketList.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "Belum ada paket les",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: paketList.length,
                  itemBuilder: (context, index) {
                    final paket = paketList[index];
                    int hargaPromo = PaketLesService.calculateHargaPromo(
                      paket['harga_awal'] ?? 0,
                      paket['diskon'] ?? 0,
                    );

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header dengan status
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: paket['status'] == 'aktif'
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  paket['status'] == 'aktif'
                                      ? '✅ Aktif'
                                      : '❌ Nonaktif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: paket['status'] == 'aktif'
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Harga
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        PaketLesService.formatRupiah(
                                          paket['harga_awal'] ?? 0,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      if ((paket['diskon'] ?? 0) > 0)
                                        Text(
                                          "${paket['diskon']}% OFF",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      Text(
                                        PaketLesService.formatRupiah(
                                          hargaPromo,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Durasi
                                  if (paket['durasi'] != null)
                                    Text(
                                      "⏱️ ${paket['durasi']} menit",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // Buttons
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showDetailModal(paket),
                                    icon: const Icon(
                                      Icons.visibility,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      "Detail",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showEditModal(paket),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text(
                                      "Edit",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _showDeleteConfirmation(paket),
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    label: const Text(
                                      "Hapus",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
