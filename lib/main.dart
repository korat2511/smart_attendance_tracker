import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_attendance_tracker/configuration/app_constants.dart';
import 'package:smart_attendance_tracker/configuration/theme_provider.dart';
import 'package:smart_attendance_tracker/utils/navigation_utils.dart';
import 'package:smart_attendance_tracker/ui/screens/auth/splash_screen.dart';
import 'package:smart_attendance_tracker/ui/providers/staff_provider.dart';
import 'package:smart_attendance_tracker/ui/providers/attendance_provider.dart';
import 'package:smart_attendance_tracker/ui/providers/report_provider.dart';
import 'package:smart_attendance_tracker/ui/providers/home_provider.dart';
import 'package:smart_attendance_tracker/ui/providers/cashbook_provider.dart';
import 'package:smart_attendance_tracker/ui/providers/subscription_provider.dart';

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
