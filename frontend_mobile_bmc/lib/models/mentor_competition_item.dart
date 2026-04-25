class MentorCompetitionItem {
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
    this.categoryQuestions = const {},
  });

  final String id;
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

  factory MentorCompetitionItem.fromJson(Map<String, dynamic> json) {
    final rawMap = json['categoryQuestions'];
    final parsedMap = <String, int>{};
    if (rawMap is Map) {
      for (final entry in rawMap.entries) {
        final value = entry.value;
        final normalized = value is int ? value : int.tryParse('$value') ?? 0;
        parsedMap['${entry.key}'] = normalized;
      }
    }

    return MentorCompetitionItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'tryout',
      classLevel: json['classLevel']?.toString() ?? 'Kelas 12',
      title: json['title']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '-',
      totalQuestions: int.tryParse('${json['totalQuestions']}') ?? 0,
      durationLabel: json['durationLabel']?.toString() ?? '-',
      scheduleLabel: json['scheduleLabel']?.toString() ?? '',
      isPublished: json['isPublished'] == true,
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      categoryQuestions: parsedMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'classLevel': classLevel,
      'title': title,
      'subject': subject,
      'totalQuestions': totalQuestions,
      'durationLabel': durationLabel,
      'scheduleLabel': scheduleLabel,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'categoryQuestions': categoryQuestions,
    };
  }

  MentorCompetitionItem copyWith({
    String? id,
    String? type,
    String? classLevel,
    String? title,
    String? subject,
    int? totalQuestions,
    String? durationLabel,
    String? scheduleLabel,
    bool? isPublished,
    DateTime? createdAt,
    Map<String, int>? categoryQuestions,
  }) {
    return MentorCompetitionItem(
      id: id ?? this.id,
      type: type ?? this.type,
      classLevel: classLevel ?? this.classLevel,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      durationLabel: durationLabel ?? this.durationLabel,
      scheduleLabel: scheduleLabel ?? this.scheduleLabel,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      categoryQuestions: categoryQuestions ?? this.categoryQuestions,
    );
  }
}
