import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_constants.dart';
import '../models/user_model.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Token methods
  static Future<bool> saveToken(String token) async {
    await init();
    return await _prefs!.setString(StorageConstants.keyAccessToken, token);
  }

  static String? getToken() {
    if (_prefs == null) return null;
    return _prefs!.getString(StorageConstants.keyAccessToken);
  }

  static Future<bool> removeToken() async {
    await init();
    return await _prefs!.remove(StorageConstants.keyAccessToken);
  }

  // User data methods
  static Future<bool> saveUser(UserModel user) async {
    await init();
    final userJson = jsonEncode(user.toJson());
    await _prefs!.setBool(StorageConstants.keyIsLoggedIn, true);
    await _prefs!.setInt(StorageConstants.keyUserId, user.id);
    await _prefs!.setString(StorageConstants.keyUserName, user.name);
    await _prefs!.setString(StorageConstants.keyUserEmail, user.email);
    await _prefs!.setString(StorageConstants.keyUserMobile, user.mobile);
    await _prefs!.setString(StorageConstants.keyUserBusinessName, user.businessName);
    await _prefs!.setInt(StorageConstants.keyUserStaffSize, user.staffSize);
    return await _prefs!.setString(StorageConstants.keyUserData, userJson);
  }

  static UserModel? getUser() {
    if (_prefs == null) return null;
    final userJson = _prefs!.getString(StorageConstants.keyUserData);
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  static bool isLoggedIn() {
    if (_prefs == null) return false;
    return _prefs!.getBool(StorageConstants.keyIsLoggedIn) ?? false;
  }

  static Future<bool> clearUser() async {
    await init();
    await _prefs!.remove(StorageConstants.keyIsLoggedIn);
    await _prefs!.remove(StorageConstants.keyUserId);
    await _prefs!.remove(StorageConstants.keyUserName);
    await _prefs!.remove(StorageConstants.keyUserEmail);
    await _prefs!.remove(StorageConstants.keyUserMobile);
    await _prefs!.remove(StorageConstants.keyUserBusinessName);
    await _prefs!.remove(StorageConstants.keyUserStaffSize);
    await _prefs!.remove(StorageConstants.keyUserData);
    return await removeToken();
  }
}
