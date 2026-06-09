import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StudentForm extends StatelessWidget {
  const StudentForm({
    super.key,
    required this.formKey,
    required this.namaController,
    required this.kelasController,
    required this.sekolahController,
    required this.whatsappController,
    required this.alamatController,
    required this.emailController,
    required this.inputDecoration,
    required this.requiredValidator,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController namaController;
  final TextEditingController kelasController;
  final TextEditingController sekolahController;
  final TextEditingController whatsappController;
  final TextEditingController alamatController;
  final TextEditingController emailController;
  final InputDecoration Function(String, IconData) inputDecoration;
  final String? Function(String?, String) requiredValidator;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data Diri Siswa', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: Color(0xFF25273D))),
          const SizedBox(height: 14),
          TextFormField(
            controller: namaController,
            decoration: inputDecoration('Nama lengkap siswa', Icons.person_outline),
            validator: (v) => requiredValidator(v, 'Nama lengkap siswa'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: kelasController,
            decoration: inputDecoration('Kelas', Icons.class_outlined),
            validator: (v) => requiredValidator(v, 'Kelas'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: sekolahController,
            decoration: inputDecoration('Asal sekolah', Icons.school_outlined),
            validator: (v) => requiredValidator(v, 'Asal sekolah'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: whatsappController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: inputDecoration('No. WhatsApp siswa', Icons.phone_outlined),
            validator: (v) {
              final req = requiredValidator(v, 'No. WhatsApp siswa');
              if (req != null) return req;
              if (!RegExp(r'^[0-9]+$').hasMatch(v!.trim())) {
                return 'Nomor WhatsApp harus berupa angka';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: alamatController,
            minLines: 2,
            maxLines: 3,
            decoration: inputDecoration('Alamat lengkap', Icons.location_on_outlined),
            validator: (v) => requiredValidator(v, 'Alamat lengkap'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: inputDecoration('Email siswa', Icons.email_outlined),
            validator: (v) {
              final requiredMessage = requiredValidator(v, 'Email siswa');
              if (requiredMessage != null) return requiredMessage;
              if (!(v?.contains('@') ?? false)) return 'Format email belum valid';
              return null;
            },
          ),
        ],
      ),
    );
  }
}
