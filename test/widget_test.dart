import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance_tracker/main.dart';

void main() {
  testWidgets('App displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartAttendanceTrackerApp());

    // Wait for splash screen to build.
    await tester.pump();

    // Verify that the app title appears on the splash screen.
    expect(find.text('Smart Attendance Tracker'), findsOneWidget);

    // Verify that the subtitle text appears.
    expect(find.text('Manage your team attendance'), findsOneWidget);

    // Allow the splash screen's 2-second delay timer to complete so no pending timer remains when the test ends.
    await tester.pump(const Duration(seconds: 3));
  });
}
