class Alumni {
  final int id;
  final String nama;
  final String sekolah;
  final int tahunLulus;
  final String? prestasi;
  final String? foto;

  Alumni({
    required this.id,
    required this.nama,
    required this.sekolah,
    required this.tahunLulus,
    this.prestasi,
    this.foto,
  });

  factory Alumni.fromJson(Map<String, dynamic> json) {
    return Alumni(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nama: json['nama']?.toString() ?? '',
      sekolah: json['sekolah']?.toString() ?? '',
      tahunLulus: (json['tahun_lulus'] as num?)?.toInt() ?? DateTime.now().year,
      prestasi: json['prestasi']?.toString(),
      foto: json['foto']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'sekolah': sekolah,
      'tahun_lulus': tahunLulus,
      'prestasi': prestasi,
      'foto': foto,
    };
  }
}
