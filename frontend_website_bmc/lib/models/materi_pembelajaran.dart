

class MateriPembelajaran {
  final int id;
  final int mentorId;
  final String title;
  final String description;
  final String filePath;
  final String fileType;
  final int fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  MateriPembelajaran({
    required this.id,
    required this.mentorId,
    required this.title,
    required this.description,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MateriPembelajaran.fromJson(Map<String, dynamic> json) {
    return MateriPembelajaran(
      id: json['id'] ?? 0,
      mentorId: json['mentor_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSize: json['file_size'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}
