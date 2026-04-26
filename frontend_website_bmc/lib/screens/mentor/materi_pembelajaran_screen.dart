import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/user.dart';
import '../../models/materi_pembelajaran.dart';
import '../../services/auth_service.dart';
import '../../services/materi_service.dart';

class MateriPembelajaranScreen extends StatefulWidget {
  const MateriPembelajaranScreen({super.key});

  @override
  State<MateriPembelajaranScreen> createState() => _MateriPembelajaranScreenState();
}

class _MateriPembelajaranScreenState extends State<MateriPembelajaranScreen> {
  User? _currentUser;
  bool _isLoading = true;
  List<MateriPembelajaran> _materiList = [];

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _bgGray = Color(0xFFF3F4F6);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);

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

  Future<void> _handleDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Materi'),
        content: const Text('Apakah Anda yakin ingin menghapus materi ini? File fisik juga akan terhapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        title: const Text('Materi Pembelajaran', style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _textPrimary),
        elevation: 0.5,
      ),
      body: _isLoading && _materiList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (_materiList.isEmpty)
                    _buildEmptyState()
                  else
                    _buildMateriGrid(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUploadDialog,
        backgroundColor: _primaryBlue,
        icon: const Icon(Icons.cloud_upload, color: Colors.white),
        label: const Text('Upload Materi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha:0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          const Icon(
            Icons.menu_book,
            color: Colors.white,
            size: 64,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Materi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Materi yang Anda upload akan tampil di sini.',
            style: TextStyle(color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMateriGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 140,
      ),
      itemCount: _materiList.length,
      itemBuilder: (context, index) {
        final materi = _materiList[index];
        return _buildMateriCard(materi);
      },
    );
  }

  Widget _buildMateriCard(MateriPembelajaran materi) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
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
          onTap: () {
            // Bisa tambahkan fitur preview / download di sini
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Fitur unduh segera hadir'))
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getFileColor(materi.fileType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getFileIcon(materi.fileType),
                    color: _getFileColor(materi.fileType),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        materi.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _textPrimary,
                        ),
                      ),
                      if (materi.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          materi.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              materi.fileType.toUpperCase().replaceAll('.', ''),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatFileSize(materi.fileSize),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx'],
        withData: true, // Penting untuk flutter web
      );

      if (result != null) {
        final file = result.files.first;
        // Cek ukuran max 15MB
        if (file.size > 15 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ukuran file maksimal 15MB'), backgroundColor: Colors.red),
          );
          return;
        }
        
        setState(() {
          _selectedFile = file;
          // Auto fill title if empty
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
        const SnackBar(content: Text('Pilih file terlebih dahulu'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isUploading = true);

    final success = await MateriService.uploadMateri(
      mentorId: widget.mentorId,
      title: _titleController.text,
      description: _descController.text,
      file: _selectedFile!,
    );

    setState(() => _isUploading = false);

    if (success) {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onUploadSuccess();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengupload materi'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upload Materi Baru',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // File Selector
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedFile != null ? const Color(0xFF2563EB) : Colors.grey.shade300,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle : Icons.upload_file,
                        size: 48,
                        color: _selectedFile != null ? const Color(0xFF2563EB) : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFile != null ? _selectedFile!.name : 'Klik untuk memilih file',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedFile != null ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                          fontWeight: _selectedFile != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (_selectedFile == null) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Maksimal 15MB. Format: PDF, PPTX, DOCX',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Materi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _handleUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Upload Sekarang', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
