import 'package:flutter/material.dart';

class VerifikasiPendaftaranScreen extends StatefulWidget {
  const VerifikasiPendaftaranScreen({super.key});

  @override
  State<VerifikasiPendaftaranScreen> createState() =>
      _VerifikasiPendaftaranScreenState();
}

class _VerifikasiPendaftaranScreenState
    extends State<VerifikasiPendaftaranScreen> {
  List<Map<String, dynamic>> pendaftaranList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendaftaran();
  }

  Future<void> _loadPendaftaran() async {
    setState(() => isLoading = true);
    // TODO: Load from service
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _verifyPendaftaran(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("✅ Terima Pendaftaran"),
        content: const Text(
          "Apakah Anda yakin ingin menerima pendaftaran ini?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Pendaftaran diterima"),
                  backgroundColor: Colors.green,
                ),
              );
              _loadPendaftaran();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Terima", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _rejectPendaftaran(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("❌ Tolak Pendaftaran"),
        content: const Text("Apakah Anda yakin ingin menolak pendaftaran ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("❌ Pendaftaran ditolak"),
                  backgroundColor: Colors.red,
                ),
              );
              _loadPendaftaran();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Tolak", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Verifikasi Pendaftaran",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Verifikasi data siswa yang telah mendaftar",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Menunggu Verifikasi",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "0",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Diterima",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "0",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ditolak",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "0",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: pendaftaranList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Tidak ada data pendaftaran",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("NO.")),
                        DataColumn(label: Text("NAMA SISWA")),
                        DataColumn(label: Text("SEKOLAH")),
                        DataColumn(label: Text("KELAS")),
                        DataColumn(label: Text("TANGGAL DAFTAR")),
                        DataColumn(label: Text("STATUS")),
                        DataColumn(label: Text("AKSI")),
                      ],
                      rows: pendaftaranList.asMap().entries.map((entry) {
                        int idx = entry.key + 1;
                        var data = entry.value;

                        return DataRow(
                          cells: [
                            DataCell(Text(idx.toString())),
                            DataCell(Text(data['nama'] ?? '-')),
                            DataCell(Text(data['sekolah'] ?? '-')),
                            DataCell(Text(data['kelas'] ?? '-')),
                            DataCell(Text(data['tanggal'] ?? '-')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  data['status'] ?? 'Pending',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green,
                                    ),
                                    onPressed: () =>
                                        _verifyPendaftaran(data['id']),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _rejectPendaftaran(data['id']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
