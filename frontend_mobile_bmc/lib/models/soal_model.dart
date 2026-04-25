class SoalModel {
  final String id;
  final String latihanId;
  final String pertanyaan;
  final Map<String, String> pilihan; // {A: "...", B: "...", C: "...", D: "..."}
  final String kunciJawaban; // A, B, C, atau D
  final String pembahasan;
  final DateTime createdAt;

  SoalModel({
    required this.id,
    required this.latihanId,
    required this.pertanyaan,
    required this.pilihan,
    required this.kunciJawaban,
    required this.pembahasan,
    required this.createdAt,
  });

  factory SoalModel.fromJson(Map<String, dynamic> json) {
    return SoalModel(
      id: json['id'] ?? '',
      latihanId: json['latihanId'] ?? '',
      pertanyaan: json['pertanyaan'] ?? '',
      pilihan: Map<String, String>.from(json['pilihan'] ?? {}),
      kunciJawaban: json['kunciJawaban'] ?? 'A',
      pembahasan: json['pembahasan'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
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
  }) {
    return SoalModel(
      id: id ?? this.id,
      latihanId: latihanId ?? this.latihanId,
      pertanyaan: pertanyaan ?? this.pertanyaan,
      pilihan: pilihan ?? this.pilihan,
      kunciJawaban: kunciJawaban ?? this.kunciJawaban,
      pembahasan: pembahasan ?? this.pembahasan,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
