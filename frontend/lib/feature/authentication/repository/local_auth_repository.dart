import 'package:hive/hive.dart';
import 'package:mwandu/core/services/sp_service.dart';
import 'package:mwandu/feature/authentication/model/user_model.dart';

class LocalAuthRepository {
  static const String userBoxName = 'user_box';
  static const String _userKey = 'cached_user';

  final Box _box;
  final SpService _spService;

  LocalAuthRepository({required Box box, required SpService spService})
    : _box = box,
      _spService = spService;

  Future<void> saveUser(UserModel user) async {
    await _box.put(_userKey, user.toJson());
  }

  UserModel? getUser() {
    final raw = _box.get(_userKey);
    if (raw == null) return null;
    try {
      final map = Map<String, dynamic>.from(raw as Map);
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    await _box.delete(_userKey);
  }

  Future<void> saveToken(String token) async {
    await _spService.saveToken(token);
  }

  String? getToken() {
    return _spService.getToken();
  }

  Future<void> clearToken() async {
    await _spService.clearToken();
  }

  bool hasToken() {
    return _spService.hasToken();
  }

  Future<void> clearAuth() async {
    await clearUser();
    await clearToken();
  }
}
