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
  final double? currentOvertimeHours;
  final double? currentWorkedHours;
  final double? currentPayMultiplier;
  final String salaryType; // 'hourly', 'daily', 'weekly', 'monthly'
  final Function(String status, String? inTime, String? outTime, double? overtimeHours, double? workedHours, double? payMultiplier) onMark;
  /// Called when user taps Remove. [otOnly] true = remove only OT, false = remove full attendance.
  final void Function(bool otOnly)? onRemove;

  const MarkAttendanceBottomSheet({
    super.key,
    required this.date,
    this.currentStatus,
    this.currentInTime,
    this.currentOutTime,
    this.currentOvertimeHours,
    this.currentWorkedHours,
    this.currentPayMultiplier,
    required this.salaryType,
    required this.onMark,
    this.onRemove,
  });
  
  bool get isHourly => salaryType.toLowerCase() == 'hourly';

  @override
  State<MarkAttendanceBottomSheet> createState() => _MarkAttendanceBottomSheetState();
}

class _MarkAttendanceBottomSheetState extends State<MarkAttendanceBottomSheet> {
  String? _selectedStatus;
  String? _inTime;
  String? _outTime;
  bool _isLoading = false;
  bool _useManualHours = false;
  /// When user taps the chip that matches current attendance, we show Remove instead of Mark.
  bool _removeRequested = false;
  /// 'all' = remove full day, 'ot_only' = remove only overtime.
  String? _removeIntent;
  
  late TextEditingController _workedHoursController;
  late TextEditingController _overtimeHoursController;
  late TextEditingController _payMultiplierController;

  bool get _currentHasOvertime => (widget.currentOvertimeHours ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _inTime = widget.currentInTime;
    _outTime = widget.currentOutTime;
    
    // Initialize controllers with existing values
    _workedHoursController = TextEditingController(
      text: widget.currentWorkedHours != null && widget.currentWorkedHours! > 0 
          ? widget.currentWorkedHours.toString() 
          : '',
    );
    _overtimeHoursController = TextEditingController(
      text: widget.currentOvertimeHours != null && widget.currentOvertimeHours! > 0 
          ? widget.currentOvertimeHours.toString() 
          : '',
    );
    _payMultiplierController = TextEditingController(
      text: widget.currentPayMultiplier != null && widget.currentPayMultiplier != 1.0 
          ? widget.currentPayMultiplier.toString() 
          : '',
    );
    
    // If worked hours is set, default to manual hours mode
    if (widget.currentWorkedHours != null && widget.currentWorkedHours! > 0) {
      _useManualHours = true;
    }
  }
  
  @override
  void dispose() {
    _workedHoursController.dispose();
    _overtimeHoursController.dispose();
    _payMultiplierController.dispose();
    super.dispose();
  }

  bool _isPresentSelected() {
    final status = _removeRequested ? _selectedStatus : (_selectedStatus ?? widget.currentStatus);
    return status == 'P' || status == 'OT';
  }

  bool _isOvertimeSelected() {
    final status = _removeRequested ? _selectedStatus : (_selectedStatus ?? widget.currentStatus);
    return status == 'OT';
  }

  bool _isHdSelected() {
    final status = _removeRequested ? _selectedStatus : (_selectedStatus ?? widget.currentStatus);
    return status == 'HD';
  }

  bool _isAbsentSelected() {
    final status = _removeRequested ? _selectedStatus : (_selectedStatus ?? widget.currentStatus);
    return status == 'A';
  }

  bool _isOffSelected() {
    final status = _removeRequested ? _selectedStatus : (_selectedStatus ?? widget.currentStatus);
    return status == 'Off';
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
      return 'Mark Present + Overtime';
    } else if (status == 'A') {
      return 'Mark Absent';
    } else if (status == 'Off') {
      return 'Mark Off Day';
    }
    return 'Mark Attendance';
  }

  String _getButtonText() {
    if (_removeRequested && _removeIntent != null) {
      return _removeIntent == 'ot_only' ? 'Remove OT' : 'Remove';
    }
    final status = _selectedStatus ?? widget.currentStatus;
    if (status == 'P') {
      return 'Mark Present';
    } else if (status == 'HD') {
      return 'Mark Half Day';
    } else if (status == 'OT') {
      return 'Mark P + OT';
    } else if (status == 'A') {
      return 'Mark Absent';
    } else if (status == 'Off') {
      return 'Mark Off';
    }
    return 'Mark';
  }

  void _handleRemove() {
    if (widget.onRemove == null) return;
    widget.onRemove!(_removeIntent == 'ot_only');
  }

  void _onStatusChipTapped(String value) {
    final current = widget.currentStatus;
    setState(() {
      if (value == 'P' && (current == 'P' || current == 'OT')) {
        _removeRequested = true;
        _removeIntent = 'all';
        _selectedStatus = null;
      } else if (value == 'HD' && current == 'HD') {
        _removeRequested = true;
        _removeIntent = 'all';
        _selectedStatus = null;
      } else if (value == 'A' && current == 'A') {
        _removeRequested = true;
        _removeIntent = 'all';
        _selectedStatus = null;
      } else if (value == 'Off' && current == 'Off') {
        _removeRequested = true;
        _removeIntent = 'all';
        _selectedStatus = null;
      } else if (value == 'OT' && (current == 'OT' || (current == 'P' && _currentHasOvertime))) {
        _removeRequested = true;
        _removeIntent = 'ot_only';
        _selectedStatus = null;
      } else {
        _removeRequested = false;
        _removeIntent = null;
        _selectedStatus = value;
        if (value == 'P' || value == 'OT') {
          if (_inTime == null && widget.currentInTime != null) _inTime = widget.currentInTime;
          if (_outTime == null && widget.currentOutTime != null) _outTime = widget.currentOutTime;
        }
        if (value == 'OT') {
          // keep times
        } else {
          _overtimeHoursController.clear();
        }
        if (value == 'A' || value == 'Off') {
          _inTime = null;
          _outTime = null;
          _workedHoursController.clear();
        }
      }
    });
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
    final statusToMark = _selectedStatus ?? widget.currentStatus ?? 'P';
    
    // Read values from controllers
    final workedHours = double.tryParse(_workedHoursController.text);
    final overtimeHours = double.tryParse(_overtimeHoursController.text);
    final payMultiplier = double.tryParse(_payMultiplierController.text);

    // Validation for Present/Half Day/OT status - only required for hourly staff
    if (widget.isHourly && (statusToMark == 'P' || statusToMark == 'HD' || statusToMark == 'OT')) {
      if (_useManualHours) {
        // Manual hours mode - require worked hours for hourly staff
        if (workedHours == null || workedHours <= 0) {
          SnackbarUtils.showError('Please enter worked hours');
          return;
        }
      } else {
        // Time-based mode - require check-in time for hourly staff
        if (_inTime == null) {
          SnackbarUtils.showError('Please select check-in time');
          return;
        }
      }
    }

    // Validation for OT status - always required
    if (statusToMark == 'OT' && (overtimeHours == null || overtimeHours <= 0)) {
      SnackbarUtils.showError('Please enter overtime hours');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // For Absent or Off, clear times, overtime, and worked hours
    String? finalInTime;
    String? finalOutTime;
    double? finalOvertimeHours;
    double? finalWorkedHours;
    double? finalPayMultiplier;

    if (statusToMark == 'P' || statusToMark == 'HD' || statusToMark == 'OT') {
      if (_useManualHours && (workedHours != null && workedHours > 0)) {
        finalWorkedHours = workedHours;
        finalInTime = null;
        finalOutTime = null;
      } else if (_inTime != null) {
        finalInTime = _inTime;
        finalOutTime = _outTime;
        finalWorkedHours = null;
      }
      finalOvertimeHours = statusToMark == 'OT' ? overtimeHours : null;
      // Pay multiplier applies to present/half day/OT
      finalPayMultiplier = payMultiplier != null && payMultiplier > 0 ? payMultiplier : null;
    }

    widget.onMark(statusToMark, finalInTime, finalOutTime, finalOvertimeHours, finalWorkedHours, finalPayMultiplier);
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

          // Status Selection - Show P/HD/A/Off in first row
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
                    _isPresentSelected(),
                    () => _onStatusChipTapped('P'),
                    isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatusButton(
                    'HD',
                    'Half Day',
                    Colors.blue,
                    _isHdSelected(),
                    () => _onStatusChipTapped('HD'),
                    isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatusButton(
                    'A',
                    'Absent',
                    AppColors.warningRed,
                    _isAbsentSelected(),
                    () => _onStatusChipTapped('A'),
                    isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatusButton(
                    'Off',
                    'Off',
                    Colors.purple,
                    _isOffSelected(),
                    () => _onStatusChipTapped('Off'),
                    isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatusButton(
                    'OT',
                    'Overtime',
                    Colors.orange,
                    _isOvertimeSelected(),
                    () => _onStatusChipTapped('OT'),
                    isDark,
                  ),
                ),
              ],
            ),
          ),

          // Check In / Check Out OR Manual Hours (only for Present, Half Day, or OT; hide when Remove is shown)
          if (!_removeRequested &&
              ((_selectedStatus == 'P' || _selectedStatus == 'HD' || _selectedStatus == 'OT') ||
                  (_selectedStatus == null && (widget.currentStatus == 'P' || widget.currentStatus == 'HD' || widget.currentStatus == 'OT'))))
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
              child: Column(
                children: [
                  // Toggle between Time-based and Manual Hours
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _useManualHours = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_useManualHours 
                                    ? (isDark ? AppColors.primaryBlue : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: !_useManualHours ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ] : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 18,
                                    color: !_useManualHours
                                        ? (isDark ? Colors.white : AppColors.primaryBlue)
                                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Time',
                                    style: AppTypography.bodyMedium(
                                      color: !_useManualHours
                                          ? (isDark ? Colors.white : AppColors.primaryBlue)
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                      fontWeight: !_useManualHours ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _useManualHours = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _useManualHours 
                                    ? (isDark ? AppColors.primaryBlue : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _useManualHours ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ] : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_note,
                                    size: 18,
                                    color: _useManualHours
                                        ? (isDark ? Colors.white : AppColors.primaryBlue)
                                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Manual Hours',
                                    style: AppTypography.bodyMedium(
                                      color: _useManualHours
                                          ? (isDark ? Colors.white : AppColors.primaryBlue)
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                      fontWeight: _useManualHours ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Show either Time fields or Manual Hours input
                  if (!_useManualHours) ...[
                    Row(
                      children: [
                        // Check In
                        Expanded(
                          child: _buildTimeField(
                            label: widget.isHourly ? 'Check In *' : 'Check In (Optional)',
                            icon: Icons.login,
                            iconColor: AppColors.successGreen,
                            time: _inTime,
                            onTap: () {
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
                        // Check Out
                        Expanded(
                          child: _buildTimeField(
                            label: 'Check Out (Optional)',
                            icon: Icons.logout,
                            iconColor: AppColors.warningRed,
                            time: _outTime,
                            onTap: () => _selectTime('out'),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Manual Hours Input
                    _buildManualHoursInput(isDark),
                  ],
                  
                  // Overtime Hours Input (only for OT status)
                  if (_selectedStatus == 'OT')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildOvertimeInput(isDark),
                    ),
                  
                  // Pay Multiplier Input
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildPayMultiplierInput(isDark),
                  ),
                ],
              ),
            ),

          // Remove mode note (only after user taps the matching chip)
          if (_removeRequested && _removeIntent != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.horizontalPadding(context)),
              child: Text(
                _removeIntent == 'ot_only'
                    ? 'Only overtime will be cleared for this day.'
                    : 'Attendance will be cleared for this day.',
                style: AppTypography.bodySmall(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
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
                    onPressed: _isLoading ? null : (_removeRequested ? _handleRemove : _handleMark),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: () {
                        if (_removeRequested && _removeIntent != null) {
                          return _removeIntent == 'ot_only' ? Colors.orange : AppColors.warningRed;
                        }
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

  Widget _buildManualHoursInput(bool isDark) {
    return TextField(
      controller: _workedHoursController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: widget.isHourly ? 'Worked Hours *' : 'Worked Hours (Optional)',
        hintText: 'Enter hours worked (e.g. 8)',
        prefixIcon: const Icon(Icons.schedule, color: AppColors.primaryBlue),
        suffixText: 'hrs',
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildOvertimeInput(bool isDark) {
    return TextField(
      controller: _overtimeHoursController,
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
    );
  }

  Widget _buildPayMultiplierInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, size: 16, color: Colors.purple),
            const SizedBox(width: 6),
            Text(
              'Pay Multiplier (Optional)',
              style: AppTypography.bodySmall(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Quick select buttons
            _buildMultiplierChip('1x', 1.0, isDark),
            const SizedBox(width: 8),
            _buildMultiplierChip('1.5x', 1.5, isDark),
            const SizedBox(width: 8),
            _buildMultiplierChip('2x', 2.0, isDark),
            const SizedBox(width: 12),
            // Custom input
            Expanded(
              child: TextField(
                controller: _payMultiplierController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: 'Custom',
                  suffixText: 'x',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Use for special pay (e.g., 2x for Sunday work)',
          style: AppTypography.bodySmall(
            color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.7) : AppColors.textSecondaryLight.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplierChip(String label, double value, bool isDark) {
    final currentValue = double.tryParse(_payMultiplierController.text) ?? 1.0;
    final isSelected = currentValue == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (value == 1.0) {
            _payMultiplierController.clear();
          } else {
            _payMultiplierController.text = value.toString();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : (isDark ? AppColors.surfaceDark : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall(
            color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
