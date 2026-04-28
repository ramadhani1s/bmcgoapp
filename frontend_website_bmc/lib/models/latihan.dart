class Latihan {
  final int id;
  final int mentorId;
  final String title;
  final String mapel;
  final String status; // 'Draft' or 'Dipublikasikan'
  final int totalSoal;
  final DateTime createdAt;
  final List<int> questionIds; // List of soal_latihan IDs in this latihan

  const Latihan({
    required this.id,
    required this.mentorId,
    required this.title,
    required this.mapel,
    required this.status,
    required this.totalSoal,
    required this.createdAt,
    required this.questionIds,
  });

  factory Latihan.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['created_at'] is String) {
      try {
        parsedDate = DateTime.parse(json['created_at']);
      } catch (_) {}
    }

    List<int> qIds = [];
    if (json['question_ids'] is List) {
      qIds = (json['question_ids'] as List).cast<int>();
    }

    return Latihan(
      id: json['id'] ?? 0,
      mentorId: json['mentor_id'] ?? 0,
      title: json['title'] ?? json['judul'] ?? '',
      mapel: json['mapel'] ?? json['mata_pelajaran'] ?? '',
      status: json['status'] ?? 'Draft',
      totalSoal: json['total_soal'] ?? qIds.length,
      createdAt: parsedDate ?? DateTime.now(),
      questionIds: qIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mentor_id': mentorId,
      'title': title,
      'mapel': mapel,
      'status': status,
      'total_soal': totalSoal,
      'created_at': createdAt.toIso8601String(),
      'question_ids': questionIds,
    };
  }

  Latihan copyWith({
    int? id,
    int? mentorId,
    String? title,
    String? mapel,
    String? status,
    int? totalSoal,
    DateTime? createdAt,
    List<int>? questionIds,
  }) {
    return Latihan(
      id: id ?? this.id,
      mentorId: mentorId ?? this.mentorId,
      title: title ?? this.title,
      mapel: mapel ?? this.mapel,
      status: status ?? this.status,
      totalSoal: totalSoal ?? this.totalSoal,
      createdAt: createdAt ?? this.createdAt,
      questionIds: questionIds ?? this.questionIds,
    );
  }

  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  bool get isPublished => status == 'Dipublikasikan';
}
