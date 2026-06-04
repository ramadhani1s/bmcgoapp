class SoalLatihan {
  final int id;
  final String pertanyaan;
  final String pilihanA;
  final String pilihanB;
  final String pilihanC;
  final String pilihanD;
  final String jawaban;
  final String pembahasan;

  SoalLatihan({
    required this.id,
    required this.pertanyaan,
    required this.pilihanA,
    required this.pilihanB,
    required this.pilihanC,
    required this.pilihanD,
    required this.jawaban,
    required this.pembahasan,
  });

  factory SoalLatihan.fromJson(Map<String, dynamic> json) {
    return SoalLatihan(
      id: json['id'] ?? 0,
      pertanyaan: json['pertanyaan'] ?? '',
      pilihanA: json['pilihanA'] ?? '',
      pilihanB: json['pilihanB'] ?? '',
      pilihanC: json['pilihanC'] ?? '',
      pilihanD: json['pilihanD'] ?? '',
      jawaban: json['jawaban'] ?? '',
      pembahasan: json['pembahasan'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pertanyaan': pertanyaan,
      'pilihanA': pilihanA,
      'pilihanB': pilihanB,
      'pilihanC': pilihanC,
      'pilihanD': pilihanD,
      'jawaban': jawaban,
      'pembahasan': pembahasan,
    };
  }
}

class SoalSiswa {
  final int id;
  final String pertanyaan;
  final String pilihanA;
  final String pilihanB;
  final String pilihanC;
  final String pilihanD;
  final String jawaban;
  final String pembahasan;

  SoalSiswa({
    required this.id,
    required this.pertanyaan,
    required this.pilihanA,
    required this.pilihanB,
    required this.pilihanC,
    required this.pilihanD,
    required this.jawaban,
    required this.pembahasan,
  });

  factory SoalSiswa.fromSoalLatihan(SoalLatihan soal) {
    return SoalSiswa(
      id: soal.id,
      pertanyaan: soal.pertanyaan,
      pilihanA: soal.pilihanA,
      pilihanB: soal.pilihanB,
      pilihanC: soal.pilihanC,
      pilihanD: soal.pilihanD,
      jawaban: soal.jawaban,
      pembahasan: soal.pembahasan,
    );
  }
}

class SoalModel {
  final String id;
  final String latihanId;
  final String pertanyaan;
  final Map<String, String> pilihan;
  final String kunciJawaban;
  final String pembahasan;
  final DateTime createdAt;
  final String subject;

  SoalModel({
    required this.id,
    required this.latihanId,
    required this.pertanyaan,
    required this.pilihan,
    required this.kunciJawaban,
    required this.pembahasan,
    required this.createdAt,
    required this.subject,
  });

  factory SoalModel.fromJson(Map<String, dynamic> json) {
    return SoalModel(
      id: json['id']?.toString() ?? '',
      latihanId: json['latihanId']?.toString() ?? '',
      pertanyaan: json['pertanyaan'] ?? '',
      pilihan: Map<String, String>.from(json['pilihan'] ?? {}),
      kunciJawaban: json['kunciJawaban'] ?? 'A',
      pembahasan: json['pembahasan'] ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      subject: json['subject'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latihanId': latihanId,
      'pertanyaan': pertanyaan,
      'pilihan': pilihan,
      'kunciJawaban': kunciJawaban,
      'pembahasan': pembahasan,
      'createdAt': createdAt.toIso8601String(),
      'subject': subject,
    };
  }

  SoalModel copyWith({
    String? id,
    String? latihanId,
    String? pertanyaan,
    Map<String, String>? pilihan,
    String? kunciJawaban,
    String? pembahasan,
    DateTime? createdAt,
    String? subject,
  }) {
    return SoalModel(
      id: id ?? this.id,
      latihanId: latihanId ?? this.latihanId,
      pertanyaan: pertanyaan ?? this.pertanyaan,
      pilihan: pilihan ?? this.pilihan,
      kunciJawaban: kunciJawaban ?? this.kunciJawaban,
      pembahasan: pembahasan ?? this.pembahasan,
      createdAt: createdAt ?? this.createdAt,
      subject: subject ?? this.subject,
    );
  }
}