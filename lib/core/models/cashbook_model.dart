/// Cashbook monthly overview (income total, expense total, balance).
class CashbookOverviewModel {
  final int month;
  final int year;
  final double incomeTotal;
  final double expenseTotal;
  final double balance;

  CashbookOverviewModel({
    required this.month,
    required this.year,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.balance,
  });

  factory CashbookOverviewModel.fromJson(Map<String, dynamic> json) {
    return CashbookOverviewModel(
      month: _toInt(json['month'], fallback: DateTime.now().month),
      year: _toInt(json['year'], fallback: DateTime.now().year),
      incomeTotal: _toDouble(json['income_total']),
      expenseTotal: _toDouble(json['expense_total']),
      balance: _toDouble(json['balance']),
    );
  }
}

/// Single cashbook transaction (income or expense, including advances).
class CashbookTransactionModel {
  final String id;
  final String type; // 'income' | 'expense'
  final DateTime date;
  final String description;
  final double amount;

  CashbookTransactionModel({
    required this.id,
    required this.type,
    required this.date,
    required this.description,
    required this.amount,
  });

  bool get isIncome => type == 'income';

  factory CashbookTransactionModel.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String? ?? '';
    DateTime date = DateTime.now();
    if (dateStr.isNotEmpty) {
      date = DateTime.tryParse(dateStr) ?? date;
    }
    return CashbookTransactionModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'expense',
      date: date,
      description: json['description'] as String? ?? '',
      amount: _toDouble(json['amount']),
    );
  }
}

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
