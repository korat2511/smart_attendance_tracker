import 'package:flutter/material.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/services/api_service.dart';

class StaffProvider extends ChangeNotifier {
  List<StaffModel> _staffList = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<StaffModel> get staffList => _staffList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _staffList.isEmpty && !_isLoading && _errorMessage == null;
  bool get hasError => _errorMessage != null;

  Future<void> loadStaffList() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final staff = await ApiService().getStaffList();
      _staffList = staff;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshStaffList() async {
    await loadStaffList();
  }

  void addStaff(StaffModel staff) {
    _staffList.insert(0, staff);
    notifyListeners();
  }

  Future<void> updateStaff(StaffModel updatedStaff) async {
    try {
      final staff = await ApiService().updateStaff(
        id: updatedStaff.id!,
        name: updatedStaff.name,
        phoneNumber: updatedStaff.phoneNumber,
        salaryType: updatedStaff.salaryType,
        salaryAmount: updatedStaff.salaryAmount,
        overtimeCharges: updatedStaff.overtimeCharges,
      );

      final index = _staffList.indexWhere((s) => s.id == staff.id);
      if (index != -1) {
        _staffList[index] = staff;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteStaff(int staffId) async {
    try {
      await ApiService().deleteStaff(staffId);
      _staffList.removeWhere((s) => s.id == staffId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
