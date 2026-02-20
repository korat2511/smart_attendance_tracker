
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/screens/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    FocusUtils.unfocus();
    try {
      await ApiService().logout();
      NavigationUtils.pushAndRemoveUntil(const LoginScreen());
      SnackbarUtils.showSuccess('Logged out successfully');
    } catch (e) {
      SnackbarUtils.showError('Failed to logout');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = StorageService.getUser();
    final themeProvider = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: FocusUtils.unfocus,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Settings',
                  style: AppTypography.displaySmall(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),
                if (user != null) ...[
                  _buildSectionTitle(context, 'Account'),
                  _buildSettingTile(
                    context,
                    icon: Icons.person,
                    title: 'Name',
                    subtitle: user.name,
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: user.email,
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.phone,
                    title: 'Mobile',
                    subtitle: user.mobile,
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.business,
                    title: 'Business',
                    subtitle: user.businessName,
                  ),
                  const SizedBox(height: 24),
                ],
                _buildSectionTitle(context, 'Appearance'),
                _buildSettingTile(
                  context,
                  icon: themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  title: 'Theme',
                  subtitle: themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Session'),
                _buildSettingTile(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out from your account',
                  onTap: () => _handleLogout(context),
                  textColor: AppColors.warningRed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: AppTypography.titleMedium(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = textColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue),
        title: Text(
          title,
          style: AppTypography.titleMedium(color: titleColor),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppTypography.bodySmall(color: subtitleColor),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
