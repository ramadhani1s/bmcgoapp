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

  // ── Tag Helpers for Latihan Grouping ──────────────────────────────────────

  static const String skeletonTag = '[SKELETON]';

  bool get isSkeleton => pertanyaan.contains(skeletonTag);

  static String _parseTag(String raw, String tagPrefix) {
    final regExp = RegExp('\\[' + tagPrefix + ':(.+?)\\]');
    final match = regExp.firstMatch(raw);
    if (match != null) {
      return match.group(1)?.trim() ?? '';
    }
    return '';
  }

  String get kelas {
    final regExp = RegExp(r'\[(Kelas \d+(?:\s+[a-zA-Z]+)?)\]');
    final match = regExp.firstMatch(pertanyaan);
    return match != null ? match.group(1) ?? 'Kelas 10 IPA' : 'Kelas 10 IPA';
  }

  String get mapel {
    final val = _parseTag(pertanyaan, 'Mapel');
    if (val.isNotEmpty) return val;
    final regExp = RegExp(
      r'\[(Matematika|Fisika|Kimia|Biologi|Bahasa Indonesia|Bahasa Inggris|Ekonomi|Geografi|Sosiologi|Sejarah)\]',
    );
    final match = regExp.firstMatch(pertanyaan);
    return match != null ? match.group(1) ?? 'Matematika' : 'Matematika';
  }

  String get latihanTitle {
    final val = _parseTag(pertanyaan, 'Latihan');
    if (val.isNotEmpty) return val;
    return 'Latihan $mapel';
  }

  int get durasi {
    final val = _parseTag(pertanyaan, 'Durasi');
    return int.tryParse(val) ?? 30;
  }

  int get targetSoal {
    final val = _parseTag(pertanyaan, 'Target');
    return int.tryParse(val) ?? 5;
  }

  String get cleanPertanyaan {
    return pertanyaan.replaceAll(RegExp(r'\[.+?\]'), '').trim();
  }

  static String buildPertanyaan({
    required String text,
    required String kelas,
    required String mapel,
    required String latihanTitle,
    required int durasi,
    required int target,
    bool isSkeletonFlag = false,
  }) {
    final skeletonStr = isSkeletonFlag ? skeletonTag : '';
    return '[$kelas][Mapel:$mapel][Latihan:$latihanTitle][Durasi:$durasi][Target:$target]$skeletonStr $text';
  }
}
