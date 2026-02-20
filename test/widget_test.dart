import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smart_attendance_tracker/main.dart';
import 'package:smart_attendance_tracker/core/core.dart';

void main() {
  testWidgets('App displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const SmartAttendanceTrackerApp(),
      ),
    );

    // Verify that the app name appears in the app bar.
    expect(find.text('Smart Attendance Tracker'), findsWidgets);

    // Verify that the subtitle text appears.
    expect(find.text('MVP · Provider · Light/Dark theme ready'), findsOneWidget);
  });
}
