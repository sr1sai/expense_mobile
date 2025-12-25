import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserSession {
  static UserPublicDTO? currentUser;
  
  // Keys for SharedPreferences (matches Kotlin SessionManager)
  // Using 'flutter.' prefix to match shared_preferences plugin format
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyDeviceId = 'device_id';
  
  /// Save user session to SharedPreferences (for Kotlin to access)
  static Future<void> saveUser(UserPublicDTO user) async {
    currentUser = user;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyUserName, user.name);
    await prefs.setString(_keyUserEmail, user.email);
    await prefs.setString(_keyUserPhone, user.phoneNumber);
    await prefs.setBool(_keyIsLoggedIn, true);
    
    print('✓ User session saved to SharedPreferences');
    print('User ID: ${user.id}');
  }
  
  /// Load user session from SharedPreferences
  static Future<UserPublicDTO?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    
    if (!isLoggedIn) {
      print('No user session found');
      return null;
    }
    
    final id = prefs.getString(_keyUserId);
    final name = prefs.getString(_keyUserName);
    final email = prefs.getString(_keyUserEmail);
    final phone = prefs.getString(_keyUserPhone);
    
    if (id != null && name != null && email != null && phone != null) {
      currentUser = UserPublicDTO(
        id: id,
        name: name,
        email: email,
        phoneNumber: phone,
      );
      print('✓ User session loaded from SharedPreferences');
      print('User ID: $id');
      return currentUser;
    }
    
    return null;
  }
  
  /// Clear user session (logout)
  static Future<void> clearSession() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✓ User session cleared');
  }
}

