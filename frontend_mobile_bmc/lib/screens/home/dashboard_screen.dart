import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final user = args?['user'] as Map<String, dynamic>?;
    final isActive = user?['is_active'] == true;
    final nama = user?['nama'] ?? 'Siswa';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 40, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, $nama',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isActive ? 'Akun aktif, selamat belajar!' : 'Akun belum aktif',
                            style: TextStyle(
                              fontSize: 14,
                              color: isActive ? Colors.green : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!isActive) ...[
              const Text(
                'Akun Anda harus didaftarkan paket les dan dibayar terlebih dahulu. Setelah pembayaran, admin akan mengaktifkan akun Anda.',
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/package');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Daftar Paket Les',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'Akun sudah aktif. Anda dapat mengakses semua fitur aplikasi.',
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
