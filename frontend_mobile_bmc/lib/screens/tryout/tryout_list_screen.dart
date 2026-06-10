import 'package:flutter/material.dart';
import '../../services/tryout_service.dart';
import 'tryout_exam_screen.dart';
import 'tryout_result_dashboard.dart';

class TryOutListScreen extends StatefulWidget {
  const TryOutListScreen({super.key});

  @override
  State<TryOutListScreen> createState() => _TryOutListScreenState();
}

class _TryOutListScreenState extends State<TryOutListScreen> {
  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFF7EEEF);
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _packagesTersedia = [];
  List<Map<String, dynamic>> _packagesSelesai = [];
  String _tab = 'tersedia';

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    setState(() => _isLoading = true);
    final tersediaList = await TryOutService.getPackages(status: 'tersedia');
    final selesaiList = await TryOutService.getPackages(status: 'selesai');
    if (!mounted) return;
    setState(() {
      _packagesTersedia = tersediaList;
      _packagesSelesai = selesaiList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalSelesai = _packagesSelesai.length;
    int totalTersedia = _packagesTersedia.length;
    
    List<Map<String, dynamic>> currentPackages = _tab == 'tersedia' ? _packagesTersedia : _packagesSelesai;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(totalSelesai, totalTersedia),
            const SizedBox(height: 12),
            _buildTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _accent))
                  : currentPackages.isEmpty
                      ? const Center(child: Text('Tidak ada paket Try Out', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)))
                      : RefreshIndicator(
                          color: _accent,
                          onRefresh: _fetchPackages,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final p = currentPackages[index];
                              return _buildPackageCard(p);
                            },
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemCount: currentPackages.length,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int selesai, int tersedia) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.description_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Try Out', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Latih kemampuanmu!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(Icons.emoji_events_rounded, '$selesai', 'Selesai'),
              _buildStatItem(Icons.assignment_rounded, '$tersedia', 'Tersedia'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabButton('Tersedia', 'tersedia', Icons.assignment_rounded),
        const SizedBox(width: 16),
        _buildTabButton('Riwayat', 'selesai', Icons.history_rounded),
      ],
    );
  }

  Widget _buildTabButton(String label, String value, IconData icon) {
    final isSelected = _tab == value;
    return GestureDetector(
      onTap: () {
        setState(() => _tab = value);
      },
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? _accent : Colors.grey),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: isSelected ? _accent : Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          if (isSelected) Container(width: 60, height: 3, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2)))
          else const SizedBox(height: 3),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> p) {
    final isSelesai = _tab == 'selesai';
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isSelesai ? [const Color(0xFF12B892), const Color(0xFF0F9A7A)] : [const Color(0xFF4A90E2), const Color(0xFF357ABD)]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit_document, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['judul'] ?? 'Try Out', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Text(p['tanggal'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Text(isSelesai ? 'Selesai' : 'Tersedia', style: TextStyle(color: isSelesai ? const Color(0xFF12B892) : const Color(0xFF4A90E2), fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Try Out gabungan dengan berbagai kategori soal.', style: TextStyle(fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCardStatItem('${p['total_questions'] ?? 0}', 'Soal', const Color(0xFFE3F2FD), const Color(0xFF1976D2)),
                    _buildCardStatItem('${p['durasi'] ?? 0}', 'Menit', const Color(0xFFFFF3E0), const Color(0xFFF57C00)),
                    _buildCardStatItem(isSelesai ? '${p['nilai'] ?? 0}' : '-', 'Nilai', isSelesai ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), isSelesai ? const Color(0xFF388E3C) : const Color(0xFFD32F2F)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isSelesai) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TryOutResultDashboard(package: p, result: p)));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TryOutExamScreen(package: p))).then((_) => _fetchPackages());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelesai ? const Color(0xFF12B892) : const Color(0xFFF5A623),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(isSelesai ? 'Lihat Hasil & Pembahasan >' : 'Mulai Try Out >', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStatItem(String value, String label, Color bgColor, Color textColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
