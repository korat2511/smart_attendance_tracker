import 'package:flutter/foundation.dart';
import '../../../core/models/report_model.dart';
import '../../../core/services/api_service.dart';

class ReportProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  LaborReportModel? _report;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedMonth;

  LaborReportModel? get report => _report;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get selectedMonth => _selectedMonth;

  Future<void> loadReport({
    required int staffId,
    DateTime? month,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final targetMonth = month ?? DateTime.now();
      _selectedMonth = targetMonth;

      _report = await _apiService.getLaborReport(
        staffId: staffId,
        month: targetMonth.month,
        year: targetMonth.year,
      );

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
      _report = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void changeMonth(DateTime month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
