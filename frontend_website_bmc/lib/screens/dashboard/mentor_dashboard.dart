import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Mentor Dashboard',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat datang, ${_currentUser!.nama}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _currentUser!.roleName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Stats
                  const Text(
                    'Statistik Mengajar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Siswa Aktif',
                          '45',
                          Icons.people,
                          const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Kelas Saya',
                          '3',
                          Icons.class_,
                          const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Tugas Diberikan',
                          '12',
                          Icons.assignment,
                          const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Penilaian',
                          '28',
                          Icons.grade,
                          const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Menu Grid
                  const Text(
                    'Menu Mentor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildMenuCard(
                        'Daftar Siswa',
                        Icons.people_outline,
                        const Color(0xFF3B82F6),
                        () {
                          // Navigate to student list
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fitur Daftar Siswa - Coming Soon!',
                              ),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        'Kelola Kelas',
                        Icons.class_outlined,
                        const Color(0xFF10B981),
                        () {
                          // Navigate to class management
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fitur Kelola Kelas - Coming Soon!',
                              ),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        'Buat Tugas',
                        Icons.assignment_outlined,
                        const Color(0xFFF59E0B),
                        () {
                          // Navigate to create assignment
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fitur Buat Tugas - Coming Soon!'),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        'Penilaian',
                        Icons.grade_outlined,
                        const Color(0xFF8B5CF6),
                        () {
                          // Navigate to grading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fitur Penilaian - Coming Soon!'),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        'Jadwal Mengajar',
                        Icons.schedule_outlined,
                        const Color(0xFFEF4444),
                        () {
                          // Navigate to schedule
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fitur Jadwal Mengajar - Coming Soon!',
                              ),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        'Laporan Siswa',
                        Icons.report_outlined,
                        const Color(0xFF6B7280),
                        () {
                          // Navigate to student reports
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fitur Laporan Siswa - Coming Soon!',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Recent Activity
                  const Text(
                    'Aktivitas Terbaru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildActivityItem(
                          'Tugas Matematika dikumpulkan oleh 15 siswa',
                          '2 jam yang lalu',
                          Icons.assignment_turned_in,
                          const Color(0xFF10B981),
                        ),
                        const Divider(height: 20),
                        _buildActivityItem(
                          'Kelas Bahasa Inggris dimulai',
                          '4 jam yang lalu',
                          Icons.play_circle,
                          const Color(0xFF3B82F6),
                        ),
                        const Divider(height: 20),
                        _buildActivityItem(
                          'Penilaian ulangan Fisika selesai',
                          '1 hari yang lalu',
                          Icons.grade,
                          const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
