import 'package:flutter/material.dart';

class EvaluasiSiswaScreen extends StatefulWidget {
  const EvaluasiSiswaScreen({super.key});

  @override
  State<EvaluasiSiswaScreen> createState() => _EvaluasiSiswaScreenState();
}

class _EvaluasiSiswaScreenState extends State<EvaluasiSiswaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock Data
  final List<Map<String, dynamic>> _latihanSoalSubmissions = [
    {
      'id': 1,
      'siswa': 'Budi Santoso',
      'avatar': 'B',
      'tugas': 'Latihan Matematika Dasar',
      'tanggal': '26 Apr 2026',
      'status': 'Belum Dinilai',
      'nilai': null,
      'catatan': '',
    },
    {
      'id': 2,
      'siswa': 'Siti Aminah',
      'avatar': 'S',
      'tugas': 'Latihan Matematika Dasar',
      'tanggal': '25 Apr 2026',
      'status': 'Sudah Dinilai',
      'nilai': 85.0,
      'catatan': 'Sangat baik, pertahankan prestasimu!',
    },
    {
      'id': 3,
      'siswa': 'Andi Wijaya',
      'avatar': 'A',
      'tugas': 'Fisika Kinematika',
      'tanggal': '24 Apr 2026',
      'status': 'Belum Dinilai',
      'nilai': null,
      'catatan': '',
    },
  ];

  final List<Map<String, dynamic>> _tryoutSubmissions = [
    {
      'id': 4,
      'siswa': 'Budi Santoso',
      'avatar': 'B',
      'tugas': 'Try Out UTBK SNBT 1',
      'tanggal': '20 Apr 2026',
      'status': 'Sudah Dinilai',
      'nilai': 70.0,
      'catatan': 'Perlu lebih banyak latihan di Penalaran Umum.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openEvaluationModal(Map<String, dynamic> submission, bool isTryout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EvaluationModal(
        submission: submission,
        onSave: (nilai, catatan) {
          setState(() {
            submission['nilai'] = nilai;
            submission['catatan'] = catatan;
            submission['status'] = 'Sudah Dinilai';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Evaluasi berhasil disimpan!'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Evaluasi & Penilaian Siswa',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubmissionList(_latihanSoalSubmissions, false),
                _buildSubmissionList(_tryoutSubmissions, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bantu Siswa Berkembang 🚀',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Berikan nilai yang adil dan catatan evaluasi yang memotivasi untuk membantu kemajuan belajar mereka.',
                  style: TextStyle(
                    color: Colors.indigo.shade50,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_half_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
        ),
        labelColor: const Color(0xFF1D4ED8),
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        indicatorPadding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Latihan Soal'),
          Tab(text: 'Hasil Try Out'),
        ],
      ),
    );
  }

  Widget _buildSubmissionList(List<Map<String, dynamic>> submissions, bool isTryout) {
    if (submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Belum ada submission',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final data = submissions[index];
        final isEvaluated = data['status'] == 'Sudah Dinilai';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isEvaluated ? Colors.green.shade200 : Colors.blue.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openEvaluationModal(data, isTryout),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isEvaluated ? Colors.green.shade50 : Colors.indigo.shade50,
                      child: Text(
                        data['avatar'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isEvaluated ? Colors.green.shade700 : Colors.indigo.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data['siswa'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isEvaluated ? Colors.green.shade50 : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  data['status'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isEvaluated ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['tugas'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Text(
                                'Dikumpulkan: ${data['tanggal']}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          
                          if (isEvaluated) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('Nilai', style: TextStyle(fontSize: 10, color: Colors.blue)),
                                      Text(
                                        '${data['nilai']}',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Catatan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text(
                                        data['catatan'],
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class EvaluationModal extends StatefulWidget {
  final Map<String, dynamic> submission;
  final Function(double nilai, String catatan) onSave;

  const EvaluationModal({super.key, required this.submission, required this.onSave});

  @override
  State<EvaluationModal> createState() => _EvaluationModalState();
}

class _EvaluationModalState extends State<EvaluationModal> {
  double _nilai = 0;
  final TextEditingController _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.submission['nilai'] != null) {
      _nilai = widget.submission['nilai'] is int 
          ? (widget.submission['nilai'] as int).toDouble() 
          : widget.submission['nilai'];
    }
    if (widget.submission['catatan'] != null) {
      _catatanController.text = widget.submission['catatan'];
    }
  }

  Color _getScoreColor(double score) {
    if (score < 50) return Colors.red;
    if (score < 75) return Colors.orange;
    if (score < 90) return Colors.blue;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      widget.submission['avatar'],
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evaluasi untuk ${widget.submission['siswa']}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.submission['tugas'],
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 32),
              
              // Skor Slider
              const Text('Berikan Nilai (0 - 100)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _getScoreColor(_nilai),
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: _getScoreColor(_nilai),
                        overlayColor: _getScoreColor(_nilai).withValues(alpha: 0.2),
                        trackHeight: 8,
                      ),
                      child: Slider(
                        value: _nilai,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: (val) {
                          setState(() {
                            _nilai = val;
                          });
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _getScoreColor(_nilai).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getScoreColor(_nilai).withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(
                        _nilai.toInt().toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(_nilai),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Catatan
              const Text('Catatan & Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              TextField(
                controller: _catatanController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tulis evaluasi, saran, atau apresiasi untuk siswa...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(_nilai, _catatanController.text);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan Evaluasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
