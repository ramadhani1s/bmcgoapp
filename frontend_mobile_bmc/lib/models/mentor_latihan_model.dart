class MentorLatihanModel {
  final String id;
  final String judul;
  final String kelas;
  final String mapel;
  final int jumlahSoal;
  final int durasiMenit;
  final String jadwalPelaksanaan;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MentorLatihanModel({
    required this.id,
    required this.judul,
    required this.kelas,
    required this.mapel,
    required this.jumlahSoal,
    required this.durasiMenit,
    required this.jadwalPelaksanaan,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MentorLatihanModel.fromJson(Map<String, dynamic> json) {
    return MentorLatihanModel(
      id: json['id']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      kelas: json['kelas']?.toString() ?? 'Kelas 12',
      mapel: json['mapel']?.toString() ?? '',
      jumlahSoal: int.tryParse(json['jumlah_soal']?.toString() ?? '0') ?? 0,
      durasiMenit: int.tryParse(json['durasi_menit']?.toString() ?? '0') ?? 0,
      jadwalPelaksanaan: json['jadwal_pelaksanaan']?.toString() ?? '',
      isPublished: json['is_published'] == true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'kelas': kelas,
      'mapel': mapel,
      'jumlah_soal': jumlahSoal,
      'durasi_menit': durasiMenit,
      'jadwal_pelaksanaan': jadwalPelaksanaan,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MentorLatihanModel copyWith({
    String? id,
    String? judul,
    String? kelas,
    String? mapel,
    int? jumlahSoal,
    int? durasiMenit,
    String? jadwalPelaksanaan,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MentorLatihanModel(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      kelas: kelas ?? this.kelas,
      mapel: mapel ?? this.mapel,
      jumlahSoal: jumlahSoal ?? this.jumlahSoal,
      durasiMenit: durasiMenit ?? this.durasiMenit,
      jadwalPelaksanaan: jadwalPelaksanaan ?? this.jadwalPelaksanaan,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
