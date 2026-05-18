import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingHistory = true;
  Map<String, dynamic>? _latestResult;
  List<dynamic> _history = const [];
  String _selectedClass = 'Semua Kelas';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    final history = await AttendanceService.getHistory(
      className: _selectedClass == 'Semua Kelas' ? null : _selectedClass,
      date: _selectedDate,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _history = history;
      _isLoadingHistory = false;

      if (_selectedClass != 'Semua Kelas') {
        final hasSelectedClass = _classOptions.contains(_selectedClass);
        if (!hasSelectedClass) {
          _selectedClass = 'Semua Kelas';
        }
      }
    });
  }

  List<String> get _classOptions {
    final set = <String>{'Semua Kelas'};
    for (final item in _history) {
      final className = (item['class_name'] ?? '').toString().trim();
      if (className.isNotEmpty) {
        set.add(className);
      }
    }
    return set.toList();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(selected.year, selected.month, selected.day);
    });
    await _loadHistory();
  }

  void _clearFilters() {
    setState(() {
      _selectedClass = 'Semua Kelas';
      _selectedDate = null;
    });
    _loadHistory();
  }

  Future<void> _submitToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token absensi wajib diisi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await AttendanceService.submitToken(token);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result['message'] ?? 'Gagal kirim token absensi').toString()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _latestResult = result['attendance'] as Map<String, dynamic>?;
    });

    _tokenController.clear();
    await _loadHistory();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text((result['message'] ?? 'Absensi berhasil').toString()),
        backgroundColor: const Color(0xFF22C55E),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hadir':
        return const Color(0xFF16A34A);
      case 'terlambat':
        return const Color(0xFFE67E22);
      case 'tidak_hadir':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(dynamic value) {
    final parsed = DateTime.tryParse((value ?? '').toString());
    if (parsed == null) {
      return '-';
    }

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _formatFilterDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Kelas'),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.08),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Input Token Absensi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan token yang diberikan mentor. 0-15 menit: hadir, >15-30 menit: terlambat, >30 menit: tidak hadir.',
                      style: TextStyle(color: Color(0xFF64748B), height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _tokenController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Contoh: AB12CD',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitToken,
                        icon: const Icon(Icons.how_to_reg_outlined),
                        label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Token'),
                      ),
                    ),
                  ],
                ),
              ),
              if (_latestResult != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.06),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hasil Absensi Terakhir',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      _buildStatusChip((_latestResult!['status'] ?? '-').toString()),
                      const SizedBox(height: 8),
                      Text('Kelas: ${(_latestResult!['class_name'] ?? '-').toString()}'),
                      Text('Mapel: ${(_latestResult!['subject'] ?? '-').toString()}'),
                      Text('Waktu Input: ${_formatDate(_latestResult!['submitted_at'])}'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Riwayat Absensi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Riwayat',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _classOptions.contains(_selectedClass)
                          ? _selectedClass
                          : 'Semua Kelas',
                      items: _classOptions
                          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) async {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedClass = value;
                        });
                        await _loadHistory();
                      },
                      decoration: InputDecoration(
                        labelText: 'Kelas',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              _selectedDate == null
                                  ? 'Pilih Tanggal'
                                  : _formatFilterDate(_selectedDate!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isLoadingHistory)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ))
              else if (_history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('Belum ada data absensi.'),
                )
              else
                ..._history.map((item) {
                  final status = (item['status'] ?? '-').toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (item['class_name'] ?? '-').toString(),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text('Mapel: ${(item['subject'] ?? '-').toString()}'),
                              Text('Input: ${_formatDate(item['submitted_at'])}'),
                            ],
                          ),
                        ),
                        _buildStatusChip(status),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
