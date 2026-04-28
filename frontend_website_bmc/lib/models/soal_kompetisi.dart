class SoalKompetisi {
  final int id;
  final int kompetisiId;
  final String tipe; // 'tryout' atau 'olimpiade'
  final String pertanyaan;
  final String pilihanA;
  final String pilihanB;
  final String pilihanC;
  final String pilihanD;
  final String pilihanE;
  final String jawaban;
  final String pembahasan;
  final String kategori;

  const SoalKompetisi({
    required this.id,
    required this.kompetisiId,
    required this.tipe,
    required this.pertanyaan,
    required this.pilihanA,
    required this.pilihanB,
    required this.pilihanC,
    required this.pilihanD,
    this.pilihanE = '',
    required this.jawaban,
    this.pembahasan = '',
    this.kategori = '',
  });

  factory SoalKompetisi.fromJson(Map<String, dynamic> json) {
    return SoalKompetisi(
      id: json['id'] ?? 0,
      kompetisiId: json['kompetisi_id'] ?? json['competitionId'] ?? 0,
      tipe: json['tipe'] ?? json['type'] ?? 'tryout',
      pertanyaan: json['pertanyaan'] ?? json['question'] ?? '',
      pilihanA: json['pilihan_a'] ?? json['option_a'] ?? '',
      pilihanB: json['pilihan_b'] ?? json['option_b'] ?? '',
      pilihanC: json['pilihan_c'] ?? json['option_c'] ?? '',
      pilihanD: json['pilihan_d'] ?? json['option_d'] ?? '',
      pilihanE: json['pilihan_e'] ?? json['option_e'] ?? '',
      jawaban: (json['jawaban'] ?? json['answer'] ?? '')
          .toString()
          .toUpperCase(),
      pembahasan: json['pembahasan'] ?? json['explanation'] ?? '',
      kategori: json['kategori'] ?? json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kompetisi_id': kompetisiId,
      'tipe': tipe,
      'pertanyaan': pertanyaan,
      'pilihan_a': pilihanA,
      'pilihan_b': pilihanB,
      'pilihan_c': pilihanC,
      'pilihan_d': pilihanD,
      'pilihan_e': pilihanE,
      'jawaban': jawaban,
      'pembahasan': pembahasan,
      'kategori': kategori,
    };
  }

  SoalKompetisi copyWith({
    int? id,
    int? kompetisiId,
    String? tipe,
    String? pertanyaan,
    String? pilihanA,
    String? pilihanB,
    String? pilihanC,
    String? pilihanD,
    String? pilihanE,
    String? jawaban,
    String? pembahasan,
    String? kategori,
  }) {
    return SoalKompetisi(
      id: id ?? this.id,
      kompetisiId: kompetisiId ?? this.kompetisiId,
      tipe: tipe ?? this.tipe,
      pertanyaan: pertanyaan ?? this.pertanyaan,
      pilihanA: pilihanA ?? this.pilihanA,
      pilihanB: pilihanB ?? this.pilihanB,
      pilihanC: pilihanC ?? this.pilihanC,
      pilihanD: pilihanD ?? this.pilihanD,
      pilihanE: pilihanE ?? this.pilihanE,
      jawaban: jawaban ?? this.jawaban,
      pembahasan: pembahasan ?? this.pembahasan,
      kategori: kategori ?? this.kategori,
    );
  }
}
