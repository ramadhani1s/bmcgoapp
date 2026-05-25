class MateriPembelajaran {
  final int id;
  final int mentorId;
  final String classLevel;
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
    required this.classLevel,
    required this.title,
    required this.description,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MateriPembelajaran.fromJson(Map<String, dynamic> json) {
    final kelas =
        (json['kelas'] ??
                json['class_level'] ??
                json['class'] ??
                json['paket'] ??
                json['paket_nama'] ??
                json['class_name'])
            ?.toString() ??
        '';
    return MateriPembelajaran(
      id: json['id'] ?? 0,
      mentorId: json['mentor_id'] ?? 0,
      classLevel: kelas,
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
