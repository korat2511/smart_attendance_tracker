/// API and backend configuration (Laravel base URL, endpoints, etc.).
/// Staging environment: staging.nutanvij.com
abstract class ApiConstants {
  ApiConstants._();

  /// Base URL for Laravel API (staging environment).
  static const String baseUrl = 'https://staging.nutanvij.com/api';

  /// API version prefix (e.g. /v1) if your Laravel API uses versioning
  static const String apiVersion = 'v1';

  /// Full base path: baseUrl + version (e.g. https://staging.nutanvij.com/api/v1)
  static String get basePath => '$baseUrl/$apiVersion';


}
