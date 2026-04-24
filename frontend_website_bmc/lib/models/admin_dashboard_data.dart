class DashboardPendingItem {
  final String studentName;
  final String schoolName;
  final String className;
  final DateTime date;
  final String status;

  DashboardPendingItem({
    required this.studentName,
    required this.schoolName,
    required this.className,
    required this.date,
    required this.status,
  });

  factory DashboardPendingItem.fromJson(Map<String, dynamic> json) {
    return DashboardPendingItem(
      studentName: json['student_name']?.toString() ?? '-',
      schoolName: json['school_name']?.toString() ?? '-',
      className: json['class_name']?.toString() ?? '-',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'Menunggu',
    );
  }
}

class AdminDashboardData {
  final int waitingVerifications;
  final int todaySchedules;
  final int activeStudents;
  final List<DashboardPendingItem> pendingItems;

  const AdminDashboardData({
    required this.waitingVerifications,
    required this.todaySchedules,
    required this.activeStudents,
    required this.pendingItems,
  });

  factory AdminDashboardData.empty() {
    return const AdminDashboardData(
      waitingVerifications: 0,
      todaySchedules: 0,
      activeStudents: 0,
      pendingItems: [],
    );
  }

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final pendingItems = (json['pending_items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DashboardPendingItem.fromJson)
        .toList();

    return AdminDashboardData(
      waitingVerifications: json['waiting_verifications'] is int
          ? json['waiting_verifications'] as int
          : int.tryParse(json['waiting_verifications']?.toString() ?? '0') ?? 0,
      todaySchedules: json['today_schedules'] is int
          ? json['today_schedules'] as int
          : int.tryParse(json['today_schedules']?.toString() ?? '0') ?? 0,
      activeStudents: json['active_students'] is int
          ? json['active_students'] as int
          : int.tryParse(json['active_students']?.toString() ?? '0') ?? 0,
      pendingItems: pendingItems,
    );
  }
}

typedef AdminDashboardSummary = AdminDashboardData;

// Legacy model classes for compatibility
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
