import 'package:flutter/material.dart';
import '../../../core/models/cashbook_model.dart';
import '../../../core/services/api_service.dart';

class CashbookProvider extends ChangeNotifier {
  DateTime? _selectedMonth;
  CashbookOverviewModel? _overview;
  List<CashbookTransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  DateTime? get selectedMonth => _selectedMonth;
  CashbookOverviewModel? get overview => _overview;
  List<CashbookTransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    notifyListeners();
  }

  Future<void> loadData({DateTime? month}) async {
    final targetMonth = month ?? _selectedMonth ?? DateTime.now();
    _selectedMonth = targetMonth;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final overview = await ApiService().getCashbookOverview(
        month: targetMonth.month,
        year: targetMonth.year,
      );
      final transactions = await ApiService().getCashbookTransactions(
        month: targetMonth.month,
        year: targetMonth.year,
      );
      _overview = overview;
      _transactions = transactions;
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

  void changeMonth(int direction) {
    final current = _selectedMonth ?? DateTime.now();
    _selectedMonth = DateTime(current.year, current.month + direction);
    notifyListeners();
  }

  Future<void> addIncome({
    required DateTime date,
    required double amount,
    String? description,
  }) async {
    await ApiService().addCashbookIncome(
      date: date,
      amount: amount,
      description: description,
    );
    await loadData();
  }

  Future<void> addExpense({
    required DateTime date,
    required double amount,
    String? description,
  }) async {
    await ApiService().addCashbookExpense(
      date: date,
      amount: amount,
      description: description,
    );
    await loadData();
  }
}
