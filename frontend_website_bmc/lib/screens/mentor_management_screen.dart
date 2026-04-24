import 'package:flutter/material.dart';
import '../models/mentor.dart';
import '../services/auth_service.dart';

class MentorManagementScreen extends StatefulWidget {
  const MentorManagementScreen({super.key});

  @override
  State<MentorManagementScreen> createState() => _MentorManagementScreenState();
}

class _MentorManagementScreenState extends State<MentorManagementScreen> {
  bool _isLoading = true;
  List<Mentor> _mentors = const [];

  @override
  void initState() {
    super.initState();
    _loadMentors();
  }

  Future<void> _loadMentors() async {
    setState(() {
      _isLoading = true;
    });

    final mentors = await AuthService.getMentors();

    if (!mounted) return;

    setState(() {
      _mentors = mentors;
      _isLoading = false;
    });
  }

  void _showDemoSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2A58F2),
      ),
    );
  }

  String _statusLabel(String status) {
    final value = status.toLowerCase();
    if (value.contains('aktif')) return 'Aktif';
    if (value.contains('non')) return 'Nonaktif';
    return status;
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();
    if (value.contains('aktif')) return const Color(0xFF16A34A);
    if (value.contains('non')) return const Color(0xFFEF4444);
    return const Color(0xFFF59E0B);
  }

  Future<void> _showCreateMentorDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final namaController = TextEditingController();
    final spesialisasiController = TextEditingController();
    final bioController = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Mentor'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: namaController,
                    decoration: const InputDecoration(labelText: 'Nama Mentor'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  TextField(
                    controller: spesialisasiController,
                    decoration: const InputDecoration(
                      labelText: 'Spesialisasi',
                    ),
                  ),
                  TextField(
                    controller: bioController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Bio'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (shouldSubmit != true) {
      return;
    }

    final result = await AuthService.createMentor(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      namaMentor: namaController.text.trim(),
      spesialisasi: spesialisasiController.text.trim(),
      bio: bioController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    _showDemoSnack(result['message'] ?? 'Proses selesai');

    if (result['success'] == true) {
      await _loadMentors();
    }
  }

  Future<void> _deleteMentor(Mentor mentor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus mentor?'),
          content: Text('Akun ${mentor.namaMentor} akan dihapus permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final result = await AuthService.deleteMentor(mentor.mentorId);
    if (!mounted) {
      return;
    }

    _showDemoSnack(result['message'] ?? 'Proses selesai');

    if (result['success'] == true) {
      await _loadMentors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Kelola Mentor',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton.icon(
            onPressed: _loadMentors,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _showCreateMentorDialog,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Tambah Mentor'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE3F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.06),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2A58E8),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daftar Mentor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_mentors.length} mentor terdaftar',
                                style: const TextStyle(
                                  color: Color(0xFFC9D7FF),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _mentors.isEmpty
                              ? const Center(
                                  child: Text('Belum ada mentor terdaftar'),
                                )
                              : SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'MENTOR',
                                                style: const TextStyle(
                                                  color: Color(0xFF9AA4B6),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'KONTAK',
                                                style: const TextStyle(
                                                  color: Color(0xFF9AA4B6),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'MATA PELAJARAN',
                                                style: const TextStyle(
                                                  color: Color(0xFF9AA4B6),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'STATUS',
                                                style: const TextStyle(
                                                  color: Color(0xFF9AA4B6),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'AKSI',
                                                style: const TextStyle(
                                                  color: Color(0xFF9AA4B6),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        for (final mentor in _mentors)
                                          _buildMentorRow(mentor),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMentorRow(Mentor mentor) {
    final statusColor = _statusColor(mentor.status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0E6D8))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              mentor.namaMentor,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              mentor.email,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                mentor.spesialisasi.isNotEmpty ? mentor.spesialisasi : 'Umum',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusLabel(mentor.status),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _showDemoSnack('Edit mentor menyusul'),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Color(0xFF4F82FF),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _deleteMentor(mentor),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
