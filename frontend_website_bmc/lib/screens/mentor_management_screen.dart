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
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Fisika',
    'Kimia',
    'Biologi',
    'Sosiologi',
    'Ekonomi',
    'Geografi'
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
            final screenHeight = MediaQuery.of(context).size.height;
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              contentPadding: EdgeInsets.zero,
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 500,
                  maxWidth: 500,
                  maxHeight: screenHeight * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
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
                                  'Tambah Mentor Baru',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Buat mentor baru untuk mengakses sistem.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
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
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD8E1EE)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text("Batal"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text("Tambah Mentor"),
                          ),
                        ],
                      ),
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
            final screenHeight = MediaQuery.of(context).size.height;
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              contentPadding: EdgeInsets.zero,
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 500,
                  maxWidth: 500,
                  maxHeight: screenHeight * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(14),
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
                                  'Edit Mentor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Perbarui data mentor yang sudah terdaftar.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD8E1EE)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Update",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
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
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
          contentPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          title: const Text(
            "Nonaktifkan Mentor",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Yakin nonaktifkan ${mentor.namaMentor}?",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Data mentor tetap tersimpan. Soal latihan yang ada tidak akan terhapus.",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
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
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text("Batal"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          title: const Text(
            "Hapus Mentor Permanen?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Apakah Anda yakin ingin menghapus mentor \"${mentor.namaMentor}\" secara permanen?",
                style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.45),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning, color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Aksi ini tidak bisa dibatalkan. Data mentor dan semua datanya akan dihapus selamanya dari sistem.",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: const Color(0xFF991B1B),
                          fontWeight: FontWeight.w500,
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
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4B5563),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text("Batal"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Hapus Permanen"),
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
                        'BMC GrowUp',
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
            "Laporan Absensi",
            Icons.assignment_turned_in_outlined,
            onTap: () {
              navigateToAdminMenu('Laporan Absensi');
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
  // MAIN UI - DIPERBAIKI BAGIAN TABELNYA
  // ==================================================
  Widget _buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'MENTOR',
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
              'EMAIL',
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
              'PASSWORD',
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
              'MATA PELAJARAN',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'STATUS',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'AKSI',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorRow(Mentor mentor) {
    final visible = _showPassword[mentor.mentorId] ?? false;
    final isAktif = mentor.status.toLowerCase() == 'aktif';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              mentor.namaMentor,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              mentor.email,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  visible ? mentor.password : "••••••••",
                  style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 4),
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
                    size: 16,
                    color: const Color(0xFF6B7280),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  mentor.mataPelajaran,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color: isAktif
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAktif
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFFCA5A5),
                  width: 1,
                ),
              ),
              child: Text(
                mentor.status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isAktif
                      ? const Color(0xFF166534)
                      : const Color(0xFF991B1B),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _showEditDialog(mentor),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Edit",
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _deactivateMentor(mentor),
                  icon: const Icon(
                    Icons.block_outlined,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Nonaktifkan",
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _hardDeleteMentor(mentor),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Hapus Permanen",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorTableCard() {
    return Container(
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
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              children: [
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Data Mentor",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Daftar mentor bimbingan belajar BMC",
                        style: TextStyle(
                          color: Color(0xFFDBEAFE),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTableHeader(),
                if (_filteredMentors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        "Belum ada mentor",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredMentors.length,
                    itemBuilder: (context, index) {
                      return _buildMentorRow(_filteredMentors[index]);
                    },
                  ),
              ],
            ),
    );
  }

  Widget _buildMainContent() {
    final activeMentor = _mentors
        .where((e) => e.status.toLowerCase() == 'aktif')
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Kelola Mentor',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Buat dan atur data mentor bimbingan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Mentor'),
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
                _statCard(
                  'Total Mentor',
                  _mentors.length.toString(),
                  const Color(0xFF2563EB),
                  Icons.groups_2_rounded,
                ),
                _statCard(
                  'Mentor Aktif',
                  activeMentor.toString(),
                  const Color(0xFF16A34A),
                  Icons.verified_rounded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Cari mentor...",
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
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _mentors.isEmpty ? null : _exportAllMentorExcel,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text("Export Excel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMentorTableCard(),
          ],
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInDashboard) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F9FF), Color(0xFFF3F6FB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildMainContent(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF7F9FF), Color(0xFFF3F6FB)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }
}