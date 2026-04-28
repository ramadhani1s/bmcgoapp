class SoalLatihan {
  final int id;
  final int mentorId;
  final String pertanyaan;
  final String pilihanA;
  final String pilihanB;
  final String pilihanC;
  final String pilihanD;
  final String jawaban;
  final String pembahasan;

  const SoalLatihan({
    required this.id,
    required this.mentorId,
    required this.pertanyaan,
    required this.pilihanA,
    required this.pilihanB,
    required this.pilihanC,
    required this.pilihanD,
    required this.jawaban,
    this.pembahasan = '',
  });

  factory SoalLatihan.fromJson(Map<String, dynamic> json) {
    return SoalLatihan(
      id: json['id'] ?? 0,
      mentorId: json['mentor_id'] ?? 0,
      pertanyaan: json['pertanyaan'] ?? '',
      pilihanA: json['pilihan_a'] ?? '',
      pilihanB: json['pilihan_b'] ?? '',
      pilihanC: json['pilihan_c'] ?? '',
      pilihanD: json['pilihan_d'] ?? '',
      jawaban: (json['jawaban'] ?? '').toString().toUpperCase(),
      pembahasan: json['pembahasan'] ?? json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mentor_id': mentorId,
      'pertanyaan': pertanyaan,
      'pilihan_a': pilihanA,
      'pilihan_b': pilihanB,
      'pilihan_c': pilihanC,
      'pilihan_d': pilihanD,
      'jawaban': jawaban,
      'pembahasan': pembahasan,
    };
  }

  SoalLatihan copyWith({
    int? id,
    int? mentorId,
    String? pertanyaan,
    String? pilihanA,
    String? pilihanB,
    String? pilihanC,
    String? pilihanD,
    String? jawaban,
    String? pembahasan,
  }) {
    return SoalLatihan(
      id: id ?? this.id,
      mentorId: mentorId ?? this.mentorId,
      pertanyaan: pertanyaan ?? this.pertanyaan,
      pilihanA: pilihanA ?? this.pilihanA,
      pilihanB: pilihanB ?? this.pilihanB,
      pilihanC: pilihanC ?? this.pilihanC,
      pilihanD: pilihanD ?? this.pilihanD,
      jawaban: jawaban ?? this.jawaban,
      pembahasan: pembahasan ?? this.pembahasan,
    );
  }
}
