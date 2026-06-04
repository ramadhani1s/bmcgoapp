class AlumniModel {
  final int id;
  final String nama;
  final String sekolah;
  final int tahunLulus;
  final String prestasi;
  final String foto;

  AlumniModel({
    required this.id,
    required this.nama,
    required this.sekolah,
    required this.tahunLulus,
    required this.prestasi,
    required this.foto,
  });

  factory AlumniModel.fromJson(Map<String, dynamic> json) {
    return AlumniModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nama: json['nama']?.toString() ?? '',
      sekolah: json['sekolah']?.toString() ?? '',
      tahunLulus: (json['tahun_lulus'] as num?)?.toInt() ?? 2024,
      prestasi: json['prestasi']?.toString() ?? '',
      foto: json['foto']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'sekolah': sekolah,
      'tahun_lulus': tahunLulus,
      'prestasi': prestasi,
      'foto': foto,
    };
  }
}
