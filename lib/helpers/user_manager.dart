import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserManager {
  // Save token and user info after login
  static Future<void> saveUser(Map<String, dynamic> user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));
  }

  // Get user info as Map
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) return jsonDecode(userString);
    return null;
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Clear user info & token on logout
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Convenience getters
  static Future<String?> getName() async {
    final user = await getUser();
    if (user == null) return null;
    return '${user['first_name']} ${user['last_name']}';
  }

  static Future<String?> getRole() async {
    final user = await getUser();
    if (user == null) return null;
    return user['role'];
  }

  static Future<String?> getImageUrl() async {
    final user = await getUser();
    if (user == null) return null;
    return user['image_url'];
  }
}
