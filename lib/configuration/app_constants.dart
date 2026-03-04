abstract class AppConstants {
  AppConstants._();

  static const String appName = 'AttendEx';
  static const String appVersion = '1.0.8';
  static const String buildNumber = '8';
  static String get fullVersion => '$appVersion ($buildNumber)';

  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int otpLength = 6;

  static const List<MapEntry<String, String>> paymentMethods = [
    MapEntry('upi', 'UPI'),
    MapEntry('bank_transfer', 'Bank Transfer'),
    MapEntry('cash', 'Cash'),
    MapEntry('other', 'Other'),
  ];

  static const String defaultPaymentMethod = 'other';

  static const String versionCheckUrl =
      'https://raw.githubusercontent.com/korat2511/smart_attendance_tracker/main/config/version_config.json';
}
