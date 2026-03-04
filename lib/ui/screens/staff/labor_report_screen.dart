import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_attendance_tracker/configuration/app_colors.dart';
import 'package:smart_attendance_tracker/configuration/app_constants.dart';
import 'package:smart_attendance_tracker/configuration/app_typography.dart';
import 'package:smart_attendance_tracker/models/report_model.dart';
import 'package:smart_attendance_tracker/models/staff_model.dart';
import 'package:smart_attendance_tracker/services/api_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:smart_attendance_tracker/utils/navigation_utils.dart';
import 'package:smart_attendance_tracker/utils/responsive_utils.dart';
import 'package:smart_attendance_tracker/utils/focus_utils.dart';
import 'package:smart_attendance_tracker/utils/snackbar_utils.dart';
import 'package:smart_attendance_tracker/ui/providers/report_provider.dart';

class LaborReportScreen extends StatefulWidget {
  final StaffModel staff;
  final DateTime initialMonth;

  const LaborReportScreen({
    super.key,
    required this.staff,
    required this.initialMonth,
  });

  @override
  State<LaborReportScreen> createState() => _LaborReportScreenState();
}

class _LaborReportScreenState extends State<LaborReportScreen> {
  bool _isGeneratingPdf = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportProvider = context.read<ReportProvider>();
      reportProvider.loadReport(
        staffId: widget.staff.id ?? 0,
        month: widget.initialMonth,
      );
    });
  }

  String _getSalaryTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'hourly':
        return 'Hourly';
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return type;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  String _formatPaymentDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
        appBar: _buildAppBar(context, theme, isDark),
        body: Consumer<ReportProvider>(
          builder: (context, reportProvider, _) {
            return Column(
              children: [

                // Content
                Expanded(
                  child: reportProvider.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        )
                      : reportProvider.errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: AppColors.warningRed,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    reportProvider.errorMessage ?? 'Error loading report',
                                    style: AppTypography.bodyLarge(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      reportProvider.loadReport(
                                        staffId: widget.staff.id ?? 0,
                                        month: reportProvider.selectedMonth,
                                      );
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : reportProvider.report == null
                              ? Center(
                                  child: Text(
                                    'No report data available',
                                    style: AppTypography.bodyLarge(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveUtils.horizontalPadding(context),
                                    vertical: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Labor Report Card
                                      _buildLaborReportCard(context, theme, isDark, reportProvider),
                                      const SizedBox(height: 12),

Divider(),
                                      _buildMonthNavigation(isDark, reportProvider),
                                      Divider(),
                                      const SizedBox(height: 12),

                                      // Attendance Summary
                                      _buildAttendanceSummary(context, theme, isDark, reportProvider),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // Payment Summary
                                      _buildPaymentSummary(context, theme, isDark, reportProvider),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // Attendance Details
                                      _buildAttendanceDetails(context, theme, isDark, reportProvider),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // Generate PDF Button
                                      _buildGeneratePdfButton(context, theme, isDark),
                                    ],
                                  ),
                                ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => NavigationUtils.pop(),
      ),
      title: Text(
        '${widget.staff.name} ${widget.staff.id ?? ''} - Report',
        style: AppTypography.headlineSmall(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // TODO: Implement share functionality
          },
        ),
      ],
    );
  }

  Widget _buildMonthNavigation(bool isDark, ReportProvider reportProvider) {
    final now = DateTime.now();
    final report = reportProvider.report;
    final selectedMonth = reportProvider.selectedMonth ??
        (report != null ? DateTime(report.year, report.month) : now);
    final canGoNext = selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);

    return Container(
decoration: BoxDecoration(
  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,


),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1, reportProvider, selectedMonth),
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          Text(
            '${_getMonthName(selectedMonth.month)} ${selectedMonth.year}',
            style: AppTypography.titleMedium(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          AbsorbPointer(
            absorbing: !canGoNext,
            child: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoNext ? () => _changeMonth(1, reportProvider, selectedMonth) : null,
              color: canGoNext
                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }

  void _changeMonth(int direction, ReportProvider reportProvider, DateTime currentMonth) {
    final now = DateTime.now();
    final newMonth = DateTime(currentMonth.year, currentMonth.month + direction);
    if (newMonth.year > now.year || (newMonth.year == now.year && newMonth.month > now.month)) {
      return;
    }
    reportProvider.loadReport(
      staffId: widget.staff.id ?? 0,
      month: newMonth,
    );
  }

  Widget _buildLaborReportCard(BuildContext context, ThemeData theme, bool isDark, ReportProvider reportProvider) {
    final report = reportProvider.report!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Labor Report',
                style: AppTypography.titleLarge(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '${_getMonthName(report.month)} ${report.year}',
                style: AppTypography.bodyLarge(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Name', report.staffName, isDark),
          const SizedBox(height: 8),
          _buildInfoRow('Phone', report.phoneNumber, isDark),
          const SizedBox(height: 8),
          _buildInfoRow('Salary Type', _getSalaryTypeLabel(report.salaryType), isDark),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Salary Rate',
            '₹${report.salaryAmount.toStringAsFixed(1)} per ${_getSalaryTypeLabel(report.salaryType)}',
            isDark,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Overtime Rate',
            '₹${report.overtimeCharges.toStringAsFixed(1)} per hours',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTypography.bodyMedium(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSummary(BuildContext context, ThemeData theme, bool isDark, ReportProvider reportProvider) {
    final summary = reportProvider.report!.attendanceSummary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Summary',
          style: AppTypography.titleLarge(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                theme,
                isDark,
                icon: Icons.check_circle,
                iconColor: AppColors.successGreen,
                count: summary.present.toString(),
                label: 'Present',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                context,
                theme,
                isDark,
                icon: Icons.cancel,
                iconColor: AppColors.warningRed,
                count: summary.absent.toString(),
                label: 'Absent',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                context,
                theme,
                isDark,
                icon: Icons.access_time,
                iconColor: Colors.orange,
                count: summary.overtime.toString(),
                label: 'Overtime',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                context,
                theme,
                isDark,
                icon: Icons.event_busy,
                iconColor: Colors.purple,
                count: summary.weekOff.toString(),
                label: 'Week Off',
              ),
            ),
          ],
        ),
      ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.surfaceDark : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: AppTypography.headlineMedium(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodySmall(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context, ThemeData theme, bool isDark, ReportProvider reportProvider) {
    final payment = reportProvider.report!.paymentSummary;
    final report = reportProvider.report!;
    final isHourly = report.salaryType.toLowerCase() == 'hourly';
    
    // Calculate total worked hours from attendance details if not provided by backend
    double totalWorkedHours = payment.totalWorkedHours;
    double totalOvertimeHours = payment.totalOvertimeHours;
    
    if (totalWorkedHours == 0 && totalOvertimeHours == 0) {
      for (var detail in report.attendanceDetails) {
        if (detail.status == 'P' || detail.status == 'OT') {
          totalWorkedHours += detail.workedHours > 0 ? detail.workedHours : 8.0; // Default 8 hrs if not set
        } else if (detail.status == 'HD') {
          totalWorkedHours += detail.workedHours > 0 ? detail.workedHours : 4.0; // Default 4 hrs for half day
        }
        totalOvertimeHours += detail.overtimeHours;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Summary',
          style: AppTypography.titleLarge(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.surfaceDark : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              if (isHourly) ...[
                _buildPaymentRow(
                  'Total Worked Hours',
                  '${(totalWorkedHours + totalOvertimeHours).toStringAsFixed(1)} hrs',
                  isDark,
                  false,
                  valueColor: AppColors.primaryBlue,
                ),
                if (totalOvertimeHours > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '(Regular: ${totalWorkedHours.toStringAsFixed(1)}h + OT: ${totalOvertimeHours.toStringAsFixed(1)}h)',
                          style: AppTypography.bodySmall(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 24),
              ],
              _buildPaymentRow('Basic Earnings', '₹${payment.basicEarnings.toStringAsFixed(2)}', isDark, false),
              const Divider(height: 24),
              _buildPaymentRow('Overtime Earnings', '₹${payment.overtimeEarnings.toStringAsFixed(2)}', isDark, false),
              const Divider(height: 24),
              _buildPaymentRow('Total Earnings', '₹${payment.totalEarnings.toStringAsFixed(2)}', isDark, true),
              const Divider(height: 24),
              _buildPaymentRow('Advance Payments', '-₹${payment.advancePayments.toStringAsFixed(2)}', isDark, false, rowType: 'deduction'),
              const Divider(height: 24),
              _buildPaymentRowWithNote(
                'Net Payment (${_getMonthName(report.month)} ${report.year})',
                '₹${payment.netPayment.toStringAsFixed(2)}',
                isDark,
                true,
                note: 'Earnings this month after advance',
                rowType: 'net',
              ),
              if (payment.previousDueTotal > 0) ...[
                const Divider(height: 24),
                _buildPreviousDueSection(payment, isDark, report),
              ],

              if (payment.previousDueTotal > 0) ...[
                const Divider(height: 24),
                _buildPaymentRowWithNote(
                  'Total amount due',
                  '₹${payment.totalAmountDue.toStringAsFixed(2)}',
                  isDark,
                  true,
                  note: 'Previous due + This month net',
                  rowType: 'totalDue',
                ),
              ],


              if (payment.amountPaidThisPeriod > 0) ...[
                const Divider(height: 24),
                _buildPaymentRowWithNote(
                  payment.amountPaidAt != null
                      ? 'Amount paid this period on \n${_formatPaymentDate(payment.amountPaidAt!)}'
                      : 'Amount paid this period',
                  '₹${payment.amountPaidThisPeriod.toStringAsFixed(2)}',
                  isDark,
                  false,
                  note: 'Recorded in expenses',
                  rowType: 'amountPaid',
                ),
              ],

              if ((payment.amountPaidThisPeriod > 0 || payment.remainingDueThisPeriod < payment.netPayment) && payment.remainingDueThisPeriod != payment.remainingTotalDue && payment.remainingDueThisPeriod != 0) ...[
                const Divider(height: 24),
                _buildPaymentRowWithNote(
                  'Remaining due this period',
                  '₹${payment.remainingDueThisPeriod.toStringAsFixed(2)}',
                  isDark,
                  true,
                  note: 'Net − Paid this period',
                  rowType: 'remainingDue',
                ),
              ],


              const Divider(height: 24),
              _buildPaymentRowWithNote(
                'Remaining total due',
                '₹${payment.remainingTotalDue.toStringAsFixed(2)}',
                isDark,
                true,
                note: 'After all payments (amount to pay now)',
                rowType: 'remainingTotalDue',
              ),
              const Divider(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPayDialog(context, report, reportProvider, isDark),
                  icon: const Icon(Icons.payment, size: 20),
                  label: const Text('Pay'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviousDueSection(PaymentSummaryModel payment, bool isDark, LaborReportModel report) {
    final breakdown = payment.previousDueBreakdown;
    const note = 'From earlier months';
    if (breakdown.isEmpty) {
      return _buildPaymentRowWithNote(
        'Previous due',
        '₹${payment.previousDueTotal.toStringAsFixed(2)}',
        isDark,
        true,
        note: note,
        rowType: 'remainingDue',
      );
    }
    if (breakdown.length == 1) {
      return _buildPaymentRowWithNote(
        'Previous due',
        '₹${payment.previousDueTotal.toStringAsFixed(2)}',
        isDark,
        true,
        note: note,
        rowType: 'remainingDue',
      );
    }
    final parts = breakdown.map((e) => '${e.monthLabel} - ${e.due.toStringAsFixed(0)}').join(' + ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPaymentRow('Total previous due', '₹${payment.previousDueTotal.toStringAsFixed(2)}', isDark, true, rowType: 'remainingDue'),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Text(
            '$note ($parts)',
            style: AppTypography.bodySmall(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRowWithNote(
    String label,
    String value,
    bool isDark,
    bool isBold, {
    String? note,
    Color? valueColor,
    String? rowType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPaymentRow(label, value, isDark, isBold, valueColor: valueColor, rowType: rowType),
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Text(
              note,
              style: AppTypography.bodySmall(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showPayDialog(BuildContext context, LaborReportModel report, ReportProvider reportProvider, bool isDark) async {
    FocusUtils.unfocus();
    final amountController = TextEditingController();
    final maxDue = report.paymentSummary.remainingTotalDue;
    amountController.text = maxDue > 0 ? maxDue.toStringAsFixed(0) : report.paymentSummary.netPayment.toStringAsFixed(0);
    String selectedPaymentMethod = AppConstants.defaultPaymentMethod;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Record payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining total due: ₹${maxDue.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount paid (₹)',
                      border: OutlineInputBorder(),
                      hintText: '0',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Payment method',
                    style: AppTypography.labelMedium(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.paymentMethods.map((e) {
                      final isSelected = selectedPaymentMethod == e.key;
                      return FilterChip(
                        label: Text(e.value),
                        selected: isSelected,
                        onSelected: (_) => setState(() => selectedPaymentMethod = e.key),
                        selectedColor: AppColors.primaryBlue.withOpacity(0.3),
                        checkmarkColor: AppColors.primaryBlue,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final text = amountController.text.trim();
                  final amount = double.tryParse(text);
                  if (amount == null || amount < 0) {
                    SnackbarUtils.showError('Enter a valid amount');
                    return;
                  }
                  Navigator.of(ctx).pop({'submitted': true, 'amount': amount, 'paymentMethod': selectedPaymentMethod});
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (!context.mounted || result == null || result['submitted'] != true) return;
    final amount = (result['amount'] as num).toDouble();
    final paymentMethod = result['paymentMethod'] as String? ?? AppConstants.defaultPaymentMethod;
    try {
      await ApiService().recordLaborReportPayment(
        staffId: report.staffId,
        month: report.month,
        year: report.year,
        amount: amount,
        paymentMethod: paymentMethod,
      );
      SnackbarUtils.showSuccess('Payment recorded (will appear in expenses)');
      await reportProvider.loadReport(staffId: report.staffId, month: DateTime(report.year, report.month));
    } catch (e) {
      if (context.mounted) SnackbarUtils.showError(e.toString());
    }
  }

  /// Row type for color coding: earnings (default), deduction (advance), net (blue), amountPaid (green), remainingDue (slate), totalDue (bold), remainingTotalDue (blue bold).
  Widget _buildPaymentRow(
    String label,
    String value,
    bool isDark,
    bool isBold, {
    Color? valueColor,
    String? rowType,
  }) {
    Color effectiveColor = valueColor ??
        (rowType == 'deduction'
            ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
            : rowType == 'net'
                ? AppColors.primaryBlue
                : rowType == 'amountPaid'
                    ? AppColors.successGreen
                    : rowType == 'remainingDue'
                        ? AppColors.slateDark
                        : rowType == 'remainingTotalDue'
                            ? AppColors.primaryBlue
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium(
            color: effectiveColor,
            fontWeight: (isBold || rowType == 'remainingTotalDue' || rowType == 'net') ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceDetails(BuildContext context, ThemeData theme, bool isDark, ReportProvider reportProvider) {
    final report = reportProvider.report!;
    final details = report.attendanceDetails;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Details',
          style: AppTypography.titleLarge(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        details.isEmpty
            ? Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.surfaceDark : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'No attendance records',
                    style: AppTypography.bodyLarge(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.surfaceDark : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: details.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? AppColors.surfaceDark : Colors.grey[300]!,
                  ),
                  itemBuilder: (context, index) {
                    final detail = details[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date and Status Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${detail.date.day.toString().padLeft(2, '0')} ${_getMonthName(detail.date.month)} ${detail.date.year}',
                                      style: AppTypography.bodyMedium(
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(detail.status).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: _getStatusColor(detail.status),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            detail.displayStatus,
                                            style: AppTypography.bodySmall(
                                              color: _getStatusColor(detail.status),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (detail.hasOvertime) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${detail.overtimeHours.toStringAsFixed(1)}h OT',
                                              style: AppTypography.bodySmall(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (detail.payMultiplier != 1.0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.purple,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${detail.payMultiplier}x',
                                              style: AppTypography.bodySmall(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Builder(
                                    builder: (_) {
                                      // If there is overtime, show basic + OT amount breakdown.
                                      if (detail.overtimeHours > 0 && report.overtimeCharges > 0) {
                                        final otAmount = detail.overtimeHours * report.overtimeCharges;
                                        final basicAmount = detail.dailyEarnings - otAmount;
                                        if (basicAmount > 0) {
                                          return Text(
                                            '₹${basicAmount.toStringAsFixed(0)} + ${otAmount.toStringAsFixed(0)} (OT)',
                                            style: AppTypography.titleMedium(
                                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }
                                      }
                                      // Fallback: show total earnings only.
                                      return Text(
                                        '₹${detail.dailyEarnings.toStringAsFixed(2)}',
                                        style: AppTypography.titleMedium(
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                  if (detail.advanceAmount > 0)
                                    Text(
                                      'Advance: ₹${detail.advanceAmount.toStringAsFixed(2)}',
                                      style: AppTypography.bodySmall(
                                        color: AppColors.warningRed,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          // Time Information or Manual Hours
                          if (detail.inTime != null || detail.outTime != null || detail.overtimeHours > 0 || detail.workedHours > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Show manual worked hours if no in/out times
                                if (detail.workedHours > 0 && detail.inTime == null && detail.outTime == null) ...[
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Worked: ${detail.workedHours.toStringAsFixed(1)}h',
                                    style: AppTypography.bodySmall(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ] else ...[
                                  // Show in/out times
                                  if (detail.inTime != null) ...[
                                    Icon(
                                      Icons.login,
                                      size: 14,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'In: ${detail.inTime}',
                                      style: AppTypography.bodySmall(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                  if (detail.outTime != null) ...[
                                    if (detail.inTime != null) const SizedBox(width: 12),
                                    Icon(
                                      Icons.logout,
                                      size: 14,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Out: ${detail.outTime}',
                                      style: AppTypography.bodySmall(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'P':
      case 'OT':
        return AppColors.successGreen;
      case 'HD':
        return Colors.blue;
      case 'A':
        return AppColors.warningRed;
      case 'Off':
        return Colors.purple;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  Widget _buildGeneratePdfButton(BuildContext context, ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGeneratingPdf
            ? null
            : () async {
        if (_isGeneratingPdf) return;
        setState(() {
          _isGeneratingPdf = true;
        });
          final reportProvider = context.read<ReportProvider>();
          final report = reportProvider.report;
          if (report == null) {
            SnackbarUtils.showError('Report not loaded yet');
            if (mounted) {
              setState(() {
                _isGeneratingPdf = false;
              });
            }
            return;
          }
          try {
            final bytes = await ApiService().downloadLaborReportPdf(
              staffId: report.staffId,
              month: report.month,
              year: report.year,
            );
            final dir = await getTemporaryDirectory();
            final file = File(
              '${dir.path}/labor_report_${report.staffId}_${report.year}_${report.month}.pdf',
            );
            await file.writeAsBytes(bytes, flush: true);

            await Share.shareXFiles(
              [XFile(file.path)],
              text:
                  'Labor report for ${report.staffName} for ${_getMonthName(report.month)} ${report.year}.',
            );
          } catch (e) {
            SnackbarUtils.showError(e.toString());
          } finally {
            if (mounted) {
              setState(() {
                _isGeneratingPdf = false;
              });
            }
          }
        },
        icon: _isGeneratingPdf
            ? SizedBox(
                width: 20,
                height: 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: Text(_isGeneratingPdf ? 'Generating PDF...' : 'Generate & Share PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
