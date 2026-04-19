class User {
  final int id;
  final String nama;
  final String email;
  final int roleId;
  final String? phoneNumber;
  final String? status;
  final String? kelas;
  final String? asalSekolah;
  final String? whatsapp;
  final String? alamat;
  final int? siswaId;

  User({
    required this.id,
    required this.nama,
    required this.email,
    required this.roleId,
    this.phoneNumber,
    this.status,
    this.kelas,
    this.asalSekolah,
    this.whatsapp,
    this.alamat,
    this.siswaId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      roleId: json['role_id'] ?? 3,
      phoneNumber: json['phone_number'],
      status: json['status'],
      kelas: json['kelas'],
      asalSekolah: json['asal_sekolah'],
      whatsapp: json['whatsapp'],
      alamat: json['alamat'],
      siswaId: json['siswa_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'role_id': roleId,
      'phone_number': phoneNumber,
      'status': status,
      'kelas': kelas,
      'asal_sekolah': asalSekolah,
      'whatsapp': whatsapp,
      'alamat': alamat,
      'siswa_id': siswaId,
    };
  }

  // Helper methods untuk role checking
  bool get isAdmin => roleId == 1;
  bool get isMentor => roleId == 2;
  bool get isSiswa => roleId == 3;

  String get roleName {
    switch (roleId) {
      case 1:
        return 'Admin';
      case 2:
        return 'Mentor';
      case 3:
        return 'Siswa';
      default:
        return 'Unknown';
    }
  }
}