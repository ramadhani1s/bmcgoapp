// ignore_for_file: avoid_print, avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../models/user.dart';
import '../../models/materi_pembelajaran.dart';
import 'latihan_soal_screen.dart';
import '../dashboard/jadwal_pembelajaran_screen.dart';
import '../dashboard/mentor_attendance_screen.dart';
import '../dashboard/mentor_olimpiade_screen.dart';
import '../../services/auth_service.dart';
import '../../services/materi_service.dart';
// ignore: deprecated_member_use
import 'dart:html' as html;
import '../../widgets/mentor_sidebar_shell.dart';

class MateriPembelajaranScreen extends StatefulWidget {
  final String? initialClass;

  const MateriPembelajaranScreen({super.key, this.initialClass});

  @override
  State<MateriPembelajaranScreen> createState() =>
      _MateriPembelajaranScreenState();
}

class _MateriPembelajaranScreenState extends State<MateriPembelajaranScreen> {
  User? _currentUser;
  bool _isLoading = true;
  List<MateriPembelajaran> _materiList = [];
  String _selectedClass = 'Semua Kelas';
  final List<String> _fixedClassOptions = const [
    'Semua Kelas',
    'Kelas 10 IPA',
    'Kelas 10 IPS',
    'Kelas 11 IPA',
    'Kelas 11 IPS',
    'Kelas 12 IPA',
    'Kelas 12 IPS',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        await _fetchMateri();
        if (widget.initialClass != null && widget.initialClass!.isNotEmpty) {
          setState(() => _selectedClass = widget.initialClass!);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data pengguna');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMateri() async {
    if (_currentUser == null) return;
    try {
      final data = await MateriService.getMateri(_currentUser!.id);
      setState(() {
        _materiList = data;
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat materi: $e');
    }
  }

  void _onSidebarMenuTap(String title) {
    if (title == 'Dashboard' || title == 'Beranda') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorDashboard);
      return;
    }
    if (title == 'Jadwal Mengajar') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const JadwalPembelajaranScreen(mentorView: true),
        ),
      );
      return;
    }
    if (title == 'Absensi Kelas') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MentorAttendanceScreen()),
      );
      return;
    }
    if (title == 'Soal Latihan') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorExercise);
      return;
    }
    if (title == 'Try Out') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorTryout);
      return;
    }
    if (title == 'Materi Pembelajaran') {
      return;
    }
    if (title == 'Olimpiade Akademik') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MentorOlimpiadeScreen()),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _downloadFile(String filePath, String filename) {
    try {
      final origin = Uri.parse(MateriService.baseUrl).origin;
      final url = filePath.startsWith('http')
          ? filePath
          : (filePath.startsWith('/')
                ? '$origin$filePath'
                : '$origin/$filePath');

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..target = '_blank';

      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      _showSuccessSnackBar('Mengunduh "$filename"');
    } catch (e) {
      _showErrorSnackBar('Gagal mengunduh file');
    }
  }
    Future<void> _handleDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: const Text(
          'Hapus Materi?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda yakin ingin menghapus materi ini?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.warning, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aksi ini tidak bisa dibatalkan. File fisik dan semua data terkait materi ini akan dihapus secara permanen dari sistem.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF991B1B),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4B5563),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await MateriService.deleteMateri(id);
      if (success) {
        _showSuccessSnackBar('Materi berhasil dihapus');
        await _fetchMateri();
      } else {
        _showErrorSnackBar('Gagal menghapus materi');
      }
      setState(() => _isLoading = false);
    }
  }

  void _openUploadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadMateriDialog(
        mentorId: _currentUser!.id,
        onUploadSuccess: () {
          _fetchMateri();
          _showSuccessSnackBar('Materi berhasil diupload!');
        },
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.pptx':
      case '.ppt':
        return Icons.slideshow;
      case '.docx':
      case '.doc':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case '.pdf':
        return Colors.red;
      case '.pptx':
      case '.ppt':
        return Colors.orange;
      case '.docx':
      case '.doc':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _openKelolaSoal(MateriPembelajaran materi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LatihanSoalScreen(materi: materi),
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: PopupMenuButton<String>(
          tooltip: '',
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          onSelected: (val) {
            if (val != null) {
              setState(() {
                _selectedClass = val;
              });
            }
          },
          itemBuilder: (BuildContext context) {
            return _fixedClassOptions.map((c) {
              return PopupMenuItem<String>(
                value: c,
                height: 38,
                child: Text(
                  c,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.class_outlined,
                  size: 18,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedClass,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MentorSidebarShell(
      activeMenuTitle: 'Materi Pembelajaran',
      onMenuTap: _onSidebarMenuTap,
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        body: _isLoading && _materiList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(constraints),
                        const SizedBox(height: 24),
                        _buildToolbar(constraints),
                        const SizedBox(height: 16),
                        if (_materiList.isEmpty)
                          _buildEmptyState()
                        else
                          (_selectedClass == 'Semua Kelas'
                              ? _buildMateriGrid(constraints)
                              : _buildMateriGridFiltered(constraints)),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeader(BoxConstraints constraints) {
    final isSmallScreen = constraints.maxWidth < 600;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.accentBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBlue.withAlpha((0.15 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.menu_book, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Kelola Materi Pembelajaran',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bagikan modul, presentasi, atau dokumen pendukung untuk membantu siswa memahami pelajaran lebih baik.',
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.9 * 255).round()),
                    fontSize: 13,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kelola Materi Pembelajaran',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bagikan modul, presentasi, atau dokumen pendukung untuk membantu siswa memahami pelajaran lebih baik.',
                        style: TextStyle(
                          color: Colors.white.withAlpha((0.9 * 255).round()),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                const Icon(Icons.menu_book, color: Colors.white, size: 64),
              ],
            ),
    );
  }
    Widget _buildToolbar(BoxConstraints constraints) {
    final isSmallScreen = constraints.maxWidth < 700;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: isSmallScreen
          ? Column(
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelola Upload Materi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tambahkan file materi baru',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _openUploadDialog,
                          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                          label: const Text('Upload Materi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildClassDropdown(),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Kelola Upload Materi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tambahkan file materi baru dengan tampilan tombol yang seragam seperti halaman lain.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _openUploadDialog,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text('Upload Materi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: _buildClassDropdown(),
                ),
              ],
            ),
    );
  }
    Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Materi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Materi yang Anda upload akan tampil di sini.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMateriGrid(BoxConstraints constraints) {
    final crossAxisCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 900 ? 2 : 3);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 3.5,
      ),
      itemCount: _materiList.length,
      itemBuilder: (context, index) {
        final materi = _materiList[index];
        return _buildMateriCard(materi);
      },
    );
  }

  Widget _buildMateriGridFiltered(BoxConstraints constraints) {
    final filtered = _materiList
        .where((m) => m.classLevel == _selectedClass)
        .toList();
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Tidak ada materi untuk "$_selectedClass"',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final crossAxisCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 900 ? 2 : 3);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 3.5,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final materi = filtered[index];
        return _buildMateriCard(materi);
      },
    );
  }
    Widget _buildMateriCard(MateriPembelajaran materi) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.03 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _downloadFile(
            materi.filePath,
            '${materi.title}${materi.fileType}',
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getFileColor(
                      materi.fileType,
                    ).withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getFileIcon(materi.fileType),
                    color: _getFileColor(materi.fileType),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        materi.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (materi.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          materi.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              materi.fileType.toUpperCase().replaceAll('.', ''),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatFileSize(materi.fileSize),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.download_outlined,
                    size: 20,
                    color: Color(0xFF2563EB),
                  ),
                  onPressed: () => _downloadFile(
                    materi.filePath,
                    '${materi.title}${materi.fileType}',
                  ),
                  tooltip: 'Unduh Materi',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.assignment_outlined,
                    size: 20,
                    color: Color(0xFF10B981),
                  ),
                  onPressed: () => _openKelolaSoal(materi),
                  tooltip: 'Kelola Latihan Soal',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () => _handleDelete(materi.id),
                  tooltip: 'Hapus Materi',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class UploadMateriDialog extends StatefulWidget {
  final int mentorId;
  final VoidCallback onUploadSuccess;

  const UploadMateriDialog({
    super.key,
    required this.mentorId,
    required this.onUploadSuccess,
  });

  @override
  State<UploadMateriDialog> createState() => _UploadMateriDialogState();
}

class _UploadMateriDialogState extends State<UploadMateriDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  PlatformFile? _selectedFile;
  bool _isUploading = false;
  final List<String> _classOptions = const ['10 IPA', '10 IPS', '11 IPA', '11 IPS', '12 IPA', '12 IPS'];
  String _selectedClass = '10 IPA'; 
  final List<String> _mapelOptions = const [
    'Matematika',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Fisika',
    'Kimia',
    'Biologi',
    'Sosiologi',
    'Ekonomi',
    'Geografi',
  ];
  String _selectedMapel = 'Matematika';

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.first;
        if (file.size > 15 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran file maksimal 15MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _selectedFile = file;
          if (_titleController.text.isEmpty) {
            _titleController.text = file.name.split('.').first;
          }
        });
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih file terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    final success = await MateriService.uploadMateri(
      mentorId: widget.mentorId,
      title: _titleController.text,
      description: _descController.text,
      file: _selectedFile!,
      classLevel: _selectedClass,
      subject: _selectedMapel,
    );

    setState(() => _isUploading = false);

    if (success) {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onUploadSuccess();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengupload materi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _fieldWithLabel({
    required String label,
    required Widget child,
    bool requiredField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildFormDropdown({
    required String value,
    required List<String> options,
    required void Function(String) onChanged,
  }) {
    return Container(
      height: 44,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: PopupMenuButton<String>(
          tooltip: '',
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          onSelected: onChanged,
          itemBuilder: (BuildContext context) {
            return options.map((opt) {
              return PopupMenuItem<String>(
                value: opt,
                height: 38,
                child: Text(
                  opt,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              );
            }).toList();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
    );

    final screenHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 500,
          maxWidth: 500,
          maxHeight: screenHeight * 0.85,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Styled Header (Gradient Biru)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Materi Baru',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tambahkan file materi baru untuk dibagikan ke siswa.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // File Selector
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedFile != null
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE2E8F0),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _selectedFile != null
                                    ? Icons.check_circle
                                    : Icons.upload_file,
                                size: 40,
                                color: _selectedFile != null
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedFile != null
                                    ? _selectedFile!.name
                                    : 'Klik untuk memilih file',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedFile != null
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF64748B),
                                  fontWeight: _selectedFile != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              if (_selectedFile == null) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'Maksimal 15MB. Format: PDF, PPTX, DOCX',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _fieldWithLabel(
                        label: 'Judul Materi',
                        requiredField: true,
                        child: TextFormField(
                          controller: _titleController,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                          decoration: inputDecoration.copyWith(
                            hintText: 'Masukkan judul materi',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Judul wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _fieldWithLabel(
                        label: 'Deskripsi (Opsional)',
                        child: TextFormField(
                          controller: _descController,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                          decoration: inputDecoration.copyWith(
                            hintText: 'Masukkan deskripsi materi',
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _fieldWithLabel(
                        label: 'Kelas',
                        requiredField: true,
                        child: _buildFormDropdown(
                          value: _selectedClass,
                          options: _classOptions,
                          onChanged: (val) {
                            setState(() => _selectedClass = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      _fieldWithLabel(
                        label: 'Mata Pelajaran',
                        requiredField: true,
                        child: _buildFormDropdown(
                          value: _selectedMapel,
                          options: _mapelOptions,
                          onChanged: (val) {
                            setState(() => _selectedMapel = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isUploading ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF64748B),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFD8E1EE)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUploading ? null : _handleUpload,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isUploading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Upload Sekarang',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
      ),
    );
  }
}