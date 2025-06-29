import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mcsh_cbt/services/authservice.dart';
import 'package:mcsh_cbt/services/storage_service.dart';
import '../services/teacher_service.dart';

class TeacherProvider extends ChangeNotifier {
  final TeacherService _teacherService = TeacherService();

  Teacher? _currentTeacher;
  bool _isLoading = false;
  String _errorMessage = '';
  List<Teacher> _pendingTeachers = [];
  List<Teacher> _allTeachers = [];

  // Getters
  Teacher? get currentTeacher => _currentTeacher;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<Teacher> get pendingTeachers => _pendingTeachers;
  List<Teacher> get allTeachers => _allTeachers;
  bool get isLoggedIn => _currentTeacher != null;
  bool get isPending => _currentTeacher?.status == TeacherStatus.pending;
  bool get isApproved => _currentTeacher?.status == TeacherStatus.approved;
  bool get isRejected => _currentTeacher?.status == TeacherStatus.rejected;

  // Teacher signup
  Future<bool> signup({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    required String role, 
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // For simplifying the signup process, we're using empty lists for subjects and grades
      // In a real app, these would be selected during signup or assigned by an admin
      final authService = await GetIt.I.getAsync<AuthService>();
      final storageService = await GetIt.I.getAsync<StorageService>();

     
      final result =  await authService.signup(firstName: firstname, lastName: lastname, email: email, password: password, role: role);

    // print("result");
    // print(result);

    // print("token");
    // print(result?["token"]);

    _isLoading = false;

      if (result?['token'] != null) {
        // _currentTeacher = result['teacher'];
        storageService.saveString("auth_token", result?['token']);
        notifyListeners();
        return true;
      } else {
        _errorMessage = result?['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print(e);
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Teacher login
  Future<bool> login({required String email, required String password}) async {

    final authService = await GetIt.I.getAsync<AuthService>();
    final storageService = await GetIt.I.getAsync<StorageService>();

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await authService.login(
        email: email,
        password: password,
      );

      _isLoading = false;

      if (result?['token'] != null) {
        _currentTeacher = Teacher(id: result?["user"]['id'], firstname: result?["user"]['firstName'], lastname: result?["user"]['lastName'], email: result?["user"]['email'], password: "", subjects: [], grades: []);
        storageService.saveString("auth_token", result?['token']);
        storageService.saveString("userId", result?["user"]['id']);
        storageService.saveString("email", result?["user"]['email']);

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
    _currentTeacher = null;
    notifyListeners();
  }

  // Load pending teachers (for admin)
  Future<void> loadPendingTeachers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _pendingTeachers = _teacherService.getPendingTeachers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load all teachers (for admin)
  Future<void> loadAllTeachers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allTeachers = _teacherService.getAllTeachers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Get teacher by ID
  Teacher? getTeacherById(String id) {
    return _teacherService.getTeacherById(id);
  }

  // Update profile
  // Since properties are final, we need to create a new Teacher object
  // and replace the current one rather than modifying properties
  Future<bool> updateProfile({
    required String teacherId,
    String? newFirstname,
    String? newLastname,
    String? newEmail,
  }) async {
    if (_currentTeacher == null || _currentTeacher!.id != teacherId) {
      _errorMessage = 'Unauthorized';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Create a new Teacher with updated values
      // In a real app, we would call an update method in the service
      final firstname = newFirstname ?? _currentTeacher!.firstname;
      final lastname = newLastname ?? _currentTeacher!.lastname;
      final email = newEmail ?? _currentTeacher!.email;

      final updatedTeacher = Teacher(
        id: _currentTeacher!.id,
        firstname: firstname,
        lastname: lastname,
        email: email,
        password: _currentTeacher!.password,
        subjects: _currentTeacher!.subjects,
        grades: _currentTeacher!.grades,
        status: _currentTeacher!.status,
        rejectionReason: _currentTeacher!.rejectionReason,
      );

      _currentTeacher = updatedTeacher;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check account status
  Future<void> checkAccountStatus() async {
    if (_currentTeacher == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedTeacher = _teacherService.getTeacherById(
        _currentTeacher!.id,
      );
      if (updatedTeacher != null) {
        _currentTeacher = updatedTeacher;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
