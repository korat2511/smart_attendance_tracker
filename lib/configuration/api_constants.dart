
abstract class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://staging.nutanvij.com/api';

  static const String apiVersion = 'v1';

  static String get basePath => '$baseUrl/$apiVersion';


}
