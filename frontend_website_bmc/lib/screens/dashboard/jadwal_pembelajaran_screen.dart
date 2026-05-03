// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import '../../services/jadwal_pembelajaran_service.dart';

class JadwalPembelajaranScreen extends StatefulWidget {
  const JadwalPembelajaranScreen({super.key});

  @override
  State<JadwalPembelajaranScreen> createState() =>
      _JadwalPembelajaranScreenState();
}

class _JadwalPembelajaranScreenState extends State<JadwalPembelajaranScreen> {
  static const Color _headerBlue = Color(0xFF175CFF);
  static const Color _accentGreen = Color(0xFF1CB58A);
  static const Color _lightGray = Color(0xFFF7F8FC);
  static const Color _borderGray = Color(0xFFE6EAF0);
  List<Map<String, dynamic>> jadwalList = [];
  List<Map<String, dynamic>> paketList = [];
  List<Map<String, dynamic>> mentorList = [];

  bool isLoading = true;
  String selectedHari = '';
  int? selectedMentorFilterId;

  static const List<String> hariList = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _mataPelajaranOptions = [
    'Matematika',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Fisika',
    'Kimia',
    'Biologi',
    'UTBK',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        JadwalService.getPaketList(),
        JadwalService.getMentorList(),
        JadwalService.getJadwalList(),
      ]);

      if (!mounted) return;

      setState(() {
        paketList = results[0];
        mentorList = results[1];
        jadwalList = results[2];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        paketList = [];
        mentorList = [];
        jadwalList = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat jadwal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredRows {
    return jadwalList.where((jadwal) {
      final hariMatch =
          selectedHari.isEmpty || jadwal['hari']?.toString() == selectedHari;
      final mentorMatch =
          selectedMentorFilterId == null ||
          _asInt(jadwal['mentor_id']) == selectedMentorFilterId;
      return hariMatch && mentorMatch;
    }).toList();
  }
  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
  String _timeToString(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    if (text.isEmpty) return '-';

    if (text.contains('T')) {
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
    }

    final parts = text.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return text;
  }


  List<String>? _parseWaktuRange(String value) {
    final match = RegExp(
      r'(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})',
    ).firstMatch(value);
    if (match == null) return null;
    return [match.group(1)!, match.group(2)!];
  }

  TimeOfDay _timeOfDayFromString(String time, {int fallbackHour = 8}) {
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return TimeOfDay(hour: hour ?? fallbackHour, minute: minute ?? 0);
  }
  String _packageLabel(Map<String, dynamic> paket) {
    return (paket['nama_paket'] ?? paket['nama'] ?? 'Paket').toString();
  }

  String _mentorLabel(Map<String, dynamic> mentor) {
    return (mentor['nama_mentor'] ?? mentor['nama'] ?? 'Mentor').toString();
  }

  Map<String, dynamic>? _findPaketById(int? id) {
    if (id == null) return null;
    for (final paket in paketList) {
      if (_asInt(paket['id']) == id) return paket;
    }
    return null;
  }

  Map<String, dynamic>? _findMentorById(int? id) {
    if (id == null) return null;
    for (final mentor in mentorList) {
      if (_asInt(mentor['id']) == id) return mentor;
    }
    return null;
  }

  String _resolveMentorName(int mentorId) {
    final mentor = _findMentorById(mentorId);
    return mentor == null ? 'Mentor #$mentorId' : _mentorLabel(mentor);
  }

  String _resolveKelas(int paketId) {
    final paket = _findPaketById(paketId);
    if (paket == null) return '-';
    return _packageLabel(paket);
  }
  InputDecoration _fieldDecoration(
    String label, {
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: _lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _headerBlue),
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    );

  int _countJadwalHariIni() {
    final now = DateTime.now();
    final hariIni = hariList[now.weekday - 1];
    return jadwalList.where((jadwal) => jadwal['hari'] == hariIni).length;
  }

  Future<void> _createOrUpdateJadwal({Map<String, dynamic>? existing}) async {
    final formKey = GlobalKey<FormState>();

    int? selectedPaketId = existing == null
        ? null
        : _asInt(existing['paket_id']);
    int? selectedMentorId = existing == null
        ? null
        : _asInt(existing['mentor_id']);
    String? selectedHariValue = existing == null
        ? null
        : existing['hari']?.toString();

    final mataPelajaranController = TextEditingController(
      text: existing?['mata_pelajaran']?.toString() ?? '',
    );
    final waktuController = TextEditingController(
      text: existing == null
          ? ''
          : '${_timeToString(existing['jam_mulai'])} - ${_timeToString(existing['jam_selesai'])}',
    );
    final ruangController = TextEditingController(
      text: existing?['ruang']?.toString() ?? '',
    );

    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            Future<void> pickAndSetWaktu() async {
              final currentRange = _parseWaktuRange(waktuController.text);
              final startInitial = currentRange == null
                  ? const TimeOfDay(hour: 8, minute: 0)
                  : _timeOfDayFromString(currentRange[0], fallbackHour: 8);
              final endInitial = currentRange == null
                  ? const TimeOfDay(hour: 10, minute: 0)
                  : _timeOfDayFromString(currentRange[1], fallbackHour: 10);

              final pickedStart = await showTimePicker(
                context: dialogContext,
                initialTime: startInitial,
              );
              if (pickedStart == null) return;

              final pickedEnd = await showTimePicker(
                context: dialogContext,
                initialTime: endInitial,
              );
              if (pickedEnd == null) return;

              setModalState(() {
                waktuController.text =
                    '${pickedStart.hour.toString().padLeft(2, '0')}:${pickedStart.minute.toString().padLeft(2, '0')} - ${pickedEnd.hour.toString().padLeft(2, '0')}:${pickedEnd.minute.toString().padLeft(2, '0')}';
              });

            Future<void> pickAndSetTime(
              TextEditingController controller,
            ) async {
              final parsedHour =
                  int.tryParse(controller.text.split(':').first) ?? 8;
              final parsedMinute = controller.text.contains(':')
                  ? int.tryParse(controller.text.split(':')[1]) ?? 0
                  : 0;

              final picked = await showTimePicker(
                context: dialogContext,
                initialTime: TimeOfDay(hour: parsedHour, minute: parsedMinute),
              );

              if (picked != null) {
                setModalState(() {
                  controller.text =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
              }
            }

            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              if (selectedPaketId == null || selectedMentorId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Paket dan mentor wajib dipilih'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final waktuParts = _parseWaktuRange(waktuController.text.trim());
              if (waktuParts == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '❌ Waktu wajib diisi dengan format 08:00 - 10:00',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (isSubmitting) return;

              final rootMessenger = ScaffoldMessenger.of(context);
              final dialogMessenger = ScaffoldMessenger.of(dialogContext);
              final navigator = Navigator.of(dialogContext);

              setModalState(() => isSubmitting = true);

              final payload = <String, dynamic>{
                'paket_id': selectedPaketId,
                'mentor_id': selectedMentorId,
                'hari': selectedHariValue ?? '',
                'jam_mulai': waktuParts[0],
                'jam_selesai': waktuParts[1],
                'mata_pelajaran': mataPelajaranController.text.trim(),
                'ruang': ruangController.text.trim(),
              };

              final result = existing == null
                  ? await JadwalService.createJadwal(payload)
                  : await JadwalService.updateJadwal(
                      _asInt(existing['id']),
                      payload,
                    );

              if (!dialogContext.mounted) return;

              if (result['status'] == 'success') {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        existing == null
                            ? '✅ Jadwal berhasil dibuat'
                            : '✅ Jadwal berhasil diupdate',
                      ),
                      backgroundColor: Colors.green,
                navigator.pop();
                rootMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      existing == null
                          ? 'Jadwal berhasil dibuat'
                          : 'Jadwal berhasil diupdate',
                    ),
                  );
                  _loadInitialData();
                }
              } else {
                setModalState(() => isSubmitting = false);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                dialogMessenger.showSnackBar(

                dialogMessenger.showSnackBar(

                dialogMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal menyimpan jadwal: ${result['message'] ?? 'Unknown error'}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }


            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 96,
                vertical: 36,
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: const BoxDecoration(
                          color: _headerBlue,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    existing == null
                                        ? '➕ Tambah Jadwal Baru'
                                        : '✏️ Edit Jadwal',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    existing == null
                                        ? 'Buat jadwal pembelajaran mingguan baru'
                                        : 'Perbarui informasi jadwal pembelajaran',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),

            final title = existing == null ? 'Tambah Jadwal' : 'Edit Jadwal';

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<int?>(
                          initialValue: selectedPaketId,
                          items: paketList
                              .map(
                                (paket) => DropdownMenuItem<int?>(
                                  value: _asInt(paket['id']),
                                  child: Text(_packageLabel(paket)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setModalState(() => selectedPaketId = value);
                          },
                          validator: (value) =>
                              value == null ? 'Paket wajib dipilih' : null,
                          decoration: const InputDecoration(
                            labelText: 'Paket Les',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int?>(
                          initialValue: selectedMentorId,
                          items: mentorList
                              .map(
                                (mentor) => DropdownMenuItem<int?>(
                                  value: _asInt(mentor['id']),
                                  child: Text(_mentorLabel(mentor)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setModalState(() => selectedMentorId = value);
                          },
                          validator: (value) =>
                              value == null ? 'Mentor wajib dipilih' : null,
                          decoration: const InputDecoration(
                            labelText: 'Mentor',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedHariValue,
                          items: hariList
                              .map(
                                (hari) => DropdownMenuItem<String>(
                                  value: hari,
                                  child: Text(hari),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setModalState(() => selectedHariValue = value);
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Hari wajib dipilih'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Hari',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: jamMulaiController,
                          readOnly: true,
                          onTap: () => pickAndSetTime(jamMulaiController),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Jam mulai wajib diisi'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Jam Mulai',
                            hintText: '08:00',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.access_time_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: jamSelesaiController,
                          readOnly: true,
                          onTap: () => pickAndSetTime(jamSelesaiController),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Jam selesai wajib diisi'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Jam Selesai',
                            hintText: '09:30',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.access_time_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: mataPelajaranController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Mata pelajaran wajib diisi'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Mata Pelajaran',
                            border: OutlineInputBorder(),
                            hintText: 'Matematika',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: ruangController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Ruang wajib diisi'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Ruang',
                            border: OutlineInputBorder(),
                            hintText: 'Ruang A',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE4EAF3)),
                          ),
                          child: Text(
                            'Data yang disimpan akan masuk ke tabel jadwal dengan FK paket_id dan mentor_id.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                            IconButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              icon: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedHariValue,
                                      items: hariList
                                          .map(
                                            (hari) => DropdownMenuItem<String>(
                                              value: hari,
                                              child: Text(hari),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setModalState(
                                          () => selectedHariValue = value,
                                        );
                                      },
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                          ? 'Hari wajib dipilih'
                                          : null,
                                      decoration: _fieldDecoration(
                                        'Hari *',
                                        hintText: 'Pilih hari',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: waktuController,
                                      readOnly: true,
                                      onTap: pickAndSetWaktu,
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                          ? 'Waktu wajib diisi'
                                          : null,
                                      decoration: _fieldDecoration(
                                        'Waktu *',
                                        hintText: '08:00 - 10:00',
                                        suffixIcon: const Icon(
                                          Icons.access_time_rounded,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      initialValue: selectedPaketId,
                                      items: paketList
                                          .map(
                                            (paket) => DropdownMenuItem<int>(
                                              value: paket['id'] as int,
                                              child: Text(_packageLabel(paket)),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setModalState(
                                          () => selectedPaketId = value,
                                        );
                                      },
                                      validator: (value) => value == null
                                          ? 'Kelas wajib dipilih'
                                          : null,
                                      decoration: _fieldDecoration(
                                        'Kelas *',
                                        hintText: 'Kelas 10 A',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue:
                                          _mataPelajaranOptions.contains(
                                            mataPelajaranController.text,
                                          )
                                          ? mataPelajaranController.text
                                          : null,
                                      items:
                                          [
                                                ..._mataPelajaranOptions,
                                                if (mataPelajaranController
                                                        .text
                                                        .isNotEmpty &&
                                                    !_mataPelajaranOptions
                                                        .contains(
                                                          mataPelajaranController
                                                              .text,
                                                        ))
                                                  mataPelajaranController.text,
                                              ]
                                              .map(
                                                (mapel) =>
                                                    DropdownMenuItem<String>(
                                                      value: mapel,
                                                      child: Text(mapel),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (value) {
                                        setModalState(() {
                                          mataPelajaranController.text =
                                              value ?? '';
                                        });
                                      },
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                          ? 'Mata pelajaran wajib diisi'
                                          : null,
                                      decoration: _fieldDecoration(
                                        'Mata Pelajaran *',
                                        hintText: 'Pilih mapel',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      initialValue: selectedMentorId,
                                      items: mentorList
                                          .map(
                                            (mentor) => DropdownMenuItem<int>(
                                              value: mentor['id'] as int,
                                              child: Text(_mentorLabel(mentor)),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setModalState(
                                          () => selectedMentorId = value,
                                        );
                                      },
                                      validator: (value) => value == null
                                          ? 'Mentor wajib dipilih'
                                          : null,
                                      decoration: _fieldDecoration(
                                        'Mentor *',
                                        hintText: 'Pilih mentor',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: ruangController,
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                          ? 'Ruang wajib diisi'
                                          : null,
                                      decoration: _fieldDecoration(
                                        'Ruang *',
                                        hintText: 'Ruang A1',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: isSubmitting ? null : submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _headerBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      existing == null
                                          ? 'Tambah Jadwal'
                                          : 'Update',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _headerBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(existing == null ? 'Simpan' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );

    mataPelajaranController.dispose();
    waktuController.dispose();
    ruangController.dispose();
  }

  Future<void> _showDeleteDialog(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(

        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '🗑️ Hapus Jadwal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus jadwal ini? Tindakan ini tidak dapat dibatalkan.',
        ),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Jadwal',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus jadwal ini?',
          style: TextStyle(color: Color(0xFF6B7280), height: 1.45),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(

              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),

              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await JadwalService.deleteJadwal(id);
      if (!mounted) return;

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal berhasil dihapus'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _loadInitialData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal hapus jadwal: ${result['message'] ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  DataRow _buildRow(Map<String, dynamic> jadwal, int index) {
    final paketId = _asInt(jadwal['paket_id']);
    final mentorId = _asInt(jadwal['mentor_id']);
    final jamMulai = _timeToString(jadwal['jam_mulai']);
    final jamSelesai = _timeToString(jadwal['jam_selesai']);

    return DataRow(
      color: MaterialStateProperty.all(
        index.isEven ? Colors.white : _lightGray.withValues(alpha: 0.5),
      ),
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _headerBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              (jadwal['hari'] ?? '-').toString(),
              style: const TextStyle(
                color: _headerBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            '$jamMulai - $jamSelesai',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _accentGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _resolveKelas(paketId),
              style: TextStyle(
                color: _accentGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(Text((jadwal['mata_pelajaran'] ?? '-').toString())),
        DataCell(Text(_resolveMentorName(mentorId))),
        DataCell(Text((jadwal['ruang'] ?? '-').toString())),
        const DataCell(Text('0')),
        DataCell(
          Text(
            (jadwal['mata_pelajaran'] ?? '-').toString(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        DataCell(
          Text(
            _resolveMentorName(mentorId ?? 0),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        DataCell(
          Text(
            (jadwal['ruang'] ?? '-').toString(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Edit Jadwal',
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: _headerBlue,
                      size: 18,
                    ),
                    onPressed: () => _createOrUpdateJadwal(existing: jadwal),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Hapus Jadwal',
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                    onPressed: () => _showDeleteDialog(jadwal['id'] as int),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
              ],
            ),
                onPressed: () => _showDeleteDialog(_asInt(jadwal['id'])),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _headerBlue));
    }

    return RefreshIndicator(
      color: _headerBlue,
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_headerBlue, Color(0xFF1E4FB8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _headerBlue.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelola Jadwal Pembelajaran',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Jadwal utama yang berlaku setiap minggu secara berkelanjutan',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _createOrUpdateJadwal(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah Jadwal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _headerBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Jadwal Mingguan',
                      value: jadwalList.length.toString(),
                      subtitle: 'Kelas aktif per minggu',
                      color: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFFEAF2FF),
                      icon: Icons.calendar_month_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      title: 'Jadwal Hari Ini',
                      value: _countJadwalHariIni().toString(),
                      subtitle: 'Jadwal berlaku hari ini',
                      color: _accentGreen,
                      backgroundColor: const Color(0xFFEAF8EF),
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderGray),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedHari.isEmpty
                            ? null
                            : selectedHari,
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('Semua Hari'),
                          ),
                          ...hariList.map(
                            (hari) => DropdownMenuItem<String>(
                              value: hari,
                              child: Text(hari),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => selectedHari = value ?? '');
                        },
                        decoration: InputDecoration(
                          labelText: 'Filter Hari',
                          labelStyle: const TextStyle(fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _borderGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _borderGray),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: selectedMentorFilterId,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua Mentor'),
                          ),
                          ...mentorList.map(
                            (mentor) => DropdownMenuItem<int?>(
                              value: mentor['id'] as int,
                              child: Text(_mentorLabel(mentor)),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => selectedMentorFilterId = value);
                        },
                        decoration: InputDecoration(
                          labelText: 'Filter Mentor',
                          labelStyle: const TextStyle(fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _borderGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _borderGray),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Data Table Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderGray),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: _headerBlue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jadwal Utama (Berlaku Setiap Minggu)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Jadwal ini digunakan secara berkelanjutan hingga ada perubahan',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_filteredRows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada jadwal',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coba tambahkan jadwal baru atau ubah filter',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 8,
                          horizontalMargin: 6,
                          headingRowColor: MaterialStatePropertyAll(
                            _lightGray.withValues(alpha: 0.5),
                          ),
                          headingRowHeight: 50,
                          dataRowHeight: 56,
                          dividerThickness: 1,
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'HARI',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'WAKTU',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'KELAS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'MATA PELAJARAN',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'MENTOR',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'RUANG',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'AKSI',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          rows: _filteredRows
                              .asMap()
                              .entries
                              .map((entry) => _buildRow(entry.value, entry.key))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
    required IconData icon,
  }) {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _headerBlue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(23, 92, 255, 0.22),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.event_note_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kelola Jadwal Pembelajaran',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Jadwal utama yang berlaku setiap minggu secara berkelanjutan',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _createOrUpdateJadwal(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Jadwal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _headerBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Jadwal Mingguan',
                        value: jadwalList.length.toString(),
                        subtitle: 'Kelas aktif per minggu',
                        color: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFFEAF2FF),
                        icon: Icons.calendar_month_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Jadwal Hari Ini',
                        value: _countJadwalHariIni().toString(),
                        subtitle: 'Contoh: Hari Senin',
                        color: const Color(0xFF16A34A),
                        backgroundColor: const Color(0xFFEAF8EF),
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4EAF3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedHari.isEmpty
                              ? null
                              : selectedHari,
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('Semua Hari'),
                            ),
                            ...hariList.map(
                              (hari) => DropdownMenuItem<String>(
                                value: hari,
                                child: Text(hari),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => selectedHari = value ?? '');
                          },
                          decoration: InputDecoration(
                            labelText: 'Filter Hari',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: selectedMentorFilterId,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Semua Mentor'),
                            ),
                            ...mentorList.map(
                              (mentor) => DropdownMenuItem<int?>(
                                value: _asInt(mentor['id']),
                                child: Text(_mentorLabel(mentor)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => selectedMentorFilterId = value);
                          },
                          decoration: InputDecoration(
                            labelText: 'Filter Mentor',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4EAF3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          color: _headerBlue,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jadwal Utama (Berlaku Setiap Minggu)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Jadwal ini digunakan secara berkelanjutan hingga ada perubahan',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 28,
                          horizontalMargin: 18,
                          headingRowColor: MaterialStateProperty.all(
                            const Color(0xFFF4F7FB),
                          ),
                          columns: const [
                            DataColumn(label: Text('HARI')),
                            DataColumn(label: Text('WAKTU')),
                            DataColumn(label: Text('KELAS')),
                            DataColumn(label: Text('MATA PELAJARAN')),
                            DataColumn(label: Text('MENTOR')),
                            DataColumn(label: Text('RUANG')),
                            DataColumn(label: Text('SISWA')),
                            DataColumn(label: Text('AKSI')),
                          ],
                          rows: _filteredRows
                              .asMap()
                              .entries
                              .map((entry) => _buildRow(entry.value, entry.key))
                              .toList(),
                        ),
                      ),
                      if (_filteredRows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Belum ada jadwal yang sesuai filter.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}