import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Local data source for caching auth data.
abstract class AuthLocalDataSource {
  Future<void> cacheToken(String token);
  Future<String?> getToken();
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheToken(String token) async {
    await sharedPreferences.setString(AppConstants.tokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    return sharedPreferences.getString(AppConstants.tokenKey);
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await sharedPreferences.setString(
      AppConstants.userKey,
      jsonEncode(user.toJson()),
    );
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = sharedPreferences.getString(AppConstants.userKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (e) {
      throw const CacheException(message: 'Failed to parse cached user');
    }
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(AppConstants.tokenKey);
    await sharedPreferences.remove(AppConstants.refreshTokenKey);
    await sharedPreferences.remove(AppConstants.userKey);
  }
}
