import 'package:flutter/material.dart';
import '../../models/admin_kelola_absensi.dart';
import '../../services/admin_kelola_absensi_service.dart';
class AdminKelolaAbsensiScreen extends StatefulWidget {
  const AdminKelolaAbsensiScreen({super.key});

  @override
  State<AdminKelolaAbsensiScreen> createState() =>
      _AdminKelolaAbsensiScreenState();
}

class _AdminKelolaAbsensiScreenState
    extends State<AdminKelolaAbsensiScreen> {

  late Future<List<Absensi>> futureData;

  String selectedKelas = "Semua Kelas";
  String selectedStatus = "Semua Status";

  @override
  void initState() {
    super.initState();
    futureData = AbsensiService.getAbsensi(); 
  }

 @override
Widget build(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFFF7F9FF),
          Color(0xFFF3F6FB),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          24,
          24,
          24,
          28,
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= TITLE =================
          const Text(
            "Kelola Absensi",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Lihat, kelola, dan perbarui data kehadiran siswa berdasarkan kelas atau jadwal",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 24),

          // ================= STATS =================
          Row(
            children: [
              _statCard("Total Sesi", "0", Colors.blue, Icons.calendar_today),
              _statCard("Total Hadir", "0", Colors.green, Icons.check_circle),
              _statCard("Terlambat", "0", Colors.orange, Icons.access_time),
              _statCard("Tidak Hadir / Izin", "0", Colors.red, Icons.cancel),
            ],
          ),

          const SizedBox(height: 16),

          // ================= SEARCH =================
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText:
                        "Cari berdasarkan kelas, mata pelajaran, mentor, atau tanggal...",
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 24,
                      color: Color(0xFF64748B),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),

                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                    ),
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF9CA3AF),
                    ),
                      focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
             _dropdown(
              value: selectedKelas,
              items: const [
                "Semua Kelas",
                "Kelas 10",
                "Kelas 11",
                "Kelas 12",
              ],
              onChanged: (value) {
                setState(() {
                  selectedKelas = value!;
                });
              },
            ),

            const SizedBox(width: 10),

            _dropdown(
              value: selectedStatus,
              items: const [
                "Semua Status",
                "Hadir",
                "Terlambat",
                "Tidak Hadir",
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
              },
            ),
                        ],
          ),

          const SizedBox(height: 22),

          // ================= TABLE =================
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),

              border: Border.all(
                color: const Color(0xFFE6EDF7),
              ),

              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.05),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    18,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF1D4ED8),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Data Absensi per Sesi",
                        style:
                            TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Data ditampilkan secara dinamis",
                        style: TextStyle(
                            color: Color(0xFFDBEAFE), fontSize: 13),
                            
                      ),
                    ],
                  ),
                ),

                
                // HEADER TABLE
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [

                        Expanded(
                          flex: 2,
                          child: Text(
                            "TANGGAL & JADWAL",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                              fontSize: 13,
                            ),
                          ),
                        ),

                        Expanded(
                          child: Text(
                            "KELAS",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                              fontSize: 13,
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 2,
                          child: Text(
                            "MATA PELAJARAN",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                              fontSize: 13,
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 2,
                          child: Text(
                            "MENTOR",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                              fontSize: 13,
                            ),
                          ),
                        ),

                        Expanded(
                          child: Text(
                            "STATUS",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                              fontSize: 13,
                            ),
                          ),
                        ),

                        Expanded(
                          child: Text(
                            "AKSI",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ================= DATA =================
                FutureBuilder<List<Absensi>>(
                  future: futureData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                            child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                            child: Text("Gagal memuat data")),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                            child: Text("Data kosong")),
                      );
                    }

                    final data = snapshot.data!;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              // TANGGAL
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(item.tanggal,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold)),
                                    Text(item.jam,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                  ],
                                ),
                              ),

                              // KELAS
                              Expanded(
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    item.kelas,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight:
                                            FontWeight.w600),
                                  ),
                                ),
                              ),

                              Expanded(
                                  flex: 2,
                                  child: Text(item.mapel)),

                              Expanded(
                                  flex: 2,
                                  child: Text(item.mentor)),

                              // STATUS
                              Expanded(
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: item.status == "Selesai"
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),

                                    borderRadius: BorderRadius.circular(20),

                                    border: Border.all(
                                      color: item.status == "Selesai"
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                              ),

                              // AKSI
                              const Expanded(
                                child: Icon(
                                  Icons.remove_red_eye,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
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

  // ================= WIDGET =================

  Widget _statCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 22,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.18),
        ),
      ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),

      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),

        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: Color(0xFF6B7280),
        ),

        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF374151),
          fontWeight: FontWeight.w500,
        ),

        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),

        onChanged: onChanged,
      ),
    );
  }
}