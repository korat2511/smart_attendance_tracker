import 'package:flutter/material.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/services/api_service.dart';

class AttendanceProvider extends ChangeNotifier {
  Map<int, AttendanceModel?> _attendanceMap = {};
  Map<int, double> _advanceMap = {};
  int _presentCount = 0;
  int _absentCount = 0;
  int _overtimeCount = 0;
  double _advanceTotal = 0.0;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedMonth;

  Map<int, AttendanceModel?> get attendanceMap => _attendanceMap;
  Map<int, double> get advanceMap => _advanceMap;
  int get presentCount => _presentCount;
  int get absentCount => _absentCount;
  int get overtimeCount => _overtimeCount;
  double get advanceTotal => _advanceTotal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get selectedMonth => _selectedMonth;

  Future<void> loadAttendanceData({
    required int staffId,
    required DateTime month,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedMonth = month;
    notifyListeners();

    try {
      final result = await ApiService().getAttendance(
        staffId: staffId,
        month: month.month,
        year: month.year,
      );

      final summary = result['summary'] as AttendanceSummaryModel;
      final attendances = result['attendances'] as List<AttendanceModel>;

      _presentCount = summary.present;
      _absentCount = summary.absent;
      _overtimeCount = summary.overtime;
      _advanceTotal = summary.advanceTotal;

      // Map attendances by day
      _attendanceMap = {};
      _advanceMap = {};
      for (var attendance in attendances) {
        final day = attendance.date.day;
        _attendanceMap[day] = attendance;
        _advanceMap[day] = attendance.advanceAmount;
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAttendance({
    required int staffId,
    required DateTime date,
    required String status, // 'present', 'absent', 'off', 'half_day'
    String? inTime,
    String? outTime,
    double? workedHours,
    double? payMultiplier,
  }) async {
    final day = date.day;
    final oldAttendance = _attendanceMap[day];
    final oldPresentCount = _presentCount;
    final oldAbsentCount = _absentCount;
    
    // Convert API status to display status
    String displayStatus;
    switch (status) {
      case 'present':
        displayStatus = 'P';
        break;
      case 'half_day':
        displayStatus = 'HD';
        break;
      case 'absent':
        displayStatus = 'A';
        break;
      case 'off':
        displayStatus = 'Off';
        break;
      default:
        displayStatus = status;
    }
    
    final wasOvertime = (oldAttendance?.overtimeHours ?? 0) > 0;
    final clearOvertime = status == 'absent' || status == 'off' || status == 'half_day';
    final newOvertime = clearOvertime ? 0.0 : (oldAttendance?.overtimeHours ?? 0.0);
    if (clearOvertime && wasOvertime) {
      _overtimeCount = (_overtimeCount - 1).clamp(0, 999);
    }
    // Optimistic update
    final newAttendance = AttendanceModel(
      id: oldAttendance?.id,
      staffId: staffId,
      date: date,
      status: displayStatus,
      inTime: inTime,
      outTime: outTime,
      overtimeHours: newOvertime,
      advanceAmount: oldAttendance?.advanceAmount ?? 0.0,
      workedHours: workedHours ?? oldAttendance?.workedHours ?? 0.0,
      payMultiplier: payMultiplier ?? oldAttendance?.payMultiplier ?? 1.0,
    );
    
    _attendanceMap[day] = newAttendance;
    _updateCounts(oldAttendance?.status, displayStatus);
    notifyListeners();
    
    try {
      await ApiService().markAttendance(
        staffId: staffId,
        date: date,
        status: status,
        inTime: inTime,
        outTime: outTime,
        workedHours: workedHours,
        payMultiplier: payMultiplier,
      );
    } catch (e) {
      // Rollback on error
      _attendanceMap[day] = oldAttendance;
      _presentCount = oldPresentCount;
      _absentCount = oldAbsentCount;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  void _updateCounts(String? oldStatus, String newStatus) {
    // Decrement old status count
    if (oldStatus == 'P' || oldStatus == 'OT') {
      _presentCount = (_presentCount - 1).clamp(0, 999);
    } else if (oldStatus == 'A') {
      _absentCount = (_absentCount - 1).clamp(0, 999);
    }
    
    // Increment new status count
    if (newStatus == 'P' || newStatus == 'OT') {
      _presentCount++;
    } else if (newStatus == 'A') {
      _absentCount++;
    }
  }

  /// Clear (delete) attendance for a day. Day shows as unmarked.
  Future<void> clearAttendance({
    required int staffId,
    required DateTime date,
  }) async {
    final day = date.day;
    final oldAttendance = _attendanceMap[day];
    final oldPresentCount = _presentCount;
    final oldAbsentCount = _absentCount;
    final oldOvertimeCount = _overtimeCount;
    final oldAdvanceTotal = _advanceTotal;
    final oldAdvanceForDay = _advanceMap[day] ?? 0.0;

    final oldStatus = oldAttendance?.status;

    _attendanceMap.remove(day);
    _advanceMap.remove(day);
    if (oldStatus == 'P' || oldStatus == 'OT') {
      _presentCount = (_presentCount - 1).clamp(0, 999);
    } else if (oldStatus == 'A') {
      _absentCount = (_absentCount - 1).clamp(0, 999);
    }
    if ((oldAttendance?.overtimeHours ?? 0) > 0) {
      _overtimeCount = (_overtimeCount - 1).clamp(0, 999);
    }
    _advanceTotal = (_advanceTotal - oldAdvanceForDay).clamp(0.0, double.infinity);
    notifyListeners();

    try {
      await ApiService().clearAttendance(staffId: staffId, date: date);
    } catch (e) {
      if (oldAttendance != null) {
        _attendanceMap[day] = oldAttendance;
        _advanceMap[day] = oldAdvanceForDay;
      }
      _presentCount = oldPresentCount;
      _absentCount = oldAbsentCount;
      _overtimeCount = oldOvertimeCount;
      _advanceTotal = oldAdvanceTotal;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markOvertime({
    required int staffId,
    required DateTime date,
    required double overtimeHours,
  }) async {
    final day = date.day;
    final oldAttendance = _attendanceMap[day];
    final oldOvertimeCount = _overtimeCount;
    
    // Optimistic update - keep status as P but add overtime hours
    final newAttendance = AttendanceModel(
      id: oldAttendance?.id,
      staffId: staffId,
      date: date,
      status: 'P', // OT is shown via displayStatus when overtimeHours > 0
      inTime: oldAttendance?.inTime,
      outTime: oldAttendance?.outTime,
      overtimeHours: overtimeHours,
      advanceAmount: oldAttendance?.advanceAmount ?? 0.0,
      workedHours: oldAttendance?.workedHours ?? 0.0,
    );
    
    _attendanceMap[day] = newAttendance;
    if ((oldAttendance?.overtimeHours ?? 0) == 0 && overtimeHours > 0) {
      _overtimeCount++;
    } else if ((oldAttendance?.overtimeHours ?? 0) > 0 && overtimeHours == 0) {
      _overtimeCount = (_overtimeCount - 1).clamp(0, 999);
    }
    notifyListeners();
    
    try {
      await ApiService().markOT(
        staffId: staffId,
        date: date,
        overtimeHours: overtimeHours,
      );
    } catch (e) {
      // Rollback on error
      _attendanceMap[day] = oldAttendance;
      _overtimeCount = oldOvertimeCount;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAdvance({
    required int staffId,
    required DateTime date,
    required double amount,
    String? notes,
  }) async {
    final day = date.day;
    final oldAdvance = _advanceMap[day] ?? 0.0;
    final oldTotal = _advanceTotal;
    final oldAttendance = _attendanceMap[day];
    
    // Optimistic update
    _advanceMap[day] = amount;
    _advanceTotal = _advanceTotal - oldAdvance + amount;
    
    if (oldAttendance != null) {
      _attendanceMap[day] = oldAttendance.copyWith(advanceAmount: amount);
    }
    notifyListeners();
    
    try {
      await ApiService().markAdvance(
        staffId: staffId,
        date: date,
        amount: amount,
        notes: notes,
      );
    } catch (e) {
      // Rollback on error
      _advanceMap[day] = oldAdvance;
      _advanceTotal = oldTotal;
      _attendanceMap[day] = oldAttendance;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void changeMonth(DateTime newMonth) {
    _selectedMonth = newMonth;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
