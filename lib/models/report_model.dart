int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  if (value is num) return value.toInt();
  return fallback;
}

double _toDouble(dynamic value, {double fallback = 0.0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

class LaborReportModel {
  final int staffId;
  final String staffName;
  final String phoneNumber;
  final String salaryType;
  final double salaryAmount;
  final double overtimeCharges;
  final int month;
  final int year;
  final AttendanceReportSummary attendanceSummary;
  final PaymentSummaryModel paymentSummary;
  final List<AttendanceReportDetail> attendanceDetails;

  LaborReportModel({
    required this.staffId,
    required this.staffName,
    required this.phoneNumber,
    required this.salaryType,
    required this.salaryAmount,
    required this.overtimeCharges,
    required this.month,
    required this.year,
    required this.attendanceSummary,
    required this.paymentSummary,
    required this.attendanceDetails,
  });

  factory LaborReportModel.fromJson(Map<String, dynamic> json) {
    return LaborReportModel(
      staffId: _toInt(json['staff_id']),
      staffName: json['staff_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      salaryType: json['salary_type'] as String? ?? '',
      salaryAmount: _toDouble(json['salary_amount']),
      overtimeCharges: _toDouble(json['overtime_charges']),
      month: _toInt(json['month'], fallback: DateTime.now().month),
      year: _toInt(json['year'], fallback: DateTime.now().year),
      attendanceSummary: AttendanceReportSummary.fromJson(json['attendance_summary'] as Map<String, dynamic>? ?? {}),
      paymentSummary: PaymentSummaryModel.fromJson(json['payment_summary'] as Map<String, dynamic>? ?? {}),
      attendanceDetails: (json['attendance_details'] as List<dynamic>?)
              ?.map((item) => AttendanceReportDetail.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AttendanceReportSummary {
  final int present;
  final int absent;
  final int overtime;
  final int weekOff;
  final int halfDay;

  AttendanceReportSummary({
    required this.present,
    required this.absent,
    required this.overtime,
    required this.weekOff,
    required this.halfDay,
  });

  factory AttendanceReportSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceReportSummary(
      present: _toInt(json['present']),
      absent: _toInt(json['absent']),
      overtime: _toInt(json['overtime']),
      weekOff: _toInt(json['week_off']),
      halfDay: _toInt(json['half_day']),
    );
  }
}

class PaymentSummaryModel {
  final double basicEarnings;
  final double overtimeEarnings;
  final double totalEarnings;
  final double advancePayments;
  final double netPayment;
  final double totalWorkedHours;
  final double totalOvertimeHours;

  PaymentSummaryModel({
    required this.basicEarnings,
    required this.overtimeEarnings,
    required this.totalEarnings,
    required this.advancePayments,
    required this.netPayment,
    this.totalWorkedHours = 0.0,
    this.totalOvertimeHours = 0.0,
  });

  factory PaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return PaymentSummaryModel(
      basicEarnings: _toDouble(json['basic_earnings']),
      overtimeEarnings: _toDouble(json['overtime_earnings']),
      totalEarnings: _toDouble(json['total_earnings']),
      advancePayments: _toDouble(json['advance_payments']),
      netPayment: _toDouble(json['net_payment']),
      totalWorkedHours: _toDouble(json['total_worked_hours']),
      totalOvertimeHours: _toDouble(json['total_overtime_hours']),
    );
  }
}

class AttendanceReportDetail {
  final int id;
  final DateTime date;
  final String status; // 'P', 'HD', 'A', 'OT', 'Off'
  final String? inTime;
  final String? outTime;
  final double overtimeHours;
  final double advanceAmount;
  final double dailyEarnings;
  final double workedHours;
  final double payMultiplier;

  AttendanceReportDetail({
    required this.id,
    required this.date,
    required this.status,
    this.inTime,
    this.outTime,
    this.overtimeHours = 0.0,
    this.advanceAmount = 0.0,
    this.dailyEarnings = 0.0,
    this.workedHours = 0.0,
    this.payMultiplier = 1.0,
  });

  bool get hasOvertime => overtimeHours > 0;
  
  String get displayStatus {
    if (status == 'P' && hasOvertime) return 'P+OT';
    if (status == 'OT') return 'P+OT';
    return status;
  }

  double get totalWorkedHours => workedHours + overtimeHours;

  factory AttendanceReportDetail.fromJson(Map<String, dynamic> json) {
    return AttendanceReportDetail(
      id: _toInt(json['id']),
      date: DateTime.parse(json['date'] as String? ?? DateTime.now().toIso8601String().split('T')[0]),
      status: json['status'] as String? ?? '',
      inTime: json['in_time'] as String?,
      outTime: json['out_time'] as String?,
      overtimeHours: _toDouble(json['overtime_hours']),
      advanceAmount: _toDouble(json['advance_amount']),
      dailyEarnings: _toDouble(json['daily_earnings']),
      workedHours: _toDouble(json['worked_hours']),
      payMultiplier: _toDouble(json['pay_multiplier'], fallback: 1.0),
    );
  }
}
