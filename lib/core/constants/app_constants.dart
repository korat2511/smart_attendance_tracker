/// Application-wide constants (app name, version, keys, etc.).
abstract class AppConstants {
  AppConstants._();

  static const String appName = 'Attendex';
  static const String appVersion = '1.0.2';
  static const String buildNumber = '3';
  static String get fullVersion => '$appVersion ($buildNumber)';

  /// Minimum supported Android SDK (if needed for checks)
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int otpLength = 6;

  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Timeouts (seconds)
  static const int apiTimeoutSeconds = 30;
  static const int connectTimeoutSeconds = 15;

  /// Date/Time formats (for display and API)
  static const String dateFormatDisplay = 'MMM d, yyyy';
  static const String timeFormatDisplay = 'h:mm a';
  static const String dateTimeFormatDisplay = 'MMM d, yyyy · h:mm a';
  static const String dateFormatApi = 'yyyy-MM-dd';
  static const String timeFormatApi = 'HH:mm:ss';
  static const String dateTimeFormatApi = "yyyy-MM-dd'T'HH:mm:ss";
}
