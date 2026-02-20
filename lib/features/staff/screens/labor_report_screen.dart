import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/focus_utils.dart';
import '../providers/report_provider.dart';

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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
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
                                      
                                      const SizedBox(height: 24),
                                      
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
              _buildPaymentRow('Advance Payments', '-₹${payment.advancePayments.toStringAsFixed(2)}', isDark, false),
              const Divider(height: 24),
              _buildPaymentRow('Net Payment', '₹${payment.netPayment.toStringAsFixed(2)}', isDark, true, isNet: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value, bool isDark, bool isBold, {bool isNet = false, Color? valueColor}) {
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
            color: valueColor ?? (isNet
                ? AppColors.primaryBlue
                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceDetails(BuildContext context, ThemeData theme, bool isDark, ReportProvider reportProvider) {
    final details = reportProvider.report!.attendanceDetails;
    
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
                                  Text(
                                    '₹${detail.dailyEarnings.toStringAsFixed(2)}',
                                    style: AppTypography.titleMedium(
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                if (detail.overtimeHours > 0) ...[
                                  if (detail.inTime != null || detail.outTime != null || detail.workedHours > 0) const SizedBox(width: 12),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'OT: ${detail.overtimeHours.toStringAsFixed(2)}h',
                                    style: AppTypography.bodySmall(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
        onPressed: () {
          // TODO: Implement PDF generation and sharing
        },
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text('Generate & Share PDF'),
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
