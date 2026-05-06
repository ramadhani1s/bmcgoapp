import 'dart:html' as html;
import 'dart:convert';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/mentor.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../models/admin_kelola_absensi.dart';
import '../services/admin_kelola_absensi_service.dart';
import 'dashboard/admin_kelola_alumni_screen.dart';

class MentorManagementScreen extends StatefulWidget {
  const MentorManagementScreen({super.key, this.embeddedInDashboard = false});

  final bool embeddedInDashboard;

  @override
  State<MentorManagementScreen> createState() => _MentorManagementScreenState();
}

class _MentorManagementScreenState extends State<MentorManagementScreen> {
  bool _isLoading = true;

  List<Mentor> _mentors = [];
  List<Mentor> _filteredMentors = [];

  final TextEditingController _searchController = TextEditingController();

  final Map<int, bool> _showPassword = {};

  @override
  void initState() {
    super.initState();
    _loadMentors();

    _searchController.addListener(() {
      _filterData(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================================================
  // EXPORT ALL MENTORS TO EXCEL
  // ==================================================
  void _exportAllMentorExcel() {
    final excel = xls.Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Mentor');
    final sheet = excel['Mentor'];

    // HEADER
    final headers = [
      'ID',
      'Nama Mentor',
      'Email',
      'Password',
      'Mata Pelajaran',
      'Status',
    ];

    for (int col = 0; col < headers.length; col++) {
      sheet
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = xls.TextCellValue(
        headers[col],
      );
    }

    // DATA - All mentors in single file
    int rowIndex = 1;
    for (final mentor in _mentors) {
      sheet
          .cell(
            xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          )
          .value = xls.IntCellValue(
        mentor.mentorId,
      );
      sheet
          .cell(
            xls.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
          )
          .value = xls.TextCellValue(
        mentor.namaMentor,
      );
      sheet
          .cell(
            xls.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
          )
          .value = xls.TextCellValue(
        mentor.email,
      );
      sheet
          .cell(
            xls.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
          )
          .value = xls.TextCellValue(
        mentor.password,
      );
      sheet
          .cell(
            xls.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
          )
          .value = xls.TextCellValue(
        mentor.mataPelajaran,
      );
      sheet
          .cell(
            xls.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
          )
          .value = xls.TextCellValue(
        mentor.status,
      );
      rowIndex++;
    }

    final bytes = excel.encode();
    if (bytes == null) {
      _showSnack("Gagal membuat file excel");
      return;
    }

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute(
        "download",
        "data_mentor_bmc_${DateTime.now().toString().split(' ')[0]}.xlsx",
      )
      ..click();
    html.Url.revokeObjectUrl(url);
    _showSnack("Excel semua mentor berhasil diunduh");
  }

  // ==================================================
  // LOAD DATA
  // ==================================================
  Future<void> _loadMentors() async {
    setState(() => _isLoading = true);

    final data = await AuthService.getMentors();

    if (!mounted) return;

    setState(() {
      _mentors = data;
      _filteredMentors = data;
      _isLoading = false;
    });
  }

  // ==================================================
  // SEARCH
  // ==================================================
  void _filterData(String keyword) {
    final key = keyword.toLowerCase();

    setState(() {
      _filteredMentors = _mentors.where((mentor) {
        return mentor.namaMentor.toLowerCase().contains(key) ||
            mentor.email.toLowerCase().contains(key) ||
            mentor.mataPelajaran.toLowerCase().contains(key);
      }).toList();
    });
  }

  // ==================================================
  // SNACKBAR
  // ==================================================
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ==================================================
  // CREATE
  // ==================================================
  Future<void> _showCreateDialog() async {
    final nama = TextEditingController();
    final email = TextEditingController();
    final pass = TextEditingController();
    final mapel = TextEditingController();

    bool hidePassword = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                "Tambah Mentor Baru",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(nama, "Nama Mentor"),
                    const SizedBox(height: 12),
                    _field(email, "Email"),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pass,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialog(() {
                              hidePassword = !hidePassword;
                            });
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(mapel, "Mata Pelajaran"),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final res = await AuthService.createMentor(
      email: email.text.trim(),
      password: pass.text.trim(),
      namaMentor: nama.text.trim(),
      mataPelajaran: mapel.text.trim(),
    );

    _showSnack(res["message"]);

    if (res["success"] == true) {
      _loadMentors();
    }
  }

  // ==================================================
  // EDIT
  // ==================================================
  Future<void> _showEditDialog(Mentor mentor) async {
    final nama = TextEditingController(text: mentor.namaMentor);

    final email = TextEditingController(text: mentor.email);

    final mapel = TextEditingController(text: mentor.mataPelajaran);

    final pass = TextEditingController();

    bool hidePassword = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                "Edit Mentor",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(nama, "Nama Mentor"),
                    const SizedBox(height: 12),
                    _field(email, "Email"),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pass,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: "Password Baru",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialog(() {
                              hidePassword = !hidePassword;
                            });
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(mapel, "Mata Pelajaran"),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final res = await AuthService.updateMentor(
      mentor.mentorId,
      nama.text.trim(),
      email.text.trim(),
      mapel.text.trim(),
      password: pass.text.trim(),
    );

    _showSnack(res["message"]);

    if (res["success"] == true) {
      _loadMentors();
    }
  }

  // ==================================================
  // DEACTIVATE MENTOR (Soft Delete - Status Nonaktif)
  // ==================================================
  Future<void> _deactivateMentor(Mentor mentor) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Nonaktifkan Mentor",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Yakin nonaktifkan ${mentor.namaMentor}?",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Data mentor tetap tersimpan. Soal latihan yang ada tidak akan terhapus.",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Nonaktifkan"),
            ),
          ],
        );
      },
    );

    if (yes != true) return;

    final res = await AuthService.deleteMentor(mentor.mentorId);
    _showSnack(res["message"]);

    if (res["success"] == true) {
      _loadMentors();
    }
  }

  // ==================================================
  // HARD DELETE MENTOR (Permanent Delete)
  // ==================================================
  Future<void> _hardDeleteMentor(Mentor mentor) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Hapus Mentor Permanen",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Yakin hapus ${mentor.namaMentor} permanen?",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "⚠️ Aksi ini tidak bisa dibatalkan. Data mentor dan semua datanya akan dihapus selamanya.",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Hapus Permanen",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (yes != true) return;

    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse(
          "${AuthService.baseUrl}/api/mentor/${mentor.mentorId}/hard-delete",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final body = jsonDecode(response.body);
      _showSnack(body["message"] ?? "Mentor berhasil dihapus");

      if (response.statusCode == 200) {
        _loadMentors();
      }
    } catch (e) {
      _showSnack("❌ Error: $e");
    }
  }

  Widget _field(TextEditingController c, String label) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==================================================
  // SIDEBAR DASHBOARD STYLE
  // ==================================================
  Widget _menuItem(
    String title,
    IconData icon, {
    bool active = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2A58F2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : const Color(0xFF8290A6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF4B5972),
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    void navigateToAdminMenu(String menuTitle) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.adminDashboard,
        arguments: menuTitle,
      );
    }

    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFD),
        border: Border(right: BorderSide(color: Color(0xFFDDE4F0))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Image.asset('assets/images/BMC .png'),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMC',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Bintang Muda Center',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MENU UTAMA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          _menuItem(
            "Dashboard",
            Icons.grid_view_rounded,
            onTap: () {
              navigateToAdminMenu('Dashboard');
            },
          ),

          _menuItem(
            "Verifikasi Pendaftaran",
            Icons.fact_check_outlined,
            onTap: () {
              navigateToAdminMenu('Verifikasi Pendaftaran');
            },
          ),

          _menuItem("Kelola Mentor", Icons.groups_2_outlined, active: true),

          _menuItem(
            "Kelola Jadwal",
            Icons.event_note_outlined,
            onTap: () {
              navigateToAdminMenu('Kelola Jadwal');
            },
          ),

          _menuItem(
            "Kelola Absensi",
            Icons.assignment_turned_in_outlined,
            onTap: () {
              navigateToAdminMenu('Kelola Absensi');
            },
          ),

          _menuItem(
            "Kelola Pengumuman",
            Icons.campaign_outlined,
            onTap: () {
              navigateToAdminMenu('Kelola Pengumuman');
            },
          ),

          _menuItem(
            "Kelola Paket Les",
            Icons.school_outlined,
            onTap: () {
              navigateToAdminMenu('Kelola Paket Les');
            },
          ),

          _menuItem(
            "Kelola Profil Alumni",
            Icons.badge_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminKelolaAlumniScreen(),
                ),
              );
            },
          ),

          const Spacer(),

          ListTile(
            leading: const Icon(Icons.logout_rounded, size: 15),
            title: const Text("Keluar", style: TextStyle(fontSize: 12)),
            onTap: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ==================================================
  // MAIN UI
  // ==================================================
  Widget _buildMentorTableCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredMentors.isEmpty
          ? const Center(child: Text("Belum ada mentor terdaftar"))
          : SingleChildScrollView(
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Colors.grey.shade100,
                ),
                columns: const [
                  DataColumn(label: Text("Mentor")),
                  DataColumn(label: Text("Email")),
                  DataColumn(label: Text("Password")),
                  DataColumn(label: Text("Mata Pelajaran")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Aksi")),
                ],
                rows: _filteredMentors.map((mentor) {
                  final visible = _showPassword[mentor.mentorId] ?? false;

                  return DataRow(
                    cells: [
                      DataCell(Text(mentor.namaMentor)),
                      DataCell(Text(mentor.email)),
                      DataCell(
                        Row(
                          children: [
                            Text(visible ? mentor.password : "••••••••"),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _showPassword[mentor.mentorId] = !visible;
                                });
                              },
                              icon: Icon(
                                visible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(mentor.mataPelajaran)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: mentor.status.toLowerCase() == 'aktif'
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            mentor.status,
                            style: TextStyle(
                              color: mentor.status.toLowerCase() == 'aktif'
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _showEditDialog(mentor),
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: "Edit Mentor",
                            ),
                            IconButton(
                              onPressed: () => _deactivateMentor(mentor),
                              icon: const Icon(
                                Icons.block,
                                color: Colors.orange,
                              ),
                              tooltip: "Nonaktifkan Mentor",
                            ),
                            IconButton(
                              onPressed: () => _hardDeleteMentor(mentor),
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                              ),
                              tooltip: "Hapus Permanen",
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildMainContent({required bool useExpandedTable}) {
    final tableSection = useExpandedTable
        ? Expanded(child: _buildMentorTableCard())
        : SizedBox(height: 500, child: _buildMentorTableCard());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: Colors.blue, size: 28),
              const SizedBox(width: 10),
              const Text(
                "Kelola Mentor",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Tambah Mentor",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Cari mentor...",
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _mentors.isEmpty ? null : _exportAllMentorExcel,
                icon: const Icon(Icons.download),
                label: const Text("Unduh Semua Data Mentor (Excel)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          tableSection,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInDashboard) {
      return Container(
        color: const Color(0xfff4f6fb),
        child: _buildMainContent(useExpandedTable: false),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),
      body: Row(
        children: [
          _buildSidebar(),

          Expanded(child: _buildMainContent(useExpandedTable: true)),
        ],
      ),
    );
  }
}
