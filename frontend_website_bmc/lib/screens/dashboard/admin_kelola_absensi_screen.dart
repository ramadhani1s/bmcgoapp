import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../models/admin_kelola_absensi.dart';
import '../../services/admin_kelola_absensi_service.dart';

class AdminKelolaAbsensiScreen extends StatefulWidget {
  const AdminKelolaAbsensiScreen({super.key});

  @override
  State<AdminKelolaAbsensiScreen> createState() =>
      _AdminKelolaAbsensiScreenState();
}

class _AdminKelolaAbsensiScreenState extends State<AdminKelolaAbsensiScreen> {
  late Future<Map<String, dynamic>> futureData;

  String selectedKelas = "Semua Kelas";
  String selectedStatus = "Semua Status";
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    futureData = AbsensiService.getAbsensi();
  }

  void _refreshData() {
    setState(() {
      futureData = AbsensiService.getAbsensi();
    });
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
      child: FutureBuilder<Map<String, dynamic>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Gagal memuat data"));
          }

          final responseData = snapshot.data ?? {
            'list': <Absensi>[],
            'totalSesi': '0',
            'totalHadir': '0',
            'totalTidakHadir': '0',
          };
          final data = responseData['list'] as List<Absensi>;
          final totalSesi = responseData['totalSesi'] as String;
          final totalHadir = responseData['totalHadir'] as String;
          final totalTidakHadir = responseData['totalTidakHadir'] as String;

          // Apply filters to list
          var filteredList = data;
          if (selectedKelas != "Semua Kelas") {
            filteredList = filteredList.where((e) => e.kelas.toLowerCase().contains(selectedKelas.toLowerCase()) || e.kelas.toLowerCase() == selectedKelas.toLowerCase()).toList();
          }
          if (selectedStatus != "Semua Status") {
            if (selectedStatus == "Hadir") {
              filteredList = filteredList.where((e) => e.status == "Hadir").toList();
            } else if (selectedStatus == "Tidak Hadir") {
              filteredList = filteredList.where((e) => e.status == "Tidak Hadir").toList();
            }
          }
          if (searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            filteredList = filteredList.where((e) =>
              e.kelas.toLowerCase().contains(query) ||
              e.mapel.toLowerCase().contains(query) ||
              e.mentor.toLowerCase().contains(query) ||
              e.tanggal.toLowerCase().contains(query)
            ).toList();
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: SingleChildScrollView(
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
                    "Akses dan pantau data kehadiran siswa secara real-time berdasarkan kelas atau jadwal",
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),

                  const SizedBox(height: 24),

                  // ================= STATS =================
                  Row(
                    children: [
                      _statCard(
                        "Total Sesi",
                        totalSesi,
                        Colors.blue,
                        Icons.calendar_today,
                      ),
                      _statCard(
                        "Total Hadir",
                        totalHadir,
                        Colors.green,
                        Icons.check_circle,
                      ),
                      _statCard(
                        "Tidak Hadir",
                        totalTidakHadir,
                        Colors.red,
                        Icons.cancel,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ================= SEARCH =================
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
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
                          "10 IPA",
                          "11 IPA",
                          "12 IPA",
                          "10 IPS",
                          "11 IPS",
                          "12 IPS",
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

                      border: Border.all(color: const Color(0xFFE6EDF7)),

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
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Data Absensi per Sesi",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Data ditampilkan secara dinamis",
                                    style: TextStyle(
                                      color: Color(0xFFDBEAFE),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.restart_alt,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                tooltip: "Riset Semua Data Absensi",
                                onPressed: () {
                                  _showResetAllConfirmation(context);
                                },
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
                              ],
                            ),
                          ),
                        ),

                        // ================= DATA =================
                        if (filteredList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text("Data kosong")),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final item = filteredList[index];

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    // TANGGAL
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.tanggal,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            item.jam,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // KELAS
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          item.kelas,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),

                                    Expanded(flex: 2, child: Text(item.mapel)),

                                    Expanded(flex: 2, child: Text(item.mentor)),

                                    // STATUS
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.status == "Hadir"
                                              ? const Color(0xFFDCFCE7) // Soft Green
                                              : const Color(0xFFFEE2E2), // Soft Red
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: item.status == "Hadir"
                                                ? const Color(0xFFBBF7D0)
                                                : const Color(0xFFFCA5A5),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          item.status,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: item.status == "Hadir"
                                                ? const Color(0xFF166534)
                                                : const Color(0xFF991B1B),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
        },
      ),
    );
  }


  // ================= WIDGET =================

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18)),
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
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),

      child: DropdownButton<String>(
        value: items.contains(value) ? value : null,
        underline: const SizedBox(),

        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),

        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF374151),
          fontWeight: FontWeight.w500,
        ),

        items: items.map((item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),

        onChanged: onChanged,
      ),
    );
  }

  void _showResetAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text(
                "Riset Semua Absensi",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Apakah Anda yakin ingin meriset seluruh data absensi?",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text(
                "Tindakan ini akan menghapus semua sesi absensi dan catatan kehadiran siswa secara permanen dari sistem. Statistik absensi juga akan kembali ke nol.",
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Batal",
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                _performResetAll();
              },
              child: const Text(
                "Riset Semua",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performResetAll() async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await AbsensiService.resetAllAbsensi();

    // Hide Loading
    if (mounted) {
      Navigator.pop(context);
    }

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Semua data absensi berhasil diriset/dihapus"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshData();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal meriset semua data absensi"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
