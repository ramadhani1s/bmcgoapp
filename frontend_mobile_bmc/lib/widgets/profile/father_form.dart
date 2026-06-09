import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FatherForm extends StatelessWidget {
  const FatherForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.jobController,
    required this.phoneController,
    required this.addressController,
    required this.inputDecoration,
    required this.requiredValidator,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController jobController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final InputDecoration Function(String, IconData) inputDecoration;
  final String? Function(String?, String) requiredValidator;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data Ayah', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: Color(0xFF25273D))),
          const SizedBox(height: 14),
          TextFormField(
            controller: nameController,
            decoration: inputDecoration('Nama lengkap ayah', Icons.person_outline),
            validator: (v) => requiredValidator(v, 'Nama lengkap ayah'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: jobController,
            decoration: inputDecoration('Pekerjaan ayah', Icons.work_outline_rounded),
            validator: (v) => requiredValidator(v, 'Pekerjaan ayah'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: inputDecoration('No. WhatsApp ayah', Icons.phone_outlined),
            validator: (v) {
              final req = requiredValidator(v, 'No. WhatsApp ayah');
              if (req != null) return req;
              if (!RegExp(r'^[0-9]+$').hasMatch(v!.trim())) {
                return 'Nomor WhatsApp harus berupa angka';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: addressController,
            minLines: 2,
            maxLines: 3,
            decoration: inputDecoration('Alamat lengkap ayah', Icons.location_on_outlined),
            validator: (v) => requiredValidator(v, 'Alamat lengkap ayah'),
          ),
        ],
      ),
    );
  }
}
