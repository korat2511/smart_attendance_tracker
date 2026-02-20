import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'edit_staff_screen.dart';
import 'advance_payment_bottom_sheet.dart';
import 'labor_report_screen.dart';
import 'mark_attendance_bottom_sheet.dart';
import '../providers/attendance_provider.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final StaffModel staff;

  const MarkAttendanceScreen({
    super.key,
    required this.staff,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attendanceProvider = context.read<AttendanceProvider>();
      attendanceProvider.loadAttendanceData(
        staffId: widget.staff.id ?? 0,
        month: DateTime.now(),
      );
    });
  }

  String _getSalaryTypeLabel(String type) {
    switch (type) {
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

  void _changeMonth(int direction, AttendanceProvider attendanceProvider) {
    final currentMonth = attendanceProvider.selectedMonth ?? DateTime.now();
    final newMonth = DateTime(
      currentMonth.year,
      currentMonth.month + direction,
    );
    attendanceProvider.changeMonth(newMonth);
    attendanceProvider.loadAttendanceData(
      staffId: widget.staff.id ?? 0,
      month: newMonth,
    );
  }

  void _showMarkAttendanceBottomSheet(int day, AttendanceProvider attendanceProvider) {
    final selectedMonth = attendanceProvider.selectedMonth ?? DateTime.now();
    final date = DateTime(selectedMonth.year, selectedMonth.month, day);
    final attendance = attendanceProvider.attendanceMap[day];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MarkAttendanceBottomSheet(
        date: date,
        currentStatus: attendance?.status,
        currentInTime: attendance?.inTime,
        currentOutTime: attendance?.outTime,
        onMark: (status, inTime, outTime, overtimeHours) async {
          // Close bottom sheet first
          if (NavigationUtils.canPop()) {
            NavigationUtils.pop();
          }
          
          // Handle OT - mark as present first, then add overtime
          if (status == 'OT') {
            if (overtimeHours == null || overtimeHours <= 0) {
              SnackbarUtils.showError('Please enter overtime hours');
              return;
            }
            
            try {
              // First mark as present if not already present
              final attendance = attendanceProvider.attendanceMap[day];
              if (attendance == null || attendance.status != 'P') {
                await attendanceProvider.markAttendance(
                  staffId: widget.staff.id ?? 0,
                  date: date,
                  status: 'present',
                  inTime: inTime,
                  outTime: outTime,
                );
              }
              
              // Then mark overtime
              await attendanceProvider.markOvertime(
                staffId: widget.staff.id ?? 0,
                date: date,
                overtimeHours: overtimeHours,
              );
              
              if (mounted) {
                SnackbarUtils.showSuccess('Overtime marked successfully');
              }
            } catch (e) {
              if (mounted) {
                SnackbarUtils.showError(e.toString());
              }
            }
            return;
          }

          // Convert status to API format
          String apiStatus;
          if (status == 'P') {
            apiStatus = 'present';
          } else if (status == 'HD') {
            apiStatus = 'half_day';
          } else if (status == 'A') {
            apiStatus = 'absent';
          } else if (status == 'Off') {
            apiStatus = 'off';
          } else {
            return;
          }

          try {
            await attendanceProvider.markAttendance(
              staffId: widget.staff.id ?? 0,
              date: date,
              status: apiStatus,
              inTime: inTime,
              outTime: outTime,
            );
            
            if (mounted) {
              SnackbarUtils.showSuccess('Attendance marked successfully');
            }
          } catch (e) {
            if (mounted) {
              SnackbarUtils.showError(e.toString());
            }
          }
        },
      ),
    );
  }

  void _showAdvancePaymentBottomSheet(
    BuildContext context,
    int year,
    int month,
    int day,
    double currentAdvance,
    AttendanceProvider attendanceProvider,
  ) {
    final date = DateTime(year, month, day);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancePaymentBottomSheet(
        date: date,
        initialAmount: currentAdvance,
        initialNotes: null,
        onSave: (amount, notes) async {
          await attendanceProvider.markAdvance(
            staffId: widget.staff.id ?? 0,
            date: date,
            amount: amount,
            notes: notes,
          );
          if (context.mounted) {
            SnackbarUtils.showSuccess('Advance marked successfully');
          }
        },
      ),
    );
  }

  String _getDayName(int day, DateTime selectedMonth) {
    final date = DateTime(selectedMonth.year, selectedMonth.month, day);
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return weekdays[date.weekday % 7];
  }

  String _getMonthYearString(DateTime selectedMonth) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[selectedMonth.month - 1]} ${selectedMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, _) {
        return GestureDetector(
          onTap: FocusUtils.unfocus,
          behavior: HitTestBehavior.opaque,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: _buildAppBar(context, theme, isDark),
            body: Column(
              children: [
                // Summary Cards
                _buildSummaryCards(context, theme, isDark, attendanceProvider),
                
                // Month Navigation
                _buildMonthNavigation(context, theme, isDark, attendanceProvider),
                
                // Open Report Button (uses currently selected month)
                _buildOpenReportButton(context, theme, isDark, attendanceProvider),
                
                // Attendance Table
                Expanded(
                  child: attendanceProvider.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        )
                      : _buildAttendanceTable(context, theme, isDark, attendanceProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => NavigationUtils.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.staff.name,
            style: AppTypography.headlineSmall(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                widget.staff.phoneNumber,
                style: AppTypography.bodyMedium(
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              Text(
                ' - ',
                style: AppTypography.bodyMedium(
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              Text(
                '₹${widget.staff.salaryAmount.toStringAsFixed(1)}/${_getSalaryTypeLabel(widget.staff.salaryType).toLowerCase()}',
                style: AppTypography.bodyMedium(
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            NavigationUtils.push(
              EditStaffScreen(staff: widget.staff),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, ThemeData theme, bool isDark, AttendanceProvider attendanceProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.horizontalPadding(context), vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              context,
              theme,
              isDark,
              icon: Icons.check_circle,
              iconColor: AppColors.successGreen,
              count: attendanceProvider.presentCount.toString(),
              label: 'Present',
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSummaryCard(
              context,
              theme,
              isDark,
              icon: Icons.cancel,
              iconColor: AppColors.warningRed,
              count: attendanceProvider.absentCount.toString(),
              label: 'Absent',
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSummaryCard(
              context,
              theme,
              isDark,
              icon: Icons.access_time,
              iconColor: Colors.orange,
              count: attendanceProvider.overtimeCount.toString(),
              label: 'Overtime',
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
              count: '₹${attendanceProvider.advanceTotal.toStringAsFixed(1)}',
              label: 'Advance',
            ),
          ),
        ],
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
      height: 110, // Fixed height for all cards
      padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 10),
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
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodySmall(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation(BuildContext context, ThemeData theme, bool isDark, AttendanceProvider attendanceProvider) {
    final selectedMonth = attendanceProvider.selectedMonth ?? DateTime.now();
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1, attendanceProvider),
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          Text(
            _getMonthYearString(selectedMonth),
            style: AppTypography.titleMedium(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1, attendanceProvider),
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildOpenReportButton(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AttendanceProvider attendanceProvider,
  ) {
    final selectedMonth = attendanceProvider.selectedMonth ?? DateTime.now();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
        vertical: 12,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            NavigationUtils.push(
              LaborReportScreen(
                staff: widget.staff,
                initialMonth: selectedMonth,
              ),
            );
          },
          icon: const Icon(Icons.description_outlined),
          label: const Text('Open Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTable(BuildContext context, ThemeData theme, bool isDark, AttendanceProvider attendanceProvider) {
    final selectedMonth = attendanceProvider.selectedMonth ?? DateTime.now();
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Column(
        children: [
          // Table Header
          _buildTableHeader(context, theme, isDark),
          // Table Rows
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final attendance = attendanceProvider.attendanceMap[day];
                final selectedStatus = attendance?.status;
                final advanceAmount = attendanceProvider.advanceMap[day] ?? 0.0;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Date Column
                      SizedBox(
                        width: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day.toString().padLeft(2, '0'),
                              style: AppTypography.titleMedium(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _getDayName(day, selectedMonth),
                              style: AppTypography.bodySmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Attendance Column - Now shows status badge and opens bottom sheet on tap
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showMarkAttendanceBottomSheet(day, attendanceProvider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedStatus == 'P' || selectedStatus == 'OT'
                                  ? AppColors.successGreen.withValues(alpha: 0.1)
                                  : selectedStatus == 'HD'
                                      ? Colors.blue.withValues(alpha: 0.1)
                                      : selectedStatus == 'A'
                                          ? AppColors.warningRed.withValues(alpha: 0.1)
                                          : selectedStatus == 'Off'
                                              ? Colors.purple.withValues(alpha: 0.1)
                                              : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedStatus == 'P' || selectedStatus == 'OT'
                                    ? AppColors.successGreen
                                    : selectedStatus == 'HD'
                                        ? Colors.blue
                                        : selectedStatus == 'A'
                                            ? AppColors.warningRed
                                            : selectedStatus == 'Off'
                                                ? Colors.purple
                                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (selectedStatus != null) ...[
                                  Icon(
                                    selectedStatus == 'P' || selectedStatus == 'OT'
                                        ? Icons.check_circle
                                        : selectedStatus == 'HD'
                                            ? Icons.access_time
                                            : selectedStatus == 'A'
                                                ? Icons.cancel
                                                : Icons.event_busy,
                                    size: 16,
                                    color: selectedStatus == 'P' || selectedStatus == 'OT'
                                        ? AppColors.successGreen
                                        : selectedStatus == 'HD'
                                            ? Colors.blue
                                            : selectedStatus == 'A'
                                                ? AppColors.warningRed
                                                : Colors.purple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    selectedStatus,
                                    style: AppTypography.bodyMedium(
                                      color: selectedStatus == 'P' || selectedStatus == 'OT'
                                          ? AppColors.successGreen
                                          : selectedStatus == 'HD'
                                              ? Colors.blue
                                              : selectedStatus == 'A'
                                                  ? AppColors.warningRed
                                                  : Colors.purple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ] else ...[
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 16,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tap to mark',
                                    style: AppTypography.bodySmall(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                // Advance Column - tap amount to mark advance
                SizedBox(
                  width: 80,
                  child: GestureDetector(
                    onTap: () => _showAdvancePaymentBottomSheet(
                      context,
                      selectedMonth.year,
                      selectedMonth.month,
                      day,
                      advanceAmount,
                      attendanceProvider,
                    ),
                    child: Text(
                      advanceAmount > 0 ? '₹${advanceAmount.toStringAsFixed(2)}' : '₹0.00',
                      style: AppTypography.bodyMedium(
                        color: advanceAmount > 0
                            ? AppColors.primaryBlue
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        fontWeight: advanceAmount > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Date Column Header
          SizedBox(
            width: 60,
            child: Text(
              'Date',
              style: AppTypography.bodyMedium(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Attendance Column Header
          Expanded(
            child: Text(
              'Attendance',
              style: AppTypography.bodyMedium(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Advance Column Header
          SizedBox(
            width: 80,
            child: Text(
              'Advance',
              style: AppTypography.bodyMedium(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

}
