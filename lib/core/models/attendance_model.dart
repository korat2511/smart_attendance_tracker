class AttendanceModel {
  final int? id;
  final int staffId;
  final DateTime date;
  final String status; // 'P', 'HD', 'A', 'OT', 'Off'
  final String? inTime;
  final String? outTime;
  final double overtimeHours;
  final double advanceAmount;

  AttendanceModel({
    this.id,
    required this.staffId,
    required this.date,
    required this.status,
    this.inTime,
    this.outTime,
    this.overtimeHours = 0.0,
    this.advanceAmount = 0.0,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as int?,
      staffId: (json['staff_id'] as int?) ?? 0, // Handle null case
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String? ?? '',
      inTime: json['in_time'] as String?,
      outTime: json['out_time'] as String?,
      overtimeHours: (json['overtime_hours'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (json['advance_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'staff_id': staffId,
      'date': date.toIso8601String().split('T')[0],
      'status': status,
      if (inTime != null) 'in_time': inTime,
      if (outTime != null) 'out_time': outTime,
      'overtime_hours': overtimeHours,
      'advance_amount': advanceAmount,
    };
  }
}

class AttendanceSummaryModel {
  final int present;
  final int absent;
  final int overtime;
  final double advanceTotal;

  AttendanceSummaryModel({
    required this.present,
    required this.absent,
    required this.overtime,
    required this.advanceTotal,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      present: (json['present'] as int?) ?? 0,
      absent: (json['absent'] as int?) ?? 0,
      overtime: (json['overtime'] as int?) ?? 0,
      advanceTotal: (json['advance_total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
