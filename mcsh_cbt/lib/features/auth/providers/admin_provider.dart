import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mcsh_cbt/services/authservice.dart';
import 'package:mcsh_cbt/services/storage_service.dart';
import '../services/admin_service.dart';
import '../services/teacher_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  Admin? _currentAdmin;
  bool _isLoading = false;
  String _errorMessage = '';
  List<Teacher> _pendingTeachers = [];
  List<Teacher> _allTeachers = [];

  // Getters
  Admin? get currentAdmin => _currentAdmin;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentAdmin != null;
  List<Teacher> get pendingTeachers => _pendingTeachers;
  List<Teacher> get allTeachers => _allTeachers;

  // Admin login
  Future<bool> login({
    required String username,
    required String password,
  }) async {

    final authService = await GetIt.I.getAsync<AuthService>();
    final storageService = await GetIt.I.getAsync<StorageService>();


    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await authService.login(
        password: password, email: username,
      );

      _isLoading = false;

      if (result?['token'] != null) {
        if (result?["user"]["role"] != "ADMIN") throw    Exception("Invalid admin user");
        _currentAdmin = Admin(
          id: result?['user']['id'],
          username: result?['user']['firstName'],
          email: result?['user']['email'],
          password:
              password, // Storing for simplicity; would be token-based in real app
          role: result?['user']['role'],
        );

        storageService.saveString("auth_token", result?['token']);
        storageService.saveString("userId", result?["user"]['id']);
        storageService.saveString("email", result?["user"]['email']);

        // Load pending teachers on login
        await loadPendingTeachers();

        notifyListeners();
        return true;
      } else {
        _errorMessage = result?['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Logout
  void logout() {
    _currentAdmin = null;
    _pendingTeachers = [];
    _allTeachers = [];
    notifyListeners();
  }

  // Load pending teachers
  Future<void> loadPendingTeachers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _pendingTeachers = _adminService.getPendingTeacherAccounts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load all teachers
  Future<void> loadAllTeachers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allTeachers = _adminService.getAllTeacherAccounts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Approve teacher
  Future<bool> approveTeacher({
    required String teacherId,
    List<String>? subjects,
    List<String>? grades,
  }) async {
    if (_currentAdmin == null) {
      _errorMessage = 'Admin authentication required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _adminService.approveTeacher(
        teacherId: teacherId,
        subjects: subjects,
        grades: grades,
      );

      _isLoading = false;

      if (result['success']) {
        // Refresh the teacher lists
        await loadPendingTeachers();
        if (_allTeachers.isNotEmpty) {
          await loadAllTeachers();
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Reject teacher
  Future<bool> rejectTeacher({
    required String teacherId,
    String? reason,
  }) async {
    if (_currentAdmin == null) {
      _errorMessage = 'Admin authentication required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _adminService.rejectTeacher(
        teacherId: teacherId,
        reason: reason,
      );

      _isLoading = false;

      if (result['success']) {
        // Refresh the teacher lists
        await loadPendingTeachers();
        if (_allTeachers.isNotEmpty) {
          await loadAllTeachers();
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update teacher assignments
  Future<bool> updateTeacherAssignments({
    required String teacherId,
    required List<String> subjects,
    required List<String> grades,
  }) async {
    if (_currentAdmin == null) {
      _errorMessage = 'Admin authentication required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _adminService.updateTeacherAssignments(
        teacherId: teacherId,
        subjects: subjects,
        grades: grades,
      );

      _isLoading = false;

      if (result['success']) {
        // Refresh the teacher lists
        if (_allTeachers.isNotEmpty) {
          await loadAllTeachers();
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Create new admin (only existing admins can do this)
  Future<bool> createAdmin({
    required String username,
    required String password,
    required String email,
    String role = 'admin',
  }) async {
    if (_currentAdmin == null) {
      _errorMessage = 'Admin authentication required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _adminService.createAdmin(
        adminId: _currentAdmin!.id,
        username: username,
        password: password,
        email: email,
        role: role,
      );

      _isLoading = false;

      if (result['success']) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Get teacher details by ID
  Teacher? getTeacherById(String id) {
    return _adminService.getTeacherById(id);
  }
}
