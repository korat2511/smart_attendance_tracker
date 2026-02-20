import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/utils/snackbar_utils.dart';

class MarkAttendanceBottomSheet extends StatefulWidget {
  final DateTime date;
  final String? currentStatus; // 'P', 'A', 'OT', 'Off', or null
  final String? currentInTime;
  final String? currentOutTime;
  final Function(String status, String? inTime, String? outTime, double? overtimeHours) onMark;

  const MarkAttendanceBottomSheet({
    super.key,
    required this.date,
    this.currentStatus,
    this.currentInTime,
    this.currentOutTime,
    required this.onMark,
  });

  @override
  State<MarkAttendanceBottomSheet> createState() => _MarkAttendanceBottomSheetState();
}

class _MarkAttendanceBottomSheetState extends State<MarkAttendanceBottomSheet> {
  String? _selectedStatus;
  String? _inTime;
  String? _outTime;
  double? _overtimeHours;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _inTime = widget.currentInTime;
    _outTime = widget.currentOutTime;
    // If already marked as OT, we might want to show existing overtime hours
    // But we don't store that in the bottom sheet, so we'll leave it null
  }

  String _getDateString() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${widget.date.day.toString().padLeft(2, '0')} ${months[widget.date.month - 1]} ${widget.date.year}';
  }

  String _getTitle() {
    final status = _selectedStatus ?? widget.currentStatus;
    if (status == 'P') {
      return 'Mark Present';
    } else if (status == 'HD') {
      return 'Mark Half Day';
    } else if (status == 'OT') {
      return 'Mark Overtime';
    } else if (status == 'A') {
      return 'Mark Absent';
    } else if (status == 'Off') {
      return 'Mark Off Day';
    }
    return 'Mark Attendance';
  }

  String _getButtonText() {
    final status = _selectedStatus ?? widget.currentStatus;
    if (status == 'P') {
      return 'Mark Present';
    } else if (status == 'HD') {
      return 'Mark Half Day';
    } else if (status == 'OT') {
      return 'Mark Overtime';
    } else if (status == 'A') {
      return 'Mark Absent';
    } else if (status == 'Off') {
      return 'Mark Off';
    }
    return 'Mark';
  }

  Future<void> _selectTime(String type) async {
    final now = DateTime.now();
    TimeOfDay? initialTime;
    
    if (type == 'in' && _inTime != null) {
      final parts = _inTime!.split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else if (type == 'out' && _outTime != null) {
      final parts = _outTime!.split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      initialTime = TimeOfDay.fromDateTime(now);
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (type == 'in') {
          _inTime = timeString;
        } else {
          _outTime = timeString;
        }
      });
    }
  }

  void _handleMark() {
    // If no status selected, use current status or default to Present
    final statusToMark = _selectedStatus ?? widget.currentStatus ?? 'P';

    // Validation for Present/Half Day/OT status
    if ((statusToMark == 'P' || statusToMark == 'HD' || statusToMark == 'OT') && _inTime == null) {
      SnackbarUtils.showError('Please select check-in time');
      return;
    }

    // Validation for OT status
    if (statusToMark == 'OT' && (_overtimeHours == null || _overtimeHours! <= 0)) {
      SnackbarUtils.showError('Please enter overtime hours');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // For Absent or Off, clear times and overtime
    final finalInTime = (statusToMark == 'P' || statusToMark == 'HD' || statusToMark == 'OT') ? _inTime : null;
    final finalOutTime = (statusToMark == 'P' || statusToMark == 'HD' || statusToMark == 'OT') ? _outTime : null;
    final finalOvertimeHours = statusToMark == 'OT' ? _overtimeHours : null;

    // Call the callback - parent will handle the API call and close the sheet
    widget.onMark(statusToMark, finalInTime, finalOutTime, finalOvertimeHours);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.horizontalPadding(context),
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: AppTypography.titleLarge(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getDateString(),
                  style: AppTypography.bodyMedium(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Status Selection - Always show all 5 buttons in one row
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.horizontalPadding(context),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatusButton(
                    'P',
                    'Present',
                    AppColors.successGreen,
                    _selectedStatus == 'P' || widget.currentStatus == 'P',
                    () => setState(() {
                      _selectedStatus = 'P';
                      // Clear overtime when switching to Present (user can add it separately)
                      _overtimeHours = null;
                      // Keep existing times if available
                      if (_inTime == null && widget.currentInTime != null) {
                        _inTime = widget.currentInTime;
                      }
                      if (_outTime == null && widget.currentOutTime != null) {
                        _outTime = widget.currentOutTime;
                      }
                    }),
                    isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatusButton(
                    'HD',
                    'Half Day',
                    Colors.blue,
                    _selectedStatus == 'HD' || widget.currentStatus == 'HD',
                    () => setState(() {
                      _selectedStatus = 'HD';
                      // Clear overtime when switching to Half Day
                      _overtimeHours = null;
                      // Keep existing times if available
                      if (_inTime == null && widget.currentInTime != null) {
                        _inTime = widget.currentInTime;
                      }
                      if (_outTime == null && widget.currentOutTime != null) {
                        _outTime = widget.currentOutTime;
                      }
                    }),
                    isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatusButton(
                    'A',
                    'Absent',
                    AppColors.warningRed,
                    _selectedStatus == 'A' || widget.currentStatus == 'A',
                    () => setState(() {
                      _selectedStatus = 'A';
                      // Clear times and overtime when marking as Absent
                      _inTime = null;
                      _outTime = null;
                      _overtimeHours = null;
                    }),
                    isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatusButton(
                    'Off',
                    'Off',
                    Colors.purple,
                    _selectedStatus == 'Off' || widget.currentStatus == 'Off',
                    () => setState(() {
                      _selectedStatus = 'Off';
                      // Clear times and overtime when marking as Off
                      _inTime = null;
                      _outTime = null;
                      _overtimeHours = null;
                    }),
                    isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatusButton(
                    'OT',
                    'Overtime',
                    Colors.orange,
                    _selectedStatus == 'OT' || widget.currentStatus == 'OT',
                    () {
                      setState(() {
                        _selectedStatus = 'OT';
                        // Pre-fill in-time if available
                        if (_inTime == null && widget.currentInTime != null) {
                          _inTime = widget.currentInTime;
                        }
                        // Pre-fill out-time if available
                        if (_outTime == null && widget.currentOutTime != null) {
                          _outTime = widget.currentOutTime;
                        }
                      });
                    },
                    isDark,
                  ),
                ),
              ],
            ),
          ),

          // Check In / Check Out (only for Present, Half Day, or OT)
          if ((_selectedStatus == 'P' || _selectedStatus == 'HD' || _selectedStatus == 'OT') ||
              (_selectedStatus == null && (widget.currentStatus == 'P' || widget.currentStatus == 'HD' || widget.currentStatus == 'OT')))
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Check In
                      Expanded(
                        child: _buildTimeField(
                          label: 'Check In',
                          icon: Icons.login,
                          iconColor: AppColors.successGreen,
                          time: _inTime,
                          onTap: () {
                            // If status not selected yet, set it to Present
                            if (_selectedStatus == null) {
                              setState(() {
                                _selectedStatus = 'P';
                              });
                            }
                            _selectTime('in');
                          },
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Check Out - can be added later by clicking
                      Expanded(
                        child: _buildTimeField(
                          label: 'Check Out',
                          icon: Icons.logout,
                          iconColor: AppColors.warningRed,
                          time: _outTime,
                          onTap: () => _selectTime('out'),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  // Overtime Hours Input (only for OT status)
                  if (_selectedStatus == 'OT')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildOvertimeInput(isDark),
                    ),
                ],
              ),
            ),

          // Buttons
          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => NavigationUtils.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: AppColors.primaryBlue,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTypography.bodyLarge(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleMark,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: () {
                        final status = _selectedStatus ?? widget.currentStatus;
                        if (status == 'A') return AppColors.warningRed;
                        if (status == 'Off') return Colors.purple;
                        if (status == 'OT') return Colors.orange;
                        if (status == 'HD') return Colors.blue;
                        return AppColors.successGreen;
                      }(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _getButtonText(),
                            style: AppTypography.bodyLarge(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    String value,
    String label,
    Color color,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(
            color: color,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.titleMedium(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTypography.bodySmall(
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String? time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          border: Border.all(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.bodySmall(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time ?? '---:--',
              style: AppTypography.titleMedium(
                color: time != null
                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOvertimeInput(bool isDark) {
    final controller = TextEditingController(
      text: _overtimeHours?.toString() ?? '',
    );

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Overtime Hours *',
        hintText: 'Enter overtime hours',
        prefixIcon: const Icon(Icons.access_time, color: Colors.orange),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        final hours = double.tryParse(value);
        setState(() {
          _overtimeHours = hours;
        });
      },
    );
  }
}
