class MentorCompetitionItem {
  final int id;
  final String type;
  final String classLevel;
  final String title;
  final String subject;
  final int totalQuestions;
  final String durationLabel;
  final String scheduleLabel;
  final bool isPublished;
  final DateTime createdAt;
  final Map<String, int> categoryQuestions;

  const MentorCompetitionItem({
    required this.id,
    required this.type,
    required this.classLevel,
    required this.title,
    required this.subject,
    required this.totalQuestions,
    required this.durationLabel,
    required this.scheduleLabel,
    required this.isPublished,
    required this.createdAt,
    required this.categoryQuestions,
  });

  factory MentorCompetitionItem.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categoryQuestions'];
    final categories = <String, int>{};
    if (rawCategories is Map) {
      for (final entry in rawCategories.entries) {
        categories['${entry.key}'] = int.tryParse('${entry.value}') ?? 0;
      }
    }

    return MentorCompetitionItem(
      id: int.tryParse('${json['id']}') ?? 0,
      type: json['type']?.toString() ?? 'tryout',
      classLevel:
          json['classLevel']?.toString() ??
          json['class_level']?.toString() ??
          'Kelas 12',
      title: json['title']?.toString() ?? json['nama']?.toString() ?? '',
      subject: json['subject']?.toString() ?? json['lokasi']?.toString() ?? '-',
      totalQuestions:
          int.tryParse(
            '${json['totalQuestions'] ?? json['total_questions'] ?? 0}',
          ) ??
          0,
      durationLabel:
          json['durationLabel']?.toString() ??
          json['durasi']?.toString() ??
          '-',
      scheduleLabel:
          json['scheduleLabel']?.toString() ??
          json['tanggal']?.toString() ??
          '',
      isPublished: json['isPublished'] == true || json['is_published'] == true,
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? json['created_at']}') ??
          DateTime.now(),
      categoryQuestions: categories,
    );
  }
}
