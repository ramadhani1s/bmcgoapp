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

  @override
  void initState() {
    super.initState();
    futureData = AbsensiService.getAbsensi(); 
  }

 @override
Widget build(BuildContext context) {
  return Material(
    color: Colors.transparent,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= TITLE =================
          const Text(
            "Kelola Absensi",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "Lihat, kelola, dan perbarui data kehadiran siswa berdasarkan kelas atau jadwal",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 16),

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
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _dropdown("Semua Kelas"),
              const SizedBox(width: 10),
              _dropdown("Semua Status"),
            ],
          ),

          const SizedBox(height: 16),

          // ================= TABLE =================
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A58F2),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Data Absensi per Sesi",
                        style:
                            TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Data ditampilkan secara dinamis",
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // HEADER TABLE
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: const [
                      Expanded(flex: 2, child: Text("TANGGAL & JADWAL")),
                      Expanded(child: Text("KELAS")),
                      Expanded(flex: 2, child: Text("MATA PELAJARAN")),
                      Expanded(flex: 2, child: Text("MENTOR")),
                      Expanded(child: Text("STATUS")),
                      Expanded(child: Text("AKSI")),
                    ],
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
                              horizontal: 12, vertical: 8),
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
                                    color: item.status ==
                                            "Selesai"
                                        ? Colors.green
                                            .withOpacity(0.2)
                                        : Colors.grey
                                            .withOpacity(0.2),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.status,
                                    textAlign: TextAlign.center,
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
  );
}

  // ================= WIDGET =================

  Widget _statCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ],
              ),
            ),
            Icon(icon, color: color),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton(
        value: text,
        underline: const SizedBox(),
        items: [text]
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (_) {},
      ),
    );
  }
}