import 'dart:html' as html;
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import '../models/mentor.dart';
import '../services/auth_service.dart';

class MentorManagementScreen extends StatefulWidget {
  const MentorManagementScreen({super.key});

  @override
  State<MentorManagementScreen> createState() =>
      _MentorManagementScreenState();
}

class _MentorManagementScreenState
    extends State<MentorManagementScreen> {
  bool _isLoading = true;

  List<Mentor> _mentors = [];
  List<Mentor> _filteredMentors = [];

  final TextEditingController _searchController =
      TextEditingController();

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
  // EXPORT EXCEL (FIX NO ERROR)
  // ==================================================
  void _exportMentorExcel(Mentor mentor) {
    final excel = Excel.createExcel();

    final defaultSheet =
        excel.getDefaultSheet() ?? 'Sheet1';

    final sheet = excel[defaultSheet];

    excel.rename(defaultSheet, 'Mentor');

    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Nama Mentor'),
      TextCellValue('Email'),
      TextCellValue('Password'),
      TextCellValue('Spesialisasi'),
      TextCellValue('Status'),
    ]);

    sheet.appendRow([
      IntCellValue(mentor.mentorId),
      TextCellValue(mentor.namaMentor),
      TextCellValue(mentor.email),
      TextCellValue(mentor.password),
      TextCellValue(mentor.spesialisasi),
      TextCellValue(mentor.status),
    ]);

    final bytes = excel.encode();

    if (bytes == null) return;

    final blob = html.Blob([bytes]);

    final url =
        html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute(
        "download",
        "mentor_${mentor.namaMentor}.xlsx",
      )
      ..click();

    html.Url.revokeObjectUrl(url);

    _showSnack(
      "Excel ${mentor.namaMentor} berhasil diunduh",
    );
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
        return mentor.namaMentor
                .toLowerCase()
                .contains(key) ||
            mentor.email
                .toLowerCase()
                .contains(key) ||
            mentor.spesialisasi
                .toLowerCase()
                .contains(key);
      }).toList();
    });
  }

  // ==================================================
  // SNACKBAR
  // ==================================================
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
                borderRadius:
                    BorderRadius.circular(18),
              ),
              title:
                  const Text("Tambah Mentor Baru"),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    _field(
                      nama,
                      "Nama Mentor",
                    ),
                    const SizedBox(height: 12),
                    _field(
                      email,
                      "Email",
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pass,
                      obscureText:
                          hidePassword,
                      decoration:
                          InputDecoration(
                        labelText:
                            "Password",
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setDialog(() {
                              hidePassword =
                                  !hidePassword;
                            });
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons
                                    .visibility_off
                                : Icons
                                    .visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      mapel,
                      "Spesialisasi",
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    context,
                    false,
                  ),
                  child:
                      const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(
                    context,
                    true,
                  ),
                  child:
                      const Text("Simpan"),
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
      spesialisasi: mapel.text.trim(),
    );

    _showSnack(res["message"]);

    if (res["success"] == true) {
      _loadMentors();
    }
  }

  // ==================================================
  // EDIT
  // ==================================================
  Future<void> _showEditDialog(
    Mentor mentor,
  ) async {
    final nama = TextEditingController(
      text: mentor.namaMentor,
    );

    final email = TextEditingController(
      text: mentor.email,
    );

    final mapel = TextEditingController(
      text: mentor.spesialisasi,
    );

    final pass = TextEditingController();

    bool hidePassword = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
              ),
              title:
                  const Text("Edit Mentor"),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    _field(
                      nama,
                      "Nama Mentor",
                    ),
                    const SizedBox(height: 12),
                    _field(
                      email,
                      "Email",
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pass,
                      obscureText:
                          hidePassword,
                      decoration:
                          InputDecoration(
                        labelText:
                            "Password Baru",
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setDialog(() {
                              hidePassword =
                                  !hidePassword;
                            });
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons
                                    .visibility_off
                                : Icons
                                    .visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      mapel,
                      "Spesialisasi",
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    context,
                    false,
                  ),
                  child:
                      const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(
                    context,
                    true,
                  ),
                  child:
                      const Text("Update"),
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
  // DELETE
  // ==================================================
  Future<void> _deleteMentor(
    Mentor mentor,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title:
              const Text("Hapus Mentor"),
          content: Text(
            "Yakin hapus ${mentor.namaMentor}?",
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text("Batal"),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
              ),
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child:
                  const Text("Hapus"),
            ),
          ],
        );
      },
    );

    if (yes != true) return;

    final res =
        await AuthService.deleteMentor(
      mentor.mentorId,
    );

    _showSnack(res["message"]);

    if (res["success"] == true) {
      _loadMentors();
    }
  }

  Widget _field(
    TextEditingController c,
    String label,
  ) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  // ==================================================
  // MAIN UI
  // ==================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xfff4f6fb),
      body: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.groups,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text(
                  "Kelola Mentor",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.blue,
                  ),
                  onPressed:
                      _showCreateDialog,
                  icon: const Icon(
                    Icons.add,
                    color:
                        Colors.white,
                  ),
                  label: const Text(
                    "Tambah Mentor",
                    style: TextStyle(
                      color:
                          Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: TextField(
                controller:
                    _searchController,
                decoration:
                    const InputDecoration(
                  prefixIcon:
                      Icon(Icons.search),
                  hintText:
                      "Cari mentor...",
                  border:
                      InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                width:
                    double.infinity,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    : _filteredMentors
                            .isEmpty
                        ? const Center(
                            child: Text(
                              "Belum ada mentor terdaftar",
                            ),
                          )
                        : LayoutBuilder(
                            builder:
                                (
                                  context,
                                  constraints,
                                ) {
                              return SingleChildScrollView(
                                scrollDirection:
                                    Axis.horizontal,
                                child:
                                    ConstrainedBox(
                                  constraints:
                                      BoxConstraints(
                                    minWidth:
                                        constraints.maxWidth,
                                  ),
                                  child:
                                      SingleChildScrollView(
                                    child:
                                        DataTable(
                                      columnSpacing:
                                          70,
                                      horizontalMargin:
                                          24,
                                      headingRowColor:
                                          WidgetStateProperty.all(
                                        Colors.grey
                                            .shade100,
                                      ),
                                      columns:
                                          const [
                                        DataColumn(
                                          label:
                                              Text(
                                            "Mentor",
                                          ),
                                        ),
                                        DataColumn(
                                          label:
                                              Text(
                                            "Email",
                                          ),
                                        ),
                                        DataColumn(
                                          label:
                                              Text(
                                            "Password",
                                          ),
                                        ),
                                        DataColumn(
                                          label:
                                              Text(
                                            "Mapel",
                                          ),
                                        ),
                                        DataColumn(
                                          label:
                                              Text(
                                            "Status",
                                          ),
                                        ),
                                        DataColumn(
                                          label:
                                              Text(
                                            "Aksi",
                                          ),
                                        ),
                                      ],
                                      rows:
                                          _filteredMentors.map(
                                        (
                                          mentor,
                                        ) {
                                          final visible =
                                              _showPassword[mentor.mentorId] ??
                                                  false;

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(
                                                  mentor.namaMentor,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  mentor.email,
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    Text(
                                                      visible
                                                          ? mentor.password
                                                          : "••••••••",
                                                    ),
                                                    IconButton(
                                                      onPressed:
                                                          () {
                                                        setState(
                                                          () {
                                                            _showPassword[mentor.mentorId] =
                                                                !visible;
                                                          },
                                                        );
                                                      },
                                                      icon:
                                                          Icon(
                                                        visible
                                                            ? Icons.visibility_off
                                                            : Icons.visibility,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  mentor.spesialisasi,
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal:
                                                        10,
                                                    vertical:
                                                        4,
                                                  ),
                                                  decoration:
                                                      BoxDecoration(
                                                    color: Colors.green.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      20,
                                                    ),
                                                  ),
                                                  child:
                                                      Text(
                                                    mentor.status,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed:
                                                          () => _exportMentorExcel(
                                                        mentor,
                                                      ),
                                                      icon:
                                                          const Icon(
                                                        Icons.download,
                                                        color:
                                                            Colors.green,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed:
                                                          () => _showEditDialog(
                                                        mentor,
                                                      ),
                                                      icon:
                                                          const Icon(
                                                        Icons.edit,
                                                        color:
                                                            Colors.blue,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed:
                                                          () => _deleteMentor(
                                                        mentor,
                                                      ),
                                                      icon:
                                                          const Icon(
                                                        Icons.delete,
                                                        color:
                                                            Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}