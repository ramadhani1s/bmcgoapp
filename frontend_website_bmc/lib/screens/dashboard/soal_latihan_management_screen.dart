import 'package:flutter/material.dart';
import '../../models/latihan.dart';
import '../../models/soal_latihan.dart';
import '../../services/latihan_management_service.dart';
import '../../services/latihan_soal_service.dart';

class SoalLatihanManagementScreen extends StatefulWidget {
  const SoalLatihanManagementScreen({super.key});

  @override
  State<SoalLatihanManagementScreen> createState() =>
      _SoalLatihanManagementScreenState();
}

class _SoalLatihanManagementScreenState
    extends State<SoalLatihanManagementScreen> {
  bool _isLoading = true;
  List<Latihan> _allLatihan = [];
  List<SoalLatihan> _allSoal = [];
  List<Latihan> _filteredLatihan = [];
  String _searchQuery = '';
  String _selectedStatus = 'Semua Status';
  String _selectedMapel = 'Semua Mapel';
  Set<String> _mapelOptions = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final latihan = await LatihanManagementService.getLatihan();
    final soal = await LatihanSoalService.getSoalLatihan();

    if (!mounted) return;

    _mapelOptions.clear();
    _mapelOptions.add('Semua Mapel');
    for (final item in latihan) {
      _mapelOptions.add(item.mapel);
    }

    setState(() {
      _allLatihan = latihan;
      _allSoal = soal;
      _filteredLatihan = latihan;
      _isLoading = false;
    });
  }

  void _filterData() {
    List<Latihan> filtered = _allLatihan;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Filter by status
    if (_selectedStatus != 'Semua Status') {
      filtered = filtered
          .where((item) => item.status == _selectedStatus)
          .toList();
    }

    // Filter by mapel
    if (_selectedMapel != 'Semua Mapel') {
      filtered = filtered
          .where((item) => item.mapel == _selectedMapel)
          .toList();
    }

    setState(() => _filteredLatihan = filtered);
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final soalController = TextEditingController(text: '1');
    String selectedMapel = 'Matematika';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Buat Latihan Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Judul Latihan',
                    hintText: 'Contoh: Latihan Matematika - Persamaan Kuad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMapel,
                  decoration: InputDecoration(
                    labelText: 'Mata Pelajaran',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items:
                      [
                            'Matematika',
                            'Fisika',
                            'Kimia',
                            'Biologi',
                            'Bahasa Indonesia',
                            'Bahasa Inggris',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedMapel = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: soalController,
                  decoration: InputDecoration(
                    labelText: 'Total Soal',
                    hintText: '1',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Judul tidak boleh kosong')),
                  );
                  return;
                }

                final result = await LatihanManagementService.createLatihan(
                  title: titleController.text,
                  mapel: selectedMapel,
                  totalSoal: int.tryParse(soalController.text) ?? 1,
                );

                if (!mounted) return;

                Navigator.pop(context);

                if (result['success']) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result['message'])));
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Latihan latihan) {
    final titleController = TextEditingController(text: latihan.title);
    String selectedMapel = latihan.mapel;
    final soalController = TextEditingController(
      text: latihan.totalSoal.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Latihan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Judul Latihan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMapel,
                  decoration: InputDecoration(
                    labelText: 'Mata Pelajaran',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items:
                      [
                            'Matematika',
                            'Fisika',
                            'Kimia',
                            'Biologi',
                            'Bahasa Indonesia',
                            'Bahasa Inggris',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedMapel = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: soalController,
                  decoration: InputDecoration(
                    labelText: 'Total Soal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await LatihanManagementService.updateLatihan(
                  latihanId: latihan.id,
                  title: titleController.text,
                  mapel: selectedMapel,
                  totalSoal: int.tryParse(soalController.text) ?? 1,
                );

                if (!mounted) return;

                Navigator.pop(context);

                if (result['success']) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result['message'])));
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteLatihan(Latihan latihan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Latihan'),
        content: Text('Hapus "${latihan.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await LatihanManagementService.deleteLatihan(latihan.id);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'])));
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<SoalLatihan> _getSoalByLatihan(Latihan latihan) {
    return _allSoal
        .where((soal) => latihan.questionIds.contains(soal.id))
        .toList();
  }

  Map<String, List<Latihan>> _groupLatihanByMapel() {
    final grouped = <String, List<Latihan>>{};
    for (final latihan in _filteredLatihan) {
      if (!grouped.containsKey(latihan.mapel)) {
        grouped[latihan.mapel] = [];
      }
      grouped[latihan.mapel]!.add(latihan);
    }
    return grouped;
  }

  List<Widget> _buildLatihanByMapelSections() {
    final grouped = _groupLatihanByMapel();
    final sections = <Widget>[];

    for (final mapel in grouped.keys) {
      final latihans = grouped[mapel]!;

      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latihan $mapel',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${latihans.fold<int>(0, (sum, item) => sum + item.totalSoal)} soal',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...latihans.map((latihan) {
              final soalList = _getSoalByLatihan(latihan);
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildDetailedLatihanCard(latihan, soalList),
              );
            }),
          ],
        ),
      );

      sections.add(const SizedBox(height: 32));
    }

    return sections;
  }

  Widget _buildDetailedLatihanCard(
    Latihan latihan,
    List<SoalLatihan> soalList,
  ) {
    final createdSoal = soalList.length;
    final totalSoal = latihan.totalSoal;
    final progressPercent = totalSoal > 0 ? createdSoal / totalSoal : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  latihan.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: latihan.isPublished
                      ? Colors.green[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  latihan.status,
                  style: TextStyle(
                    fontSize: 12,
                    color: latihan.isPublished
                        ? Colors.green[700]
                        : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Pembuatan Soal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$createdSoal dari $totalSoal soal telah dibuat',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(Colors.orange.shade500),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(totalSoal, (index) {
                    final questionNum = index + 1;
                    final isCreated = index < createdSoal;
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCreated ? Colors.green[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCreated
                              ? Colors.green[300]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        questionNum.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isCreated
                              ? Colors.green[700]
                              : Colors.grey[600],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (soalList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada soal',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...soalList.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final soal = entry.value;
              return _buildSoalCard(index, soal);
            }),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility),
                label: const Text('Lihat'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showEditDialog(latihan),
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _deleteLatihan(latihan),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoalCard(int nomorSoal, SoalLatihan soal) {
    final choices = [
      ('A', soal.pilihanA),
      ('B', soal.pilihanB),
      ('C', soal.pilihanC),
      ('D', soal.pilihanD),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      nomorSoal.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Soal Latihan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                'Kunci ${soal.jawaban}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            soal.pertanyaan,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ...choices.map((choice) {
            final label = choice.$1;
            final text = choice.$2;
            final isAnswer = label == soal.jawaban;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAnswer ? Colors.green[50] : Colors.grey[50],
                border: Border.all(
                  color: isAnswer ? Colors.green[300]! : Colors.grey[200]!,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isAnswer ? Colors.green[700] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                label: const Text(
                  'Hapus',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDipublikasikan = _allLatihan.where((e) => e.isPublished).length;
    final totalSoal = _allLatihan.fold<int>(
      0,
      (sum, item) => sum + item.totalSoal,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Soal Latihan'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kelola Soal Latihan',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buat dan kelola soal latihan untuk siswa Anda',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Stats Cards
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatCard(
                            label: 'Total Latihan',
                            value: _allLatihan.length.toString(),
                            icon: Icons.assignment,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            label: 'Dipublikasikan',
                            value: totalDipublikasikan.toString(),
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            label: 'Total Soal',
                            value: totalSoal.toString(),
                            icon: Icons.help,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            label: 'Mapel',
                            value: _mapelOptions.length.toString(),
                            icon: Icons.category,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Search and Filter
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              _searchQuery = value;
                              _filterData();
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari soal latihan...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _selectedStatus,
                          items: ['Semua Status', 'Draft', 'Dipublikasikan']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStatus = value);
                              _filterData();
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _selectedMapel,
                          items: _mapelOptions
                              .toList()
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedMapel = value);
                              _filterData();
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        FloatingActionButton(
                          onPressed: _showCreateDialog,
                          mini: false,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Grouped Latihan by Mapel
                    if (_filteredLatihan.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada latihan terdaftar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._buildLatihanByMapelSections(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

}
