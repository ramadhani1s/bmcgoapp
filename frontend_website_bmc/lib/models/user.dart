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
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return User(
      id: asInt(json['id']),
      nama: json['nama']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roleId: asInt(json['role_id'], fallback: 3),
      phoneNumber: json['phone_number']?.toString(),
      status: json['status']?.toString(),
      kelas: json['kelas']?.toString(),
      asalSekolah: json['asal_sekolah']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      alamat: json['alamat']?.toString(),
      siswaId: json['siswa_id'] == null ? null : asInt(json['siswa_id']),
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