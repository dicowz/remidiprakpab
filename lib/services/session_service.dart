import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  final SharedPreferences _prefs;
  static const String _sessionKey = 'is_logged_in';
  static const String _uidKey = 'active_user_uid';

  SessionService(this._prefs);

  Future<bool> isLoggedIn() async {
    return _prefs.getBool(_sessionKey) ?? false;
  }

  Future<String?> getActiveUserUid() async {
    return _prefs.getString(_uidKey);
  }

  Future<void> saveSession(String uid) async {
    await _prefs.setBool(_sessionKey, true);
    await _prefs.setString(_uidKey, uid);
  }

  Future<void> clearSession() async {
    await _prefs.setBool(_sessionKey, false);
    await _prefs.remove(_uidKey);
  }
}
