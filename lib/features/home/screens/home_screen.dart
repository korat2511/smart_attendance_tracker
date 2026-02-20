import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/focus_utils.dart';
import '../providers/home_provider.dart';
import 'staff_screen.dart';
import 'cashbook_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Widget> _screens = const [
    StaffScreen(),
    CashbookScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<HomeProvider>(
      builder: (context, homeProvider, _) {
        return GestureDetector(
          onTap: FocusUtils.unfocus,
          behavior: HitTestBehavior.opaque,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(AppConstants.appName),
              centerTitle: true,
            ),
            body: _screens[homeProvider.currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: homeProvider.currentIndex,
              onTap: (index) {
                FocusUtils.unfocus();
                homeProvider.setCurrentIndex(index);
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primaryBlue,
              unselectedItemColor: theme.colorScheme.onSurfaceVariant,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Staff',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long),
                  label: 'Expenses',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
