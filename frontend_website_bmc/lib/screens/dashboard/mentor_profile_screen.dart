import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class MentorProfileScreen extends StatefulWidget {
  const MentorProfileScreen({super.key});

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Future<void> _copyToClipboard(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Disalin ke clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        title: const Text('Profil Mentor'),
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Keluar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEEF4FF), Color(0xFFFFFFFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFDCE7FF)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDBEAFE),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    (user?.nama.isNotEmpty == true
                                            ? user!.nama[0]
                                            : 'M')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.nama ?? 'Mentor',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.email ?? '-',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _buildActionChip(
                                          icon: Icons.copy_outlined,
                                          label: 'Salin Email',
                                          onTap: user == null
                                              ? null
                                              : () => _copyToClipboard(
                                                  user.email,
                                                ),
                                        ),
                                        _buildActionChip(
                                          icon: Icons.refresh_outlined,
                                          label: 'Muat Ulang',
                                          onTap: _loadUser,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked = constraints.maxWidth < 720;
                            final cards = [
                              _buildInfoCard(
                                title: 'Data Login',
                                items: [
                                  _ProfileItem(
                                    label: 'Nama Login',
                                    value: user?.nama ?? '-',
                                  ),
                                  _ProfileItem(
                                    label: 'Email Login',
                                    value: user?.email ?? '-',
                                  ),
                                  _ProfileItem(
                                    label: 'Role Login',
                                    value: user?.roleName ?? '-',
                                  ),
                                ],
                              ),
                              _buildInfoCard(
                                title: 'Status Akun',
                                items: [
                                  _ProfileItem(
                                    label: 'Status Login',
                                    value: 'Aktif',
                                  ),
                                  _ProfileItem(
                                    label: 'Akses',
                                    value: 'Dashboard Mentor',
                                  ),
                                  _ProfileItem(
                                    label: 'Mode',
                                    value: 'Web Portal',
                                  ),
                                ],
                              ),
                              _buildInfoCard(
                                title: 'Aksi Cepat',
                                items: [
                                  _ProfileItem(
                                    label: 'Kelola Soal',
                                    value: 'Buka halaman latihan',
                                  ),
                                  _ProfileItem(
                                    label: 'Tryout & Olimpiade',
                                    value: 'Kelola konten ujian',
                                  ),
                                  _ProfileItem(
                                    label: 'Logout',
                                    value: 'Keluar dari akun mentor',
                                  ),
                                ],
                              ),
                            ];

                            if (stacked) {
                              return Column(
                                children: [
                                  for (final card in cards) ...[
                                    card,
                                    const SizedBox(height: 14),
                                  ],
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 14),
                                Expanded(child: cards[1]),
                                const SizedBox(width: 14),
                                Expanded(child: cards[2]),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'Data di halaman ini diambil dari sesi login yang tersimpan, jadi nama, email, dan role akan mengikuti akun yang dipakai masuk ke portal.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                              height: 1.5,
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

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: const Color(0xFFEFF6FF),
      side: const BorderSide(color: Color(0xFFDBEAFE)),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<_ProfileItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProfileRow(label: item.label, value: item.value),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem {
  final String label;
  final String value;
  const _ProfileItem({required this.label, required this.value});
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
