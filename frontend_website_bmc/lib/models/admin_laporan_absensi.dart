class Absensi {
  final int id;
  final String tanggal;
  final String jam;
  final String siswa;
  final String kelas;
  final String mapel;
  final String mentor;
  final String status;
  final int siswaId;

  Absensi({
    required this.id,
    required this.tanggal,
    required this.jam,
    required this.siswa,
    required this.kelas,
    required this.mapel,
    required this.mentor,
    required this.status,
    required this.siswaId,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json['id'] ?? 0,
      tanggal: json['tanggal'] ?? '',
      jam: json['jam'] ?? '',
      siswa: json['siswa'] ?? '',
      kelas: json['kelas'] ?? '',
      mapel: json['mapel'] ?? '',
      mentor: json['mentor'] ?? '',
      status: json['status'] ?? '',
      siswaId: json['siswa_id'] ?? 0,
    );
  }
}