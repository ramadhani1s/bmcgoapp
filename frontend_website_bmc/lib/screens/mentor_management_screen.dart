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

  @override
  void initState() {
    super.initState();
    _loadMentors();
  }

  Future<void> _loadMentors() async {
    setState(() => _isLoading = true);

    try {
      final data = await AuthService.getMentors();

      if (!mounted) return;

      setState(() {
        _mentors = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _mentors = [];
      });

      _showSnackBar("Gagal memuat mentor");
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  // ================= TAMBAH =================
  void _showAddMentorDialog() {
    final nama = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final mapel = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Mentor"),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nama,
                decoration:
                    const InputDecoration(labelText: "Nama"),
              ),
              TextField(
                controller: email,
                decoration:
                    const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: "Password"),
              ),
              TextField(
                controller: mapel,
                decoration:
                    const InputDecoration(labelText: "Mata Pelajaran"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final result =
                  await AuthService.createMentor(
                email: email.text,
                password: password.text,
                namaMentor: nama.text,
                spesialisasi: mapel.text,
              );

              if (!mounted) return;

              Navigator.pop(context);
              _showSnackBar(result["message"]);
              _loadMentors();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // ================= EDIT =================
  void _showEditMentorDialog(Mentor mentor) {
  final nama =
      TextEditingController(text: mentor.namaMentor);

  final email =
      TextEditingController(text: mentor.email);

  final mapel =
      TextEditingController(text: mentor.spesialisasi);

  final bio =
      TextEditingController(text: mentor.bio);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Edit Mentor"),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nama,
              decoration: const InputDecoration(
                labelText: "Nama Mentor",
              ),
            ),
            TextField(
              controller: email,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),
            TextField(
              controller: mapel,
              decoration: const InputDecoration(
                labelText: "Mata Pelajaran",
              ),
            ),
            TextField(
              controller: bio,
              decoration: const InputDecoration(
                labelText: "Bio",
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () async {
            final result =
                await AuthService.updateMentor(
              mentor.mentorId,
              nama.text,
              email.text,
              mapel.text,
              bio.text,
            );

            if (!mounted) return;

            Navigator.pop(context);

            _showSnackBar(
                result["message"]);

            _loadMentors();
          },
          child: const Text("Update"),
        ),
      ],
    ),
  );
}

  // ================= HAPUS =================
  void _deleteMentor(Mentor mentor) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Mentor"),
        content: Text(
            "Yakin hapus ${mentor.namaMentor}?"),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result =
        await AuthService.deleteMentor(
      mentor.mentorId,
    );

    _showSnackBar(result["message"]);
    _loadMentors();
  }

  Widget headerCell(String title,
      {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget dataCell(String title,
      {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF3F5FA),

      appBar: AppBar(
        title:
            const Text("Kelola Mentor"),
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _loadMentors,
            icon: const Icon(Icons.refresh),
            label:
                const Text("Refresh"),
          ),
          TextButton.icon(
            onPressed:
                _showAddMentorDialog,
            icon: const Icon(Icons.add),
            label: const Text(
                "Tambah Mentor"),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Container(
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                          20),
                  boxShadow: const [
                    BoxShadow(
                      color:
                          Colors.black12,
                      blurRadius: 8,
                      offset:
                          Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header biru
                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets
                              .all(24),
                      decoration:
                          const BoxDecoration(
                        color: Color(
                            0xFF2D5BE3),
                        borderRadius:
                            BorderRadius.vertical(
                          top:
                              Radius.circular(
                                  20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            "Daftar Mentor",
                            style:
                                TextStyle(
                              color: Colors
                                  .white,
                              fontSize:
                                  32,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          const SizedBox(
                              height: 5),
                          Text(
                            "${_mentors.length} mentor terdaftar",
                            style:
                                const TextStyle(
                              color: Colors
                                  .white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: 20),

                    // Header tabel
                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                                  horizontal:
                                      24),
                      child: Row(
                        children: [
                          headerCell(
                              "MENTOR",
                              flex: 2),
                          headerCell(
                              "KONTAK",
                              flex: 2),
                          headerCell(
                              "MATA PELAJARAN",
                              flex: 2),
                          headerCell(
                              "STATUS"),
                          headerCell(
                              "AKSI"),
                        ],
                      ),
                    ),

                    const Divider(
                        height: 30),

                    Expanded(
                      child:
                          ListView.builder(
                        itemCount:
                            _mentors.length,
                        itemBuilder:
                            (context,
                                index) {
                          final mentor =
                              _mentors[
                                  index];

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal:
                                  24,
                              vertical:
                                  12,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    dataCell(
                                      mentor
                                          .namaMentor,
                                      flex: 2,
                                    ),

                                    dataCell(
                                      mentor.email,
                                      flex: 2,
                                    ),

                                    Expanded(
                                      flex: 2,
                                      child:
                                          Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical:
                                              8,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .blue
                                              .shade50,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                        ),
                                        child:
                                            Center(
                                          child:
                                              Text(
                                            mentor
                                                .spesialisasi,
                                            style: const TextStyle(
                                                color: Colors.blue),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                        width:
                                            10),

                                    Expanded(
                                      child:
                                          Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical:
                                              8,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .green
                                              .shade50,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                        ),
                                        child:
                                            const Center(
                                          child:
                                              Text(
                                            "Aktif",
                                            style: TextStyle(
                                                color: Colors.green),
                                          ),
                                        ),
                                      ),
                                    ),

                                    Expanded(
                                      child:
                                          Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons
                                                  .edit,
                                              color:
                                                  Colors.blue,
                                            ),
                                            onPressed:
                                                () {
                                              _showEditMentorDialog(
                                                  mentor);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons
                                                  .delete,
                                              color:
                                                  Colors.red,
                                            ),
                                            onPressed:
                                                () {
                                              _deleteMentor(
                                                  mentor);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}