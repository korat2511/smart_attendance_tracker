import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../staff/screens/contact_list_screen.dart';
import '../../staff/screens/edit_staff_screen.dart';
import '../../staff/screens/delete_staff_dialog.dart';
import '../../staff/screens/mark_attendance_screen.dart';
import '../../staff/providers/staff_provider.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  void initState() {
    super.initState();
    // Load staff list when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaffList();
    });
  }

  void _handleAddStaff() async {
    FocusUtils.unfocus();
    final result = await NavigationUtils.push(
      const ContactListScreen(),
    );

    // Refresh staff list if staff was added
    if (result == true && mounted) {
      context.read<StaffProvider>().refreshStaffList();
    }
  }

  Future<void> _handleEditStaff(BuildContext context, StaffModel staff) async {
    FocusUtils.unfocus();
    final result = await NavigationUtils.push(
      EditStaffScreen(staff: staff),
    );

    // Refresh staff list if staff was updated
    if (result == true && mounted) {
      context.read<StaffProvider>().refreshStaffList();
    }
  }

  Future<void> _handleDeleteStaff(BuildContext context, StaffModel staff) async {
    FocusUtils.unfocus();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteStaffDialog(staffName: staff.name),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<StaffProvider>().deleteStaff(staff.id!);
        
        if (mounted) {
          SnackbarUtils.showSuccess('Staff member deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(e.toString());
        }
      }
    }
  }

  Future<void> _handleMarkAttendance(BuildContext context, StaffModel staff) async {
    FocusUtils.unfocus();
    await NavigationUtils.push(
      MarkAttendanceScreen(staff: staff),
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
        floatingActionButton: Consumer<StaffProvider>(
          builder: (context, staffProvider, _) {
            // Show FAB only when staff list is available (not loading, no error, not empty)
            if (!staffProvider.isLoading &&
                !staffProvider.hasError &&
                !staffProvider.isEmpty) {
              return FloatingActionButton(
                onPressed: _handleAddStaff,
                backgroundColor: AppColors.primaryBlue,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        body: SafeArea(
          child: Consumer<StaffProvider>(
            builder: (context, staffProvider, _) {
              if (staffProvider.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                );
              }

              if (staffProvider.hasError) {
                return _buildErrorState(
                  context,
                  theme,
                  isDark,
                  staffProvider.errorMessage ?? 'Unknown error',
                  staffProvider,
                );
              }

              if (staffProvider.isEmpty) {
                return _buildEmptyState(context, theme, isDark);
              }

              return _buildStaffList(
                context,
                theme,
                isDark,
                staffProvider.staffList,
                staffProvider,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String errorMessage,
    StaffProvider staffProvider,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.warningRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load staff',
              style: AppTypography.headlineSmall(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: AppTypography.bodyMedium(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            LoadingButton(
              text: 'Retry',
              onPressed: () => staffProvider.loadStaffList(),
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: ResponsiveUtils.responsive(
                context,
                mobile: 120,
                tablet: 150,
              ),
              height: ResponsiveUtils.responsive(
                context,
                mobile: 120,
                tablet: 150,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: ResponsiveUtils.responsive(
                  context,
                  mobile: 60,
                  tablet: 75,
                ),
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Staff Added Yet',
              style: AppTypography.headlineLarge(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.responsive(
                  context,
                  mobile: 0,
                  tablet: 48,
                ),
              ),
              child: Text(
                'Start managing your team by adding your first staff member.',
                style: AppTypography.bodyMedium(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            LoadingButton(
              text: 'Add Staff',
              onPressed: _handleAddStaff,
              width: ResponsiveUtils.responsive(
                context,
                mobile: double.infinity,
                tablet: 300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffList(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    List<StaffModel> staffList,
    StaffProvider staffProvider,
  ) {
    return RefreshIndicator(
      onRefresh: () => staffProvider.refreshStaffList(),
      color: AppColors.primaryBlue,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          ResponsiveUtils.horizontalPadding(context),
          8,
          ResponsiveUtils.horizontalPadding(context),
          80,
        ),
        itemCount: staffList.length,
        itemBuilder: (context, index) {
          final staff = staffList[index];
          return _buildStaffCard(context, theme, isDark, staff);
        },
      ),
    );
  }

  Widget _buildStaffCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    StaffModel staff,
  ) {
    String getSalaryTypeLabel(String type) {
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

    // Ref: clear border, bold dark name, lighter secondary line
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFBDBDBD);
    final nameColor = isDark ? AppColors.textPrimaryDark : const Color(0xFF1A1A1A);
    final secondaryColor = isDark ? AppColors.textSecondaryLight : const Color(0xFF5F6368);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: () => _handleMarkAttendance(context, staff),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryBlueDark,
                radius: 20,
                child: Text(
                  staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                  style: AppTypography.titleSmall(
                    color: AppColors.surfaceLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      staff.name,
                      style: AppTypography.titleLarge(
                        color: nameColor,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: secondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            staff.phoneNumber,
                            style: AppTypography.bodySmall(
                              color: secondaryColor,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹${staff.salaryAmount.toStringAsFixed(0)}/${getSalaryTypeLabel(staff.salaryType).toLowerCase()}',
                          style: AppTypography.bodySmall(
                            color: secondaryColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: secondaryColor,
                ),
                onSelected: (value) async {
                  if (value == 'attendance') {
                    await _handleMarkAttendance(context, staff);
                  } else if (value == 'edit') {
                    await _handleEditStaff(context, staff);
                  } else if (value == 'delete') {
                    await _handleDeleteStaff(context, staff);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'attendance',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Mark Attendance'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: AppColors.warningRed),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.warningRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
