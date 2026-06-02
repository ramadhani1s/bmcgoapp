import 'dart:html' as html;
import 'dart:convert';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/theme/app_colors.dart';
import '../models/mentor.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

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
  final List<String> _subjectOptions = const [
    'Matematika',
    'Fisika',
    'Kimia',
    'Biologi',
    'Bahasa Indonesia',
    'Bahasa Inggris',
  ];

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

    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 34);
    sheet.setColumnWidth(3, 24);
    sheet.setColumnWidth(4, 22);
    sheet.setColumnWidth(5, 14);

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
    String selectedMapel = _subjectOptions.first;

    bool hidePassword = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tambah Mentor Baru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    _modernField(nama, "Nama Mentor"),
                    const SizedBox(height: 12),
                    _modernField(email, "Email"),
                    const SizedBox(height: 12),

                    TextField(
                      controller: pass,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        hintText: "Password",
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialog(() {
                              hidePassword = !hidePassword;
                            });
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedMapel,
                      items: _subjectOptions
                          .map(
                            (mapel) => DropdownMenuItem(
                              value: mapel,
                              child: Text(mapel),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialog(() {
                          selectedMapel = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Mata Pelajaran",
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Batal"),
                        ),

                        const SizedBox(width: 12),

                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.add),
                          label: const Text("Tambah Mentor"),
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
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
      mataPelajaran: selectedMapel,
    );

    if (res["success"] == true) {
      await _loadMentors();
      _showSnack(res["message"] ?? "Mentor berhasil dibuat");
    } else {
      _showSnack(res["message"] ?? "Gagal membuat mentor");
    }
  }

  // ==================================================
  // EDIT
  // ==================================================
  Future<void> _showEditDialog(Mentor mentor) async {
    final nama = TextEditingController(text: mentor.namaMentor);

    final email = TextEditingController(text: mentor.email);

    String selectedMapel = _subjectOptions.contains(mentor.mataPelajaran)
        ? mentor.mataPelajaran
        : _subjectOptions.first;

    final pass = TextEditingController(text: mentor.password);

    bool hidePassword = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Mentor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _modernField(nama, "Nama Mentor"),
                    const SizedBox(height: 12),
                    _modernField(email, "Email"),
                    const SizedBox(height: 12),

                    TextField(
                      controller: pass,
                      obscureText: hidePassword,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: "Password",
                        hintText: "Masukkan password mentor",
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.4,
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialog(() {
                              hidePassword = !hidePassword;
                            });
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedMapel,
                      items: _subjectOptions
                          .map(
                            (mapel) => DropdownMenuItem(
                              value: mapel,
                              child: Text(mapel),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialog(() {
                          selectedMapel = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Mata Pelajaran",
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Batal",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text(
                            "Update",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
      selectedMapel,
      password: pass.text.trim(),
    );

    if (res["success"] == true) {
      await _loadMentors();
      _showSnack(res["message"] ?? "Mentor berhasil diupdate");
    } else {
      _showSnack(res["message"] ?? "Gagal update mentor");
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

  Widget _modernField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
        ),
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
              navigateToAdminMenu('Kelola Profil Alumni');
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            )
          : _filteredMentors.isEmpty
          ? SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.groups_2_outlined,
                        color: Color(0xFF2563EB),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Belum ada mentor",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Klik tombol Tambah Mentor untuk menambahkan mentor baru.",
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: const Color(0xFFD6E4FF)),
                child: DataTable(
                  horizontalMargin: 20,
                  columnSpacing: 50,
                  headingRowHeight: 58,
                  dataRowMinHeight: 78,
                  dataRowMaxHeight: 78,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFEFF4FF),
                  ),

                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A),
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),

                  columns: const [
                    DataColumn(
                      label: Expanded(child: Center(child: Text("Mentor"))),
                    ),

                    DataColumn(
                      label: Expanded(child: Center(child: Text("Email"))),
                    ),

                    DataColumn(
                      label: Expanded(child: Center(child: Text("Password"))),
                    ),

                    DataColumn(
                      label: Expanded(
                        child: Center(child: Text("Mata Pelajaran")),
                      ),
                    ),

                    DataColumn(
                      label: Expanded(child: Center(child: Text("Status"))),
                    ),

                    DataColumn(
                      label: Expanded(child: Center(child: Text("Aksi"))),
                    ),
                  ],
                  rows: _filteredMentors.map((mentor) {
                    final visible = _showPassword[mentor.mentorId] ?? false;

                    return DataRow(
                      cells: [
                        DataCell(
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mentor.namaMentor,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              mentor.email,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF374151)),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  visible ? mentor.password : "••••••••",
                                  style: const TextStyle(letterSpacing: 2),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _showPassword[mentor.mentorId] = !visible;
                                    });
                                  },
                                  icon: Icon(
                                    visible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              mentor.mataPelajaran,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: mentor.status.toLowerCase() == 'aktif'
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                mentor.status,
                                style: TextStyle(
                                  color: mentor.status.toLowerCase() == 'aktif'
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _showEditDialog(mentor),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _deactivateMentor(mentor),
                                  icon: const Icon(
                                    Icons.block_outlined,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _hardDeleteMentor(mentor),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }

  Widget _buildMainContent({required bool useExpandedTable}) {
    final activeMentor = _mentors
        .where((e) => e.status.toLowerCase() == 'aktif')
        .length;

    final tableSection = useExpandedTable
        ? Expanded(child: _buildMentorTableCard())
        : SizedBox(height: 500, child: _buildMentorTableCard());

    return Padding(
      padding: const EdgeInsets.all(24),
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
                    'Kelola Mentor',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Buat dan atur data mentor bimbingan',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),

              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Mentor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
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
                'Total Mentor',
                _mentors.length.toString(),
                AppColors.primary,
                AppColors.blueLightBg,
                Icons.groups_2_rounded,
              ),

              const SizedBox(width: 14),

              _buildStatCard(
                'Mentor Aktif',
                activeMentor.toString(),
                AppColors.success,
                AppColors.successBg,
                Icons.verified_rounded,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.softBorder),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: AppColors.textMuted),
                      hintText: 'Cari mentor...',
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              ElevatedButton.icon(
                onPressed: _mentors.isEmpty ? null : _exportAllMentorExcel,
                icon: const Icon(Icons.download_rounded),
                label: const Text("Export Excel"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          tableSection,
        ],
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

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInDashboard) {
      return Container(
        color: AppColors.pageBg,
        child: _buildMainContent(useExpandedTable: false),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Row(
        children: [
          _buildSidebar(),

          Expanded(child: _buildMainContent(useExpandedTable: true)),
        ],
      ),
    );
  }
}
