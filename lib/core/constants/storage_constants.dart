/// Keys for local storage (e.g. SharedPreferences, secure storage).
abstract class StorageConstants {
  StorageConstants._();

  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyUserMobile = 'user_mobile';
  static const String keyUserBusinessName = 'user_business_name';
  static const String keyUserStaffSize = 'user_staff_size';
  static const String keyUserData = 'user_data';
  static const String keyIsLoggedIn = 'is_logged_in';
}
