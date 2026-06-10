import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/config/api_config.dart';
import 'package:http/http.dart' as http;

import '../../core/session/app_session.dart';
import '../../widgets/olimpiade/olimpiade_header.dart';
import '../../widgets/olimpiade/olimpiade_empty.dart';
import '../../widgets/olimpiade/olimpiade_card.dart';

class OlimpiadeScreen extends StatefulWidget {
  const OlimpiadeScreen({super.key});

  @override
  State<OlimpiadeScreen> createState() => _OlimpiadeScreenState();
}

class _OlimpiadeScreenState extends State<OlimpiadeScreen> {
  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFF7EEEF);
  static const Color _textPrimary = Color(0xFF25273D);
  static const Color _gold = Color(0xFFF5A623);

  List<Map<String, dynamic>> _olimpiadeTersedia = [];
  List<Map<String, dynamic>> _olimpiadeSelesai = [];
  bool _isLoading = true;
  String _selectedStatus = 'tersedia';

  final List<Map<String, String>> _tabs = [
    {'label': 'Tersedia', 'value': 'tersedia'},
    {'label': 'Riwayat', 'value': 'selesai'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchOlimpiade();
  }

  Future<String> _getToken() async {
    final token = await AppSession.getAuthToken();
    return token ?? '';
  }

  Future<void> _fetchOlimpiade() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      final uriTersedia = Uri.parse('${ApiConfig.baseUrl}/api/siswa/olimpiade').replace(
        queryParameters: {'status': 'tersedia'},
      );
      final uriSelesai = Uri.parse('${ApiConfig.baseUrl}/api/siswa/olimpiade').replace(
        queryParameters: {'status': 'selesai'},
      );

      final responseTersedia = await http.get(uriTersedia, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      final responseSelesai = await http.get(uriSelesai, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (responseTersedia.statusCode == 200 && responseSelesai.statusCode == 200) {
        final dataTersedia = jsonDecode(responseTersedia.body) as Map<String, dynamic>;
        final dataSelesai = jsonDecode(responseSelesai.body) as Map<String, dynamic>;

        setState(() {
          _olimpiadeTersedia = (dataTersedia['data'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
          _olimpiadeSelesai = (dataSelesai['data'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Gagal memuat data olimpiade. Silakan coba lagi.');
    }
  }
  
  // Helper to display error messages
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalSelesai = _olimpiadeSelesai.length;
    int totalTersedia = _olimpiadeTersedia.length;
    List<Map<String, dynamic>> currentList = _selectedStatus == 'tersedia' ? _olimpiadeTersedia : _olimpiadeSelesai;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            OlimpiadeHeader(
              tabs: _tabs,
              selected: _selectedStatus,
              onTabSelected: (value) {
                setState(() => _selectedStatus = value);
              },
              accentColor: _accent,
              totalSelesai: totalSelesai,
              totalTersedia: totalTersedia,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _accent))
                  : currentList.isEmpty
                      ? const OlimpiadeEmpty(accentColor: _accent)
                      : RefreshIndicator(
                          color: _accent,
                          onRefresh: () => _fetchOlimpiade(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: currentList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final o = currentList[index];
                              return OlimpiadeCard(
                                olimpiade: o,
                                onTap: () {
                                  final status = o['status'] as String? ?? 'tersedia';
                                  if (status == 'tersedia') {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => OlimpiadeSoalScreen(olimpiade: o),
                                    )).then((_) => _fetchOlimpiade());
                                  } else {
                                    // Build hasil map from olimpiade data (list endpoint)
                                    final hasilMap = <String, dynamic>{
                                      'skor': o['skor'],
                                      'ranking': o['ranking'],
                                      'jawaban_benar': (o['jawaban_benar'] as num?)?.toInt() ?? 0,
                                      'jawaban_salah': (o['jawaban_salah'] as num?)?.toInt() ?? 0,
                                      'tidak_dijawab': (o['tidak_dijawab'] as num?)?.toInt() ?? 0,
                                      'total_soal': (o['total_questions'] as num?)?.toInt() ?? 0,
                                    };
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => OlimpiadeHasilScreen(
                                        olimpiade: o,
                                        hasil: hasilMap,
                                      ),
                                    )).then((_) => _fetchOlimpiade());
                                  }
                                },
                                goldColor: _gold,
                                textPrimary: _textPrimary,
                                textMuted: const Color(0xFF8D90A3),
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

// ===================== SOAL SCREEN =====================
class OlimpiadeSoalScreen extends StatefulWidget {
  final Map<String, dynamic> olimpiade;
  const OlimpiadeSoalScreen({super.key, required this.olimpiade});

  @override
  State<OlimpiadeSoalScreen> createState() => _OlimpiadeSoalScreenState();
}

class _OlimpiadeSoalScreenState extends State<OlimpiadeSoalScreen> {
  static const Color _accent = Color(0xFFFF7070);

  List<Map<String, dynamic>> _soalList = [];
  final Map<int, String> _jawaban = {};
  final Set<int> _raguRagu = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showNavigasi = false;
  late Timer _timer;
  int _sisaDetik = 0;

  @override
  void initState() {
    super.initState();
    _sisaDetik = (widget.olimpiade['durasi'] as int? ?? 120) * 60;
    _fetchSoal();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // ✅ FIX: cek mounted di dalam timer agar tidak setState setelah dispose
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_sisaDetik <= 0) {
        timer.cancel();
        _submitOlimpiade();
      } else {
        setState(() => _sisaDetik--);
      }
    });
  }

  String get _timerText {
    final jam = _sisaDetik ~/ 3600;
    final menit = (_sisaDetik % 3600) ~/ 60;
    final detik = _sisaDetik % 60;
    if (jam > 0) {
      return '${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
    }
    return '${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
  }

  Future<String> _getToken() async {
    final token = await AppSession.getAuthToken();
    return token ?? '';
  }

  Future<void> _fetchSoal() async {
    try {
      final token = await _getToken();
      final id = widget.olimpiade['id'];
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/siswa/olimpiade/$id/soal'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['data'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        setState(() {
          _soalList = list;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitOlimpiade() async {
    _timer.cancel();
    try {
      final token = await _getToken();
      final id = widget.olimpiade['id'];
      final jawabanStr = _jawaban.map((k, v) => MapEntry(k.toString(), v));

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/siswa/olimpiade/$id/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'jawaban': jawabanStr}),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => OlimpiadeHasilScreen(
            olimpiade: widget.olimpiade,
            hasil: data['data'] as Map<String, dynamic>,
          ),
        ));
      }
    } catch (e) {
      // ignore
    }
  }

  void _showSelesaiDialog() {
    final dijawab = _jawaban.length;
    final total = _soalList.length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Selesai Olimpiade?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Anda telah menjawab $dijawab dari $total soal.\nMasih ada ${total - dijawab} soal yang belum dijawab.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Color(0xFFFF7070))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitOlimpiade();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF12B892)),
            child: const Text('Ya, Selesai', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _accent)));
    }

    if (_soalList.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Belum ada soal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali')),
            ],
          ),
        ),
      );
    }

    final soal = _soalList[_currentIndex];
    final soalId = soal['id'] as int;
    final pilihanMap = {
      'A': soal['pilihan_a'] as String? ?? '',
      'B': soal['pilihan_b'] as String? ?? '',
      'C': soal['pilihan_c'] as String? ?? '',
      'D': soal['pilihan_d'] as String? ?? '',
      'E': soal['pilihan_e'] as String? ?? '',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF7EEEF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildSoalHeader(soalId),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16)),
                          child: Text(soal['pertanyaan'] as String? ?? '',
                              style: const TextStyle(fontSize: 15, height: 1.5)),
                        ),
                        const SizedBox(height: 12),
                        ...pilihanMap.entries
                            .where((e) => e.value.isNotEmpty)
                            .map((entry) {
                          final isSelected = _jawaban[soalId] == entry.key;
                          return GestureDetector(
                            onTap: () => setState(() => _jawaban[soalId] = entry.key),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFFEFEF) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: isSelected ? _accent : const Color(0xFFE0E0E0),
                                    width: isSelected ? 1.5 : 1),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        isSelected ? _accent : const Color(0xFFF0F0F0),
                                    child: Text(entry.key,
                                        style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF8D90A3),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text(entry.value,
                                          style: const TextStyle(fontSize: 14))),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() {
                            if (_raguRagu.contains(soalId)) {
                              _raguRagu.remove(soalId);
                            } else {
                              _raguRagu.add(soalId);
                            }
                          }),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: _raguRagu.contains(soalId)
                                  ? const Color(0xFFFFF8E1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: _raguRagu.contains(soalId)
                                      ? const Color(0xFFF5A623)
                                      : const Color(0xFFE0E0E0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bookmark_border_rounded,
                                    color: _raguRagu.contains(soalId)
                                        ? const Color(0xFFF5A623)
                                        : const Color(0xFF8D90A3),
                                    size: 18),
                                const SizedBox(width: 6),
                                Text('Tandai Ragu-ragu',
                                    style: TextStyle(
                                        color: _raguRagu.contains(soalId)
                                            ? const Color(0xFFF5A623)
                                            : const Color(0xFF8D90A3),
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
            if (_showNavigasi) _buildNavigasiSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildSoalHeader(int soalId) {
    final progress = (_currentIndex + 1) / _soalList.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFF7070),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      // ✅ FIX: ganti withOpacity → withValues
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.olimpiade['nama'] as String? ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text('Soal ${_currentIndex + 1} dari ${_soalList.length}',
                        style: const TextStyle(
                            color: Color(0xFFFFE5E5), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(_timerText,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Sebelumnya'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8D90A3),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentIndex < _soalList.length - 1
                      ? () => setState(() => _currentIndex++)
                      : null,
                  icon: const Text('Selanjutnya'),
                  label: const Icon(Icons.chevron_right_rounded),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7070),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showNavigasi = !_showNavigasi),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7070),
                    side: const BorderSide(color: Color(0xFFFF7070)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child:
                      Text('Navigasi (${_jawaban.length}/${_soalList.length})'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showSelesaiDialog,
                  icon: const Icon(Icons.flag_rounded, size: 16),
                  label: const Text('Selesai'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12B892),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigasiSheet() {
    return GestureDetector(
      onTap: () => setState(() => _showNavigasi = false),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Navigasi Soal',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 10,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 1,
                      ),
                      itemCount: _soalList.length,
                      itemBuilder: (context, index) {
                        final soalId = _soalList[index]['id'] as int;
                        final dijawab = _jawaban.containsKey(soalId);
                        final ragu = _raguRagu.contains(soalId);
                        final isCurrent = index == _currentIndex;

                        Color bg = const Color(0xFFF0F0F0);
                        Color textColor = const Color(0xFF8D90A3);
                        if (isCurrent) {
                          bg = const Color(0xFFFF7070);
                          textColor = Colors.white;
                        } else if (ragu) {
                          bg = const Color(0xFFFFF8E1);
                          textColor = const Color(0xFFF5A623);
                        } else if (dijawab) {
                          bg = const Color(0xFFE3FBF4);
                          textColor = const Color(0xFF12B892);
                        }

                        return GestureDetector(
                          onTap: () => setState(() {
                            _currentIndex = index;
                            _showNavigasi = false;
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(6)),
                            child: Center(
                                child: Text('${index + 1}',
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700))),
                          ),
                        );
                      },
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
}

// ===================== HASIL SCREEN =====================
class OlimpiadeHasilScreen extends StatelessWidget {
  final Map<String, dynamic> olimpiade;
  final Map<String, dynamic> hasil;

  const OlimpiadeHasilScreen(
      {super.key, required this.olimpiade, required this.hasil});

  static const Color _accent = Color(0xFFFF7070);
  static const Color _gold = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    final skor = (hasil['skor'] as num?)?.toInt() ?? 0;
    final benar = (hasil['jawaban_benar'] as num?)?.toInt() ?? 0;
    final salah = (hasil['jawaban_salah'] as num?)?.toInt() ?? 0;
    final tidakDijawab = (hasil['tidak_dijawab'] as num?)?.toInt() ?? 0;
    final rawTotal = (hasil['total_soal'] as num?)?.toInt() ?? 0;
    // Fallback: compute total from benar+salah+tidak if total_soal is 0
    final totalSoal = rawTotal > 0 ? rawTotal : (benar + salah + tidakDijawab);

    String predikat;
    if (skor >= 90) {
      predikat = 'Luar Biasa!';
    } else if (skor >= 80) {
      predikat = 'Hebat! Kamu Top 10!';
    } else if (skor >= 70) {
      predikat = 'Bagus! Terus Semangat!';
    } else if (skor >= 60) {
      predikat = 'Lumayan, Tingkatkan Lagi!';
    } else {
      predikat = 'Jangan Menyerah!';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7EEEF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          // ✅ FIX: ganti withOpacity → withValues
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hasil Olimpiade',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        Text(olimpiade['nama'] as String? ?? '',
                            style: const TextStyle(
                                color: Color(0xFFFFE5E5), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: _gold,
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          const Text('🏅', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Text('$skor',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 64,
                                  fontWeight: FontWeight.w800,
                                  height: 1)),
                          const Text('dari 100 poin',
                              style: TextStyle(
                                  color: Color(0xFFFFE5B0), fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(predikat,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Statistik Pengerjaan',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          _buildStatRow('Jawaban Benar', benar, totalSoal,
                              const Color(0xFF12B892), Icons.check_rounded),
                          const SizedBox(height: 10),
                          _buildStatRow('Jawaban Salah', salah, totalSoal,
                              _accent, Icons.close_rounded),
                          const SizedBox(height: 10),
                          _buildStatRow('Tidak Dijawab', tidakDijawab,
                              totalSoal, const Color(0xFF8D90A3),
                              Icons.circle_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3FBF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            // ✅ FIX: ganti withOpacity → withValues
                            color: const Color(0xFF12B892).withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Color(0xFF12B892)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hasil Tersimpan!',
                                    style: TextStyle(
                                        color: Color(0xFF12B892),
                                        fontWeight: FontWeight.w700)),
                                Text(
                                    'Hasil olimpiade kamu sudah tercatat dan akan ditampilkan di profil prestasi.',
                                    style: TextStyle(
                                        color: Color(0xFF12B892),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accent,
                              side: const BorderSide(color: _accent),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Kembali',
                                style:
                                    TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
      String label, int nilai, int total, Color color, IconData icon) {
    final progress = total > 0 ? nilai / total : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            Text('$nilai / $total',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: const Color(0xFFF0F0F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}