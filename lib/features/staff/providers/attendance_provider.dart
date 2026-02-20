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
    required String status, // 'present', 'absent', 'off'
    String? inTime,
    String? outTime,
  }) async {
    try {
      await ApiService().markAttendance(
        staffId: staffId,
        date: date,
        status: status,
        inTime: inTime,
        outTime: outTime,
      );

      // Reload data to get updated counts
      if (_selectedMonth != null) {
        await loadAttendanceData(
          staffId: staffId,
          month: _selectedMonth!,
        );
      }
    } catch (e) {
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
    try {
      await ApiService().markOT(
        staffId: staffId,
        date: date,
        overtimeHours: overtimeHours,
      );

      // Reload data to get updated counts
      if (_selectedMonth != null) {
        await loadAttendanceData(
          staffId: staffId,
          month: _selectedMonth!,
        );
      }
    } catch (e) {
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
    try {
      await ApiService().markAdvance(
        staffId: staffId,
        date: date,
        amount: amount,
        notes: notes,
      );

      if (_selectedMonth != null) {
        await loadAttendanceData(
          staffId: staffId,
          month: _selectedMonth!,
        );
      }
    } catch (e) {
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
