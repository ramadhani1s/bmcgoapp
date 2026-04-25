import 'package:flutter/material.dart';

class PaketLesScreen extends StatelessWidget {
  const PaketLesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Kelola Paket Les",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Buat dan kelola paket bimbingan belajar BMC",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2A58F2),
                ),
                onPressed: () {
                  _showTambahPaketDialog(context);
                },
                child: const Text("+ Tambah Paket Les"),
              )
            ],
          ),

          const SizedBox(height: 20),

          // ================= EMPTY STATE =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFFE5EAF2)),
            ),
            child: const Center(
              child: Text(
                "Belum ada paket les.\nKlik tombol Tambah Paket Les.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ================= MODAL =================
  void _showTambahPaketDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "+ Tambah Paket Les Baru",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      )
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Buat paket les baru yang dapat dipilih siswa saat pendaftaran",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  // FORM GRID
                  Wrap(
                    spacing: 20,
                    runSpacing: 15,
                    children: [
                      _inputField("Nama Paket *", "Nama paket les", 260),
                      _dropdownField("Kategori", ["Reguler", "Premium"], 260),
                      _dropdownField("Jenjang", ["SMA", "SMP"], 260),
                      _dropdownField("Status", ["Aktif", "Segera Hadir"], 260),
                      _inputField("Deskripsi *", "Deskripsi paket les...", 540, maxLines: 3),

                      _inputField("Durasi/Sesi (menit)", "90", 130),
                      _inputField("Sesi/Minggu", "3", 130),
                      _inputField("Total Sesi", "36", 130),
                      _inputField("Durasi Program", "3 Bulan", 130),

                      _inputField("Harga *", "0", 260),
                      _inputField("Maks. Siswa", "15", 260),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Mata Pelajaran
                  Row(
                    children: [
                      Expanded(
                        child: _inputField("Mata Pelajaran", "Tambah mata pelajaran...", double.infinity),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text("Tambah"),
                      )
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Fitur Paket
                  Row(
                    children: [
                      Expanded(
                        child: _inputField("Fitur Paket", "Tambah fitur...", double.infinity),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text("Tambah"),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  // BUTTON ACTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A58F2),
                        ),
                        onPressed: () {},
                        child: const Text("Buat Paket"),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= INPUT FIELD =================
  Widget _inputField(String label, String hint, double width, {int maxLines = 1}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          TextField(
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DROPDOWN =================
  Widget _dropdownField(String label, List<String> items, double width) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: items.first,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) {},
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}