import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageHelper {
  static const _storage = FlutterSecureStorage();
  static const String _userIdKey = 'user_id';
  static const String _userTokenKey = 'user_token';
  static const String _userNameKey = 'user_name';

  // Store user ID
  static Future<void> storeUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  // Get user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // Store user token
  static Future<void> storeUserToken(String token) async {
    await _storage.write(key: _userTokenKey, value: token);
  }

  // Get user token  
  static Future<String?> getUserToken() async {
    return await _storage.read(key: _userTokenKey);
  }

  // Store user name
  static Future<void> storeName(String name) async {
    await _storage.write(key: _userNameKey, value: name);
  }

  // Get user name
  static Future<String?> getName() async {
    return await _storage.read(key: _userNameKey);
  }

  // Delete user data
  static Future<void> deleteUserData() async {
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userTokenKey);
    await _storage.delete(key: _userNameKey);
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    final userId = await getUserId();
    return userId != null;
  }
}
