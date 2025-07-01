import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static Future<void> saveUserSession(int userId, bool isOnboarded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    await prefs.setBool('is_onboarded', isOnboarded);
  }

  static Future<Map<String, dynamic>?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final isOnboarded = prefs.getBool('is_onboarded');

    if (userId != null && isOnboarded != null) {
      return {'user_id': userId, 'is_onboarded': isOnboarded};
    } else {
      return null;
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
