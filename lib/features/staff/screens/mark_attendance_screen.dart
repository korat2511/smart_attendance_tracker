import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/models/attendance_model.dart';
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
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attendanceProvider = context.read<AttendanceProvider>();
      attendanceProvider.loadAttendanceData(
        staffId: widget.staff.id ?? 0,
        month: DateTime.now(),
      );
      // Scroll to current day after data loads
      _scrollToCurrentDay();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToCurrentDay() {
    final now = DateTime.now();
    final attendanceProvider = context.read<AttendanceProvider>();
    final selectedMonth = attendanceProvider.selectedMonth ?? now;
    
    // Only scroll if viewing current month
    if (selectedMonth.year == now.year && selectedMonth.month == now.month) {
      // Each row is approximately 60 pixels (padding 12*2 + content ~36)
      const double rowHeight = 60.0;
      final targetDay = now.day;
      
      // Calculate scroll offset (scroll to show current day in view, not at top)
      // Show a few days before current day for context
      final scrollOffset = ((targetDay - 3).clamp(0, 31)) * rowHeight;
      
      // Delay to allow ListView to build
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
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
    
    // If navigating to current month, scroll to current day
    final now = DateTime.now();
    if (newMonth.year == now.year && newMonth.month == now.month) {
      _scrollToCurrentDay();
    } else {
      // For other months, scroll to top
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
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
        currentOvertimeHours: attendance?.overtimeHours,
        currentWorkedHours: attendance?.workedHours,
        currentPayMultiplier: attendance?.payMultiplier,
        salaryType: widget.staff.salaryType,
        onMark: (status, inTime, outTime, overtimeHours, workedHours, payMultiplier) async {
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
              // Always mark as present (to save worked hours, times, and pay multiplier)
              await attendanceProvider.markAttendance(
                staffId: widget.staff.id ?? 0,
                date: date,
                status: 'present',
                inTime: inTime,
                outTime: outTime,
                workedHours: workedHours,
                payMultiplier: payMultiplier,
              );
              
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
              workedHours: workedHours,
              payMultiplier: payMultiplier,
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
      title: Text(
        widget.staff.name,
        style: AppTypography.headlineSmall(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final attendance = attendanceProvider.attendanceMap[day];
                final advanceAmount = attendanceProvider.advanceMap[day] ?? 0.0;
                
                // Check if this is today
                final now = DateTime.now();
                final isToday = selectedMonth.year == now.year && 
                               selectedMonth.month == now.month && 
                               day == now.day;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isToday 
                        ? AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1)
                        : (isDark ? AppColors.surfaceVariantDark : Colors.white),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                      left: isToday 
                          ? BorderSide(color: AppColors.primaryBlue, width: 4)
                          : BorderSide.none,
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
                                color: isToday
                                    ? AppColors.primaryBlue
                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _getDayName(day, selectedMonth),
                              style: AppTypography.bodySmall(
                                color: isToday 
                                    ? AppColors.primaryBlue.withValues(alpha: 0.8) 
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Attendance Column - Now shows status badge and opens bottom sheet on tap
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showMarkAttendanceBottomSheet(day, attendanceProvider),
                          child: _buildAttendanceStatusBadge(attendance, isDark),
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

  Widget _buildAttendanceStatusBadge(AttendanceModel? attendance, bool isDark) {
    final status = attendance?.status;
    final displayStatus = attendance?.displayStatus;
    final hasOvertime = attendance?.hasOvertime ?? false;
    final overtimeHours = attendance?.overtimeHours ?? 0.0;
    
    Color statusColor;
    IconData statusIcon;
    
    if (status == 'P' || status == 'OT' || hasOvertime) {
      statusColor = AppColors.successGreen;
      statusIcon = Icons.check_circle;
    } else if (status == 'HD') {
      statusColor = Colors.blue;
      statusIcon = Icons.access_time;
    } else if (status == 'A') {
      statusColor = AppColors.warningRed;
      statusIcon = Icons.cancel;
    } else if (status == 'Off') {
      statusColor = Colors.purple;
      statusIcon = Icons.event_busy;
    } else {
      statusColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
      statusIcon = Icons.add_circle_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: status != null ? statusColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (status != null) ...[
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 4),
            Text(
              displayStatus ?? status,
              style: AppTypography.bodyMedium(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasOvertime && overtimeHours > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${overtimeHours.toStringAsFixed(1)}h',
                  style: AppTypography.bodySmall(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ] else ...[
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 4),
            Text(
              'Tap to mark',
              style: AppTypography.bodySmall(color: statusColor),
            ),
          ],
        ],
      ),
    );
  }

}
