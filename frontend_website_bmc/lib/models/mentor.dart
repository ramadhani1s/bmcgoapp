class Mentor {
  final int mentorId;
  final int userId;
  final String email;
  final String namaMentor;
  final String mataPelajaran;
  final String password;
  final String status;

  Mentor({
    required this.mentorId,
    required this.userId,
    required this.email,
    required this.namaMentor,
    required this.mataPelajaran,
    required this.password,
    required this.status,
  });

  factory Mentor.fromJson(Map<String, dynamic> json) {
    return Mentor(
      mentorId: json['mentor_id'] ?? json['id'] ?? 0,

      userId: json['user_id'] ?? 0,

      email: json['email'] ?? '',

      namaMentor: json['nama_mentor'] ?? json['nama'] ?? '',

      mataPelajaran:
          json['mapel'] ?? json['mata_pelajaran'] ?? json['spesialisasi'] ?? '',

      password: json['password'] ?? '',

      status: json['status'] ?? 'Aktif',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mentor_id': mentorId,
      'user_id': userId,
      'email': email,
      'nama_mentor': namaMentor,
      'mata_pelajaran': mataPelajaran,
      'password': password,
      'status': status,
    };
  }
}
