import 'package:flutter/material.dart';

class MotherForm extends StatelessWidget {
  const MotherForm({
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
          const Text('Data Ibu', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: Color(0xFF25273D))),
          const SizedBox(height: 14),
          TextFormField(
            controller: nameController,
            decoration: inputDecoration('Nama lengkap ibu', Icons.person_outline),
            validator: (v) => requiredValidator(v, 'Nama lengkap ibu'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: jobController,
            decoration: inputDecoration('Pekerjaan ibu', Icons.work_outline_rounded),
            validator: (v) => requiredValidator(v, 'Pekerjaan ibu'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: inputDecoration('No. WhatsApp ibu', Icons.phone_outlined),
            validator: (v) => requiredValidator(v, 'No. WhatsApp ibu'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: addressController,
            minLines: 2,
            maxLines: 3,
            decoration: inputDecoration('Alamat lengkap ibu', Icons.location_on_outlined),
            validator: (v) => requiredValidator(v, 'Alamat lengkap ibu'),
          ),
        ],
      ),
    );
  }
}
