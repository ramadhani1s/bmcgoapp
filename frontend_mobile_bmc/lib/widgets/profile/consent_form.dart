import 'package:flutter/material.dart';

class ConsentForm extends StatelessWidget {
  const ConsentForm({
    super.key,
    required this.parentAgreementChecked,
    required this.onAgreementChanged,
    required this.accentColor,
  });

  final bool parentAgreementChecked;
  final ValueChanged<bool?> onAgreementChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Persetujuan Orang Tua', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: Color(0xFF25273D))),
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
          value: parentAgreementChecked,
          activeColor: accentColor,
          contentPadding: EdgeInsets.zero,
          title: const Text('Saya sudah membaca dan menyetujui pernyataan di atas.'),
          onChanged: onAgreementChanged,
        ),
      ],
    );
  }
}
