import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/session/app_session.dart';

class ProfileDetailFormScreen extends StatefulWidget {
  const ProfileDetailFormScreen({super.key});

  @override
  State<ProfileDetailFormScreen> createState() => _ProfileDetailFormScreenState();
}

class _ProfileDetailFormScreenState extends State<ProfileDetailFormScreen> {
  static const Color _accent = Color(0xFFFF7070);
  static const Color _textPrimary = Color(0xFF25273D);
  static const Color _textMuted = Color(0xFF8D90A3);

  final _studentFormKey = GlobalKey<FormState>();
  final _fatherFormKey = GlobalKey<FormState>();
  final _motherFormKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _kelasController = TextEditingController();
  final _sekolahController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _alamatController = TextEditingController();
  final _emailController = TextEditingController();

  final _fatherNameController = TextEditingController();
  final _fatherJobController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _fatherAddressController = TextEditingController();

  final _motherNameController = TextEditingController();
  final _motherJobController = TextEditingController();
  final _motherPhoneController = TextEditingController();
  final _motherAddressController = TextEditingController();

  int _step = 0;
  bool _isSaving = false;
  bool _didLoadInitialData = false;
  bool _hasSavedProfile = false;
  bool _isEditMode = true;
  bool _parentAgreementChecked = true;
  String _signatureFileName = '';

  static const int _totalSteps = 5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialData) {
      return;
    }
    _didLoadInitialData = true;
    _loadInitialData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kelasController.dispose();
    _sekolahController.dispose();
    _whatsappController.dispose();
    _alamatController.dispose();
    _emailController.dispose();
    _fatherNameController.dispose();
    _fatherJobController.dispose();
    _fatherPhoneController.dispose();
    _fatherAddressController.dispose();
    _motherNameController.dispose();
    _motherJobController.dispose();
    _motherPhoneController.dispose();
    _motherAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final argumentMap = args is Map<String, dynamic> ? args : const <String, dynamic>{};
    final user = argumentMap['user'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    final userName = await AppSession.getUserName();
    final userEmail = await AppSession.getUserEmail();
    final userPhone = await AppSession.getUserPhone();
    final savedProfileRaw = prefs.getString('student_profile_detail');

    Map<String, dynamic> savedProfile = const <String, dynamic>{};
    if (savedProfileRaw != null && savedProfileRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedProfileRaw);
        if (decoded is Map<String, dynamic>) {
          savedProfile = decoded;
        }
      } catch (_) {
        savedProfile = const <String, dynamic>{};
      }
    }

    _namaController.text = _readString(savedProfile, 'nama').ifEmpty(
      _readString(user, 'nama').ifEmpty(userName),
    );
    _kelasController.text = _readString(savedProfile, 'kelas').ifEmpty(
      _readString(user, 'kelas'),
    );
    _sekolahController.text = _readString(savedProfile, 'asal_sekolah').ifEmpty(
      _readString(user, 'asal_sekolah'),
    );
    _whatsappController.text = _readString(savedProfile, 'whatsapp').ifEmpty(
      _readString(user, 'whatsapp').ifEmpty(userPhone),
    );
    _alamatController.text = _readString(savedProfile, 'alamat').ifEmpty(
      _readString(user, 'alamat'),
    );
    _emailController.text = _readString(savedProfile, 'email').ifEmpty(
      _readString(user, 'email').ifEmpty(userEmail),
    );

    _fatherNameController.text = _readString(savedProfile, 'father_name');
    _fatherJobController.text = _readString(savedProfile, 'father_job');
    _fatherPhoneController.text = _readString(savedProfile, 'father_phone');
    _fatherAddressController.text = _readString(savedProfile, 'father_address');

    _motherNameController.text = _readString(savedProfile, 'mother_name');
    _motherJobController.text = _readString(savedProfile, 'mother_job');
    _motherPhoneController.text = _readString(savedProfile, 'mother_phone');
    _motherAddressController.text = _readString(savedProfile, 'mother_address');

    _signatureFileName = _readString(savedProfile, 'signature_file_name');

    _hasSavedProfile = savedProfile.isNotEmpty;
    _isEditMode = !_hasSavedProfile;

    if (mounted) {
      setState(() {});
    }
  }

  String _readString(Map<String, dynamic> data, String key) {
    return data[key]?.toString().trim() ?? '';
  }

  String _stepTitle() {
    if (_hasSavedProfile && !_isEditMode) {
      return 'Data Profil Tersimpan';
    }

    if (_hasSavedProfile && _isEditMode) {
      return 'Ubah Data Profil';
    }

    switch (_step) {
      case 0:
        return 'Data Diri Siswa';
      case 1:
        return 'Data Orang Tua (Ayah)';
      case 2:
        return 'Data Orang Tua (Ibu)';
      case 3:
        return 'Tanda Tangan Orang Tua & Akun';
      default:
        return 'Konfirmasi Data';
    }
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AA0AE), fontSize: 16),
      prefixIcon: Icon(icon, color: const Color(0xFF8E93A1), size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE1E5EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE1E5EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF77979), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }

  bool _validateCurrentStep() {
    if (_step == 0) {
      return _studentFormKey.currentState?.validate() ?? false;
    }
    if (_step == 1) {
      return _fatherFormKey.currentState?.validate() ?? false;
    }
    if (_step == 2) {
      return _motherFormKey.currentState?.validate() ?? false;
    }
    if (_step == 3) {
      if (!_parentAgreementChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Persetujuan orang tua harus dicentang.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      if (_signatureFileName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih file tanda tangan orang tua/wali terlebih dahulu.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _saveProfileData() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final payload = <String, dynamic>{
      'nama': _namaController.text.trim(),
      'kelas': _kelasController.text.trim(),
      'asal_sekolah': _sekolahController.text.trim(),
      'whatsapp': _whatsappController.text.trim(),
      'alamat': _alamatController.text.trim(),
      'email': _emailController.text.trim(),
      'father_name': _fatherNameController.text.trim(),
      'father_job': _fatherJobController.text.trim(),
      'father_phone': _fatherPhoneController.text.trim(),
      'father_address': _fatherAddressController.text.trim(),
      'mother_name': _motherNameController.text.trim(),
      'mother_job': _motherJobController.text.trim(),
      'mother_phone': _motherPhoneController.text.trim(),
      'mother_address': _motherAddressController.text.trim(),
      'signature_file_name': _signatureFileName,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_profile_detail', jsonEncode(payload));
    await prefs.setString('user_name', payload['nama'] as String);
    await prefs.setString('user_email', payload['email'] as String);
    await prefs.setString('user_phone', payload['whatsapp'] as String);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _hasSavedProfile = true;
      _isEditMode = false;
      _step = 0;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Berhasil'),
          content: const Text('Data profil berhasil disimpan'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _nextStep() {
    if (!_validateCurrentStep()) {
      return;
    }

    if (_step >= _totalSteps - 1) {
      _saveProfileData();
      return;
    }

    setState(() {
      _step += 1;
    });
  }

  void _previousStep() {
    if (_hasSavedProfile && _isEditMode && _step == 0) {
      setState(() {
        _isEditMode = false;
      });
      return;
    }

    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _step -= 1;
    });
  }

  void _mockPickSignatureFile() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('tanda_tangan_ortu.png'),
                  onTap: () {
                    setState(() {
                      _signatureFileName = 'tanda_tangan_ortu.png';
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('persetujuan_ortu.pdf'),
                  onTap: () {
                    setState(() {
                      _signatureFileName = 'persetujuan_ortu.pdf';
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startEditing() {
    setState(() {
      _isEditMode = true;
      _step = 0;
    });
  }

  Future<void> _handleStartEditing() async {
    final shouldEdit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Edit Data Profil'),
          content: const Text(
            'Kamu akan masuk ke mode edit. Data yang tersimpan tetap aman sampai kamu menekan Simpan Perubahan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Lanjut Edit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if ((shouldEdit ?? false) && mounted) {
      _startEditing();
    }
  }

  void _handlePrimaryAction() {
    if (_hasSavedProfile && !_isEditMode) {
      _handleStartEditing();
      return;
    }
    _nextStep();
  }

  Widget _buildStepIndicators() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final active = index <= _step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : 8),
            height: 4,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStudentForm() {
    return Form(
      key: _studentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data Diri Siswa', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: _textPrimary)),
          const SizedBox(height: 14),
          TextFormField(
            controller: _namaController,
            decoration: _inputDecoration('Nama lengkap siswa', Icons.person_outline),
            validator: (v) => _required(v, 'Nama lengkap siswa'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _kelasController,
            decoration: _inputDecoration('Kelas', Icons.class_outlined),
            validator: (v) => _required(v, 'Kelas'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _sekolahController,
            decoration: _inputDecoration('Asal sekolah', Icons.school_outlined),
            validator: (v) => _required(v, 'Asal sekolah'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _whatsappController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('No. WhatsApp siswa', Icons.phone_outlined),
            validator: (v) => _required(v, 'No. WhatsApp siswa'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _alamatController,
            minLines: 2,
            maxLines: 3,
            decoration: _inputDecoration('Alamat lengkap', Icons.location_on_outlined),
            validator: (v) => _required(v, 'Alamat lengkap'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email siswa', Icons.email_outlined),
            validator: (v) {
              final requiredMessage = _required(v, 'Email siswa');
              if (requiredMessage != null) {
                return requiredMessage;
              }
              if (!(v?.contains('@') ?? false)) {
                return 'Format email belum valid';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFatherForm() {
    return Form(
      key: _fatherFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data Ayah', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: _textPrimary)),
          const SizedBox(height: 14),
          TextFormField(
            controller: _fatherNameController,
            decoration: _inputDecoration('Nama lengkap ayah', Icons.person_outline),
            validator: (v) => _required(v, 'Nama lengkap ayah'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fatherJobController,
            decoration: _inputDecoration('Pekerjaan ayah', Icons.work_outline_rounded),
            validator: (v) => _required(v, 'Pekerjaan ayah'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fatherPhoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('No. WhatsApp ayah', Icons.phone_outlined),
            validator: (v) => _required(v, 'No. WhatsApp ayah'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fatherAddressController,
            minLines: 2,
            maxLines: 3,
            decoration: _inputDecoration('Alamat lengkap ayah', Icons.location_on_outlined),
            validator: (v) => _required(v, 'Alamat lengkap ayah'),
          ),
        ],
      ),
    );
  }

  Widget _buildMotherForm() {
    return Form(
      key: _motherFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data Ibu', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: _textPrimary)),
          const SizedBox(height: 14),
          TextFormField(
            controller: _motherNameController,
            decoration: _inputDecoration('Nama lengkap ibu', Icons.person_outline),
            validator: (v) => _required(v, 'Nama lengkap ibu'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _motherJobController,
            decoration: _inputDecoration('Pekerjaan ibu', Icons.work_outline_rounded),
            validator: (v) => _required(v, 'Pekerjaan ibu'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _motherPhoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('No. WhatsApp ibu', Icons.phone_outlined),
            validator: (v) => _required(v, 'No. WhatsApp ibu'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _motherAddressController,
            minLines: 2,
            maxLines: 3,
            decoration: _inputDecoration('Alamat lengkap ibu', Icons.location_on_outlined),
            validator: (v) => _required(v, 'Alamat lengkap ibu'),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Persetujuan Orang Tua', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: _textPrimary)),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF4693FF)),
          ),
          child: const Text(
            'Dengan menandatangani formulir ini, saya sebagai orang tua/wali menyatakan bahwa data yang diberikan adalah benar dan saya menyetujui anak saya untuk mengikuti program bimbingan belajar di Bimbel Bintang Muda Center.',
            style: TextStyle(color: Color(0xFF2D5A8D), fontSize: 13.2, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        CheckboxListTile(
          value: _parentAgreementChecked,
          activeColor: _accent,
          contentPadding: EdgeInsets.zero,
          title: const Text('Saya sudah membaca dan menyetujui pernyataan di atas.'),
          onChanged: (checked) {
            setState(() {
              _parentAgreementChecked = checked ?? false;
            });
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Tanda Tangan Orang Tua/Wali *',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: _textPrimary),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _mockPickSignatureFile,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE1E5EE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.upload_file_outlined, color: Color(0xFF9AA0AE)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _signatureFileName.isEmpty ? 'Choose file' : _signatureFileName,
                    style: TextStyle(
                      color: _signatureFileName.isEmpty ? const Color(0xFF9AA0AE) : _textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationPage() {
    Widget infoRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 138,
              child: Text(
                '$label:',
                style: const TextStyle(color: _textMuted, fontSize: 13.5),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(color: _textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('onfirmasi Data', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: _textPrimary)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9EDF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data Siswa', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary)),
              const SizedBox(height: 8),
              infoRow('Nama', _namaController.text.trim()),
              infoRow('Kelas', _kelasController.text.trim()),
              infoRow('Asal sekolah', _sekolahController.text.trim()),
              infoRow('WhatsApp', _whatsappController.text.trim()),
              infoRow('Alamat', _alamatController.text.trim()),
              infoRow('Email', _emailController.text.trim()),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9EDF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data Orang Tua', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary)),
              const SizedBox(height: 8),
              infoRow('Ayah', _fatherNameController.text.trim()),
              infoRow('Pekerjaan ayah', _fatherJobController.text.trim()),
              infoRow('WhatsApp ayah', _fatherPhoneController.text.trim()),
              infoRow('Ibu', _motherNameController.text.trim()),
              infoRow('Pekerjaan ibu', _motherJobController.text.trim()),
              infoRow('WhatsApp ibu', _motherPhoneController.text.trim()),
              infoRow('File tanda tangan', _signatureFileName),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pastikan semua data sudah benar sebelum menekan tombol Simpan.',
          style: TextStyle(color: _textMuted, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _buildReadOnlyProfileView() {
    Widget infoRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 138,
              child: Text(
                '$label:',
                style: const TextStyle(color: _textMuted, fontSize: 13.5),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Profil Siswa',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: _textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9EDF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data Siswa', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary)),
              const SizedBox(height: 8),
              infoRow('Nama', _namaController.text.trim()),
              infoRow('Kelas', _kelasController.text.trim()),
              infoRow('Asal sekolah', _sekolahController.text.trim()),
              infoRow('WhatsApp', _whatsappController.text.trim()),
              infoRow('Alamat', _alamatController.text.trim()),
              infoRow('Email', _emailController.text.trim()),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9EDF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data Orang Tua', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary)),
              const SizedBox(height: 8),
              infoRow('Nama ayah', _fatherNameController.text.trim()),
              infoRow('Pekerjaan ayah', _fatherJobController.text.trim()),
              infoRow('WhatsApp ayah', _fatherPhoneController.text.trim()),
              infoRow('Alamat ayah', _fatherAddressController.text.trim()),
              const SizedBox(height: 2),
              infoRow('Nama ibu', _motherNameController.text.trim()),
              infoRow('Pekerjaan ibu', _motherJobController.text.trim()),
              infoRow('WhatsApp ibu', _motherPhoneController.text.trim()),
              infoRow('Alamat ibu', _motherAddressController.text.trim()),
              infoRow('File tanda tangan', _signatureFileName),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Data sudah tersimpan. Tekan tombol Edit Data kalau ingin mengubah isi profil.',
          style: TextStyle(color: _textMuted, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_hasSavedProfile && !_isEditMode) {
      return _buildReadOnlyProfileView();
    }

    switch (_step) {
      case 0:
        return _buildStudentForm();
      case 1:
        return _buildFatherForm();
      case 2:
        return _buildMotherForm();
      case 3:
        return _buildConsentForm();
      default:
        return _buildConfirmationPage();
    }
  }

  String _primaryButtonLabel() {
    if (_hasSavedProfile && !_isEditMode) {
      return 'Edit Data';
    }

    if (_step == _totalSteps - 1) {
      if (_isSaving) {
        return 'Menyimpan...';
      }
      return _hasSavedProfile ? 'Simpan Perubahan' : 'Simpan';
    }
    return 'Lanjut';
  }

  Widget _buildSavedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Colors.white, size: 15),
          SizedBox(width: 6),
          Text(
            'Data tersimpan',
            style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: const BoxDecoration(color: _accent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _previousStep,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _hasSavedProfile && !_isEditMode
                        ? 'Data Profil Siswa'
                        : 'Registrasi Siswa Baru',
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700, height: 1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stepTitle(),
                    style: const TextStyle(color: Color(0xFFFFE6E6), fontSize: 13.5),
                  ),
                  if (_hasSavedProfile && !_isEditMode) ...[
                    const SizedBox(height: 10),
                    _buildSavedBadge(),
                  ],
                  if (!(_hasSavedProfile && !_isEditMode)) ...[
                    const SizedBox(height: 12),
                    _buildStepIndicators(),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: _buildContent(),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    if (!(_hasSavedProfile && !_isEditMode) && _step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _previousStep,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            side: const BorderSide(color: Color(0xFFCBD3E0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Kembali'),
                        ),
                      ),
                    if (!(_hasSavedProfile && !_isEditMode) && _step > 0)
                      const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : _handlePrimaryAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _primaryButtonLabel(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
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
}

extension _StringFallback on String {
  String ifEmpty(String fallback) {
    return trim().isEmpty ? fallback : this;
  }
}
