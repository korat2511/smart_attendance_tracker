import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/models/cashbook_model.dart';
import '../providers/cashbook_provider.dart';
import 'add_income_bottom_sheet.dart';
import 'add_expense_bottom_sheet.dart';

class CashbookScreen extends StatefulWidget {
  const CashbookScreen({super.key});

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CashbookProvider>();
      provider.loadData(month: DateTime.now());
    });
  }

  String _getMonthYearString(DateTime month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  void _changeMonth(int direction, CashbookProvider provider) {
    final current = provider.selectedMonth ?? DateTime.now();
    final newMonth = DateTime(current.year, current.month + direction);
    provider.changeMonth(direction);
    provider.loadData(month: newMonth);
  }

  void _showAddIncome(CashbookProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddIncomeBottomSheet(
        initialDate: provider.selectedMonth ?? DateTime.now(),
        onSave: (date, amount, description) async {
          await provider.addIncome(
            date: date,
            amount: amount,
            description: description,
          );
        },
      ),
    );
  }

  void _showAddExpense(CashbookProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseBottomSheet(
        initialDate: provider.selectedMonth ?? DateTime.now(),
        onSave: (date, amount, description) async {
          await provider.addExpense(
            date: date,
            amount: amount,
            description: description,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: FocusUtils.unfocus,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Consumer<CashbookProvider>(
          builder: (context, provider, _) {
            final selectedMonth = provider.selectedMonth ?? DateTime.now();
            final overview = provider.overview;

            return Column(
              children: [
                // Monthly Overview cards (same design as mark_attendance_screen)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.horizontalPadding(context),
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          theme,
                          isDark,
                          icon: Icons.trending_up,
                          iconColor: AppColors.successGreen,
                          count: overview != null
                              ? '₹${overview.incomeTotal.toStringAsFixed(0)}'
                              : '₹0',
                          label: 'Income',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          theme,
                          isDark,
                          icon: Icons.trending_down,
                          iconColor: AppColors.warningRed,
                          count: overview != null
                              ? '₹${overview.expenseTotal.toStringAsFixed(0)}'
                              : '₹0',
                          label: 'Expense',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          theme,
                          isDark,
                          icon: Icons.account_balance_wallet,
                          iconColor: AppColors.primaryBlue,
                          count: overview != null
                              ? '₹${overview.balance.toStringAsFixed(0)}'
                              : '₹0',
                          label: 'Balance',
                        ),
                      ),
                    ],
                  ),
                ),
                // Month swiper (same design as mark_attendance_screen)
                Container(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1, provider),
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      Text(
                        _getMonthYearString(selectedMonth),
                        style: AppTypography.titleMedium(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1, provider),
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ],
                  ),
                ),
                // Transaction list
                Expanded(
                  child: provider.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        )
                      : _buildTransactionList(context, theme, isDark, provider),
                ),
                // + Income / - Expense buttons
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.horizontalPadding(context),
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showAddIncome(provider),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Income'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showAddExpense(provider),
                          icon: const Icon(Icons.remove, size: 20),
                          label: const Text('Expense'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.warningRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
  }) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: AppColors.borderDark, width: 1) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: AppTypography.titleLarge(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodySmall(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    CashbookProvider provider,
  ) {
    final transactions = provider.transactions;

    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Column(
        children: [
          // Table header (light blue like image)
          Container(
            color: AppColors.primaryBlue.withValues(alpha: 0.15),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.horizontalPadding(context),
              vertical: 12,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    'Date',
                    style: AppTypography.labelLarge(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Description',
                    style: AppTypography.labelLarge(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Amount',
                    style: AppTypography.labelLarge(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text(
                      'No transactions this month',
                      style: AppTypography.bodyMedium(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                      left: ResponsiveUtils.horizontalPadding(context),
                      right: ResponsiveUtils.horizontalPadding(context),
                      bottom: 8,
                    ),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      return _buildTransactionRow(context, isDark, t);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    bool isDark,
    CashbookTransactionModel t,
  ) {
    final day = t.date.day;
    final monthShort = _monthShort(t.date.month);
    final amountColor =
        t.isIncome ? AppColors.successGreen : AppColors.warningRed;
    final amountPrefix = t.isIncome ? '+₹' : '-₹';
    final typeLabel = t.isIncome ? 'Income' : 'Expense';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$day',
                  style: AppTypography.bodyMedium(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  monthShort,
                  style: AppTypography.bodySmall(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description,
                  style: AppTypography.bodyMedium(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  typeLabel,
                  style: AppTypography.bodySmall(color: amountColor),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '$amountPrefix${t.amount.toStringAsFixed(2)}',
              style: AppTypography.bodyMedium(
                color: amountColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _monthShort(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
