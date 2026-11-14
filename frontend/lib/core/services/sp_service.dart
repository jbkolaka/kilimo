import 'package:shared_preferences/shared_preferences.dart';

class SpService {
  static const String _authTokenKey = 'auth_token';

  final SharedPreferences _prefs;

  SpService(this._prefs);

  static Future<SpService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SpService(prefs);
  }

  Future<bool> saveToken(String token) async {
    return await _prefs.setString(_authTokenKey, token);
  }

  String? getToken() {
    return _prefs.getString(_authTokenKey);
  }

  Future<bool> clearToken() async {
    return await _prefs.remove(_authTokenKey);
  }

  bool hasToken() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }
}
