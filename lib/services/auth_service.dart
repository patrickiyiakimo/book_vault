import '../services/storage_service.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    final users = await StorageService.getUserData();
    if (users != null && users['email'] == email) {
      if (password.length >= 6) {
        await StorageService.setLoggedIn(true);
        return true;
      }
    }
    return false;
  }

  static Future<bool> signup(String name, String email, String password) async {
    await StorageService.saveUserData(name, email);
    await StorageService.setLoggedIn(true);
    return true;
  }

  static Future<void> logout() async {
    await StorageService.setLoggedIn(false);
  }

  static Future<bool> isAuthenticated() async {
    return StorageService.isLoggedIn();
  }
}