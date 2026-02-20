import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/core.dart';
import 'core/utils/navigation_utils.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/staff/providers/staff_provider.dart';
import 'features/staff/providers/attendance_provider.dart';
import 'features/staff/providers/report_provider.dart';
import 'features/home/providers/home_provider.dart';
import 'features/home/providers/cashbook_provider.dart';
import 'features/subscription/providers/subscription_provider.dart';

void main() {
  runApp(const SmartAttendanceTrackerApp());
}

class SmartAttendanceTrackerApp extends StatelessWidget {
  const SmartAttendanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => StaffProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => CashbookProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
          ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            navigatorKey: NavigationUtils.navigatorKey,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
