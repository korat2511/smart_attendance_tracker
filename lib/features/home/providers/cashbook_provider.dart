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

  /// Delete income. Transaction id must be of form "income_123".
  Future<void> deleteIncome(String transactionId) async {
    if (!transactionId.startsWith('income_')) return;
    final id = int.tryParse(transactionId.replaceFirst('income_', ''));
    if (id == null) return;
    await ApiService().deleteCashbookIncome(id);
    await loadData();
  }

  Future<void> updateIncome({
    required String transactionId,
    required DateTime date,
    required double amount,
    String? description,
  }) async {
    if (!transactionId.startsWith('income_')) return;
    final id = int.tryParse(transactionId.replaceFirst('income_', ''));
    if (id == null) return;
    await ApiService().updateCashbookIncome(
      id: id,
      date: date,
      amount: amount,
      description: description,
    );
    await loadData();
  }

  Future<void> updateExpense({
    required String transactionId,
    required DateTime date,
    required double amount,
    String? description,
  }) async {
    if (!transactionId.startsWith('expense_')) return;
    final id = int.tryParse(transactionId.replaceFirst('expense_', ''));
    if (id == null) return;
    await ApiService().updateCashbookExpense(
      id: id,
      date: date,
      amount: amount,
      description: description,
    );
    await loadData();
  }

  /// Delete a manual cashbook expense. Transaction id must be of form "expense_123".
  Future<void> deleteExpense(String transactionId) async {
    if (!transactionId.startsWith('expense_')) return;
    final id = int.tryParse(transactionId.replaceFirst('expense_', ''));
    if (id == null) return;
    await ApiService().deleteCashbookExpense(id);
    await loadData();
  }

  /// Clear advance for an attendance. Transaction id must be of form "advance_123".
  Future<void> deleteAdvance(String transactionId) async {
    if (!transactionId.startsWith('advance_')) return;
    final id = int.tryParse(transactionId.replaceFirst('advance_', ''));
    if (id == null) return;
    await ApiService().clearAdvance(id);
    await loadData();
  }

  /// Update advance amount. Transaction id must be of form "advance_123".
  Future<void> updateAdvance(String transactionId, double amount) async {
    if (!transactionId.startsWith('advance_')) return;
    final id = int.tryParse(transactionId.replaceFirst('advance_', ''));
    if (id == null) return;
    await ApiService().updateAdvance(id, amount);
    await loadData();
  }
}
