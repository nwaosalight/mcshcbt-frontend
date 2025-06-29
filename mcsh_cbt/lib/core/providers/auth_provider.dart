import 'package:flutter/foundation.dart';

enum UserRole { STUDENT, TEACHER,  ADMIN, none }

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String _username = '';
  UserRole _userRole = UserRole.STUDENT;

  bool get isAuthenticated => _isAuthenticated;
  String get username => _username;
  UserRole get userRole => _userRole;

  // Simple in-memory authentication
  Future<bool> login(String username, String password, UserRole role) async {
    try {
      // In a real app, this would validate credentials against a backend
      if (password.length >= 6) {
        _isAuthenticated = true;
        _username = username;
        _userRole = role;

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _username = '';
    _userRole = UserRole.none;

    notifyListeners();
  }

  // No need to check auth status as we're not persisting it
  Future<bool> checkAuthStatus() async {
    return _isAuthenticated;
  }
}
