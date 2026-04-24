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
    setState(() => _isLoading = true);
    final mentors = await AuthService.getMentors();
    if (!mounted) {
      return;
    }

    setState(() {
      _mentors = mentors;
      _isLoading = false;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final subjectController = TextEditingController();
    final bioController = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Mentor'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
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
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Mata Pelajaran',
                  ),
                ),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
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
      namaMentor: nameController.text.trim(),
      spesialisasi: subjectController.text.trim(),
      bio: bioController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    _showSnack(result['message']?.toString() ?? 'Proses selesai');
    if (result['success'] == true) {
      await _loadMentors();
    }
  }

  Future<void> _showEditDialog(Mentor mentor) async {
    final nameController = TextEditingController(text: mentor.namaMentor);
    final emailController = TextEditingController(text: mentor.email);
    final subjectController = TextEditingController(text: mentor.spesialisasi);
    final bioController = TextEditingController(text: mentor.bio);

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Mentor'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Mentor'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Mata Pelajaran',
                  ),
                ),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (shouldSubmit != true) {
      return;
    }

    final result = await AuthService.updateMentor(
      mentor.mentorId,
      nameController.text.trim(),
      emailController.text.trim(),
      subjectController.text.trim(),
      bioController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    _showSnack(result['message']?.toString() ?? 'Proses selesai');
    await _loadMentors();
  }

  Future<void> _deleteMentor(Mentor mentor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Mentor'),
          content: Text('Yakin hapus ${mentor.namaMentor}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
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

    _showSnack(result['message']?.toString() ?? 'Proses selesai');
    if (result['success'] == true) {
      await _loadMentors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manajemen Mentor'),
        actions: [
          IconButton(
            onPressed: _loadMentors,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          TextButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Mentor'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mentors.isEmpty
          ? const Center(child: Text('Belum ada mentor terdaftar'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _mentors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final mentor = _mentors[index];
                return Card(
                  child: ListTile(
                    title: Text(mentor.namaMentor),
                    subtitle: Text(
                      '${mentor.email}\n${mentor.spesialisasi.isEmpty ? 'Umum' : mentor.spesialisasi}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showEditDialog(mentor),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => _deleteMentor(mentor),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
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
}
