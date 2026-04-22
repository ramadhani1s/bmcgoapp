class Mentor {
  final int mentorId;
  final int userId;
  final String email;
  final String namaMentor;
  final String spesialisasi;
  final String bio;
  final String status;

  Mentor({
    required this.mentorId,
    required this.userId,
    required this.email,
    required this.namaMentor,
    required this.spesialisasi,
    required this.bio,
    required this.status,
  });

  factory Mentor.fromJson(Map<String, dynamic> json) {
    return Mentor(
      mentorId: json['mentor_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      email: json['email'] ?? '',
      namaMentor: json['nama_mentor'] ?? '',
      spesialisasi: json['spesialisasi'] ?? '',
      bio: json['bio'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
