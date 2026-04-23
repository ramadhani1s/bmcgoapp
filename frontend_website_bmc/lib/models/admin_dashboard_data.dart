class AdminDashboardData {
  final AdminDashboardStats stats;
  final List<AdminPendingVerificationRow> pendingVerifications;
  final List<AdminScheduleRow> todaySchedules;
  final String scheduleDateLabel;

  const AdminDashboardData({
    required this.stats,
    required this.pendingVerifications,
    required this.todaySchedules,
    required this.scheduleDateLabel,
  });

  factory AdminDashboardData.empty() {
    return const AdminDashboardData(
      stats: AdminDashboardStats(
        pendingVerifications: 0,
        schedulesToday: 0,
        activeStudents: 0,
      ),
      pendingVerifications: [],
      todaySchedules: [],
      scheduleDateLabel: '-',
    );
  }

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>? ?? const {};
    final pendingJson =
        (json['pending_verifications'] as List<dynamic>? ?? const []);
    final scheduleJson = (json['today_schedules'] as List<dynamic>? ?? const []);

    return AdminDashboardData(
      stats: AdminDashboardStats.fromJson(statsJson),
      pendingVerifications: pendingJson
          .whereType<Map<String, dynamic>>()
          .map(AdminPendingVerificationRow.fromJson)
          .toList(),
      todaySchedules: scheduleJson
          .whereType<Map<String, dynamic>>()
          .map(AdminScheduleRow.fromJson)
          .toList(),
      scheduleDateLabel: json['schedule_date_label']?.toString() ?? '-',
    );
  }
}

class AdminDashboardStats {
  final int pendingVerifications;
  final int schedulesToday;
  final int activeStudents;

  const AdminDashboardStats({
    required this.pendingVerifications,
    required this.schedulesToday,
    required this.activeStudents,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      pendingVerifications: _toInt(json['pending_verifications']),
      schedulesToday: _toInt(json['schedules_today']),
      activeStudents: _toInt(json['active_students']),
    );
  }
}

class AdminPendingVerificationRow {
  final String transactionId;
  final String name;
  final String school;
  final String className;
  final String date;
  final String status;

  const AdminPendingVerificationRow({
    required this.transactionId,
    required this.name,
    required this.school,
    required this.className,
    required this.date,
    required this.status,
  });

  factory AdminPendingVerificationRow.fromJson(Map<String, dynamic> json) {
    return AdminPendingVerificationRow(
      transactionId: json['transaction_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '-',
      school: json['school']?.toString() ?? '-',
      className: json['class_name']?.toString() ?? '-',
      date: json['date']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'Menunggu',
    );
  }
}

class AdminScheduleRow {
  final String time;
  final String className;
  final String subject;
  final String mentor;
  final String room;
  final String status;

  const AdminScheduleRow({
    required this.time,
    required this.className,
    required this.subject,
    required this.mentor,
    required this.room,
    required this.status,
  });

  factory AdminScheduleRow.fromJson(Map<String, dynamic> json) {
    return AdminScheduleRow(
      time: json['time']?.toString() ?? '-',
      className: json['class_name']?.toString() ?? '-',
      subject: json['subject']?.toString() ?? '-',
      mentor: json['mentor']?.toString() ?? '-',
      room: json['room']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'Akan Datang',
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '0') ?? 0;
}
