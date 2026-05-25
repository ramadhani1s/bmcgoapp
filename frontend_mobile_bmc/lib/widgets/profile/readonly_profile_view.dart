import 'package:flutter/material.dart';

class ReadOnlyProfileView extends StatelessWidget {
  const ReadOnlyProfileView({
    super.key,
    required this.nama,
    required this.kelas,
    required this.sekolah,
    required this.whatsapp,
    required this.alamat,
    required this.email,
    required this.fatherName,
    required this.fatherJob,
    required this.fatherPhone,
    required this.fatherAddress,
    required this.motherName,
    required this.motherJob,
    required this.motherPhone,
    required this.motherAddress,
    required this.signatureFileName,
  });

  final String nama;
  final String kelas;
  final String sekolah;
  final String whatsapp;
  final String alamat;
  final String email;
  final String fatherName;
  final String fatherJob;
  final String fatherPhone;
  final String fatherAddress;
  final String motherName;
  final String motherJob;
  final String motherPhone;
  final String motherAddress;
  final String signatureFileName;

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(color: Color(0xFF8D90A3), fontSize: 13.5),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  color: Color(0xFF25273D),
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
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: Color(0xFF25273D)),
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
              const Text('Data Siswa', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF25273D))),
              const SizedBox(height: 8),
              infoRow('Nama', nama),
              infoRow('Kelas', kelas),
              infoRow('Asal sekolah', sekolah),
              infoRow('WhatsApp', whatsapp),
              infoRow('Alamat', alamat),
              infoRow('Email', email),
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
              const Text('Data Orang Tua', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF25273D))),
              const SizedBox(height: 8),
              infoRow('Nama ayah', fatherName),
              infoRow('Pekerjaan ayah', fatherJob),
              infoRow('WhatsApp ayah', fatherPhone),
              infoRow('Alamat ayah', fatherAddress),
              const SizedBox(height: 2),
              infoRow('Nama ibu', motherName),
              infoRow('Pekerjaan ibu', motherJob),
              infoRow('WhatsApp ibu', motherPhone),
              infoRow('Alamat ibu', motherAddress),
              infoRow('File tanda tangan', signatureFileName),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Data sudah tersimpan. Tekan tombol Edit Data kalau ingin mengubah isi profil.',
          style: TextStyle(color: Color(0xFF8D90A3), fontSize: 12.5),
        ),
      ],
    );
  }
}
