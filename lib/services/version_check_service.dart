import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_attendance_tracker/configuration/app_constants.dart';

class VersionCheckResult {
  final bool updateAvailable;
  final String? latestVersion;
  final String? androidUrl;
  final String? iosUrl;
  final String? message;
  final List<String>? releaseNotes;
  final bool androidForceUpdate;
  final bool iosForceUpdate;

  VersionCheckResult({
    required this.updateAvailable,
    this.latestVersion,
    this.androidUrl,
    this.iosUrl,
    this.message,
    this.releaseNotes,
    this.androidForceUpdate = false,
    this.iosForceUpdate = false,
  });
}

class VersionCheckService {
  static bool _isVersionGreater(String remote, String current) {
    final rParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final r = i < rParts.length ? rParts[i] : 0;
      final c = i < cParts.length ? cParts[i] : 0;
      if (r != c) return r > c;
    }
    return false;
  }

  static Future<VersionCheckResult> check() async {
    try {
      final response = await http.get(Uri.parse(AppConstants.versionCheckUrl)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) {
        return VersionCheckResult(updateAvailable: false);
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (json == null) return VersionCheckResult(updateAvailable: false);

      final latestVersion = json['latest_version'] as String? ?? '';
      final updateUrl = json['update_url'] as Map<String, dynamic>?;
      final androidUrl = updateUrl?['android'] as String?;
      final iosUrl = updateUrl?['ios'] as String?;
      final message = json['message'] as String?;
      final releaseNotes = (json['release_notes'] as List<dynamic>?)?.cast<String>();
      final androidForceUpdate = json['android_force_update'] as bool? ?? false;
      final iosForceUpdate = json['ios_force_update'] as bool? ?? false;

      final updateAvailable = latestVersion.isNotEmpty &&
          _isVersionGreater(latestVersion, AppConstants.appVersion);

      return VersionCheckResult(
        updateAvailable: updateAvailable,
        latestVersion: latestVersion,
        androidUrl: androidUrl,
        iosUrl: iosUrl,
        message: message,
        releaseNotes: releaseNotes,
        androidForceUpdate: androidForceUpdate,
        iosForceUpdate: iosForceUpdate,
      );
    } catch (_) {
      return VersionCheckResult(updateAvailable: false);
    }
  }
}
