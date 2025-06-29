import 'package:flutter/foundation.dart';
import 'teacher_service.dart';

class Admin {
  final String id;
  final String username;
  final String password; // In a real app, this would be hashed
  final String email;
  final String role;

  Admin({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    this.role = 'admin',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      // We wouldn't include password in toJson in a real app
    };
  }
}

class AdminService {
  // Simulate a database using an in-memory list
  final List<Admin> _admins = [];

  // Reference to the teacher service
  final TeacherService _teacherService = TeacherService();

  // Singleton pattern
  static final AdminService _instance = AdminService._internal();

  factory AdminService() {
    return _instance;
  }

  AdminService._internal() {
    // Initialize with a default admin account
    _admins.add(
      Admin(
        id: 'ADM1001',
        username: 'admin',
        password: 'admin123', // In a real app, this would be securely hashed
        email: 'admin@mountaincrest.edu',
      ),
    );
  }

  // Admin login
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      // Find admin by username
      final admin = _admins.firstWhere(
        (a) => a.username.toLowerCase() == username.toLowerCase(),
        orElse: () => throw Exception('Invalid username or password'),
      );

      // Check password (in a real app, we would compare hashed passwords)
      if (admin.password != password) {
        throw Exception('Invalid username or password');
      }

      return {
        'success': true,
        'message': 'Login successful',
        'admin': admin.toJson(),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get pending teacher accounts
  List<Teacher> getPendingTeacherAccounts() {
    return _teacherService.getPendingTeachers();
  }

  // Get all teacher accounts
  List<Teacher> getAllTeacherAccounts() {
    return _teacherService.getAllTeachers();
  }

  // Approve a teacher account
  Future<Map<String, dynamic>> approveTeacher({
    required String teacherId,
    List<String>? subjects,
    List<String>? grades,
  }) async {
    try {
      final success = await _teacherService.approveTeacher(
        teacherId: teacherId,
        subjects: subjects,
        grades: grades,
      );

      if (success) {
        return {
          'success': true,
          'message': 'Teacher account approved successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to approve teacher account. Teacher ID not found.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error approving teacher account: ${e.toString()}',
      };
    }
  }

  // Reject a teacher account
  Future<Map<String, dynamic>> rejectTeacher({
    required String teacherId,
    String? reason,
  }) async {
    try {
      final success = await _teacherService.rejectTeacher(
        teacherId: teacherId,
        reason: reason,
      );

      if (success) {
        return {'success': true, 'message': 'Teacher account rejected'};
      } else {
        return {
          'success': false,
          'message': 'Failed to reject teacher account. Teacher ID not found.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error rejecting teacher account: ${e.toString()}',
      };
    }
  }

  // Update teacher's subjects and grades
  Future<Map<String, dynamic>> updateTeacherAssignments({
    required String teacherId,
    required List<String> subjects,
    required List<String> grades,
  }) async {
    try {
      final success = await _teacherService.updateTeacherAssignments(
        teacherId: teacherId,
        subjects: subjects,
        grades: grades,
      );

      if (success) {
        return {
          'success': true,
          'message': 'Teacher assignments updated successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to update teacher assignments. Teacher ID not found.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating teacher assignments: ${e.toString()}',
      };
    }
  }

  // Get teacher details by ID
  Teacher? getTeacherById(String id) {
    return _teacherService.getTeacherById(id);
  }

  // Create a new admin account (only existing admins can do this)
  Future<Map<String, dynamic>> createAdmin({
    required String adminId, // ID of the admin creating the new admin
    required String username,
    required String password,
    required String email,
    String role = 'admin',
  }) async {
    try {
      // Check if the creating admin exists
      final creatingAdmin = _admins.any((a) => a.id == adminId);
      if (!creatingAdmin) {
        return {
          'success': false,
          'message':
              'Unauthorized: Only existing admins can create new admin accounts',
        };
      }

      // Validate input
      if (username.isEmpty || password.isEmpty || email.isEmpty) {
        return {'success': false, 'message': 'All fields are required'};
      }

      // Check for duplicate username or email
      final duplicateUsername = _admins.any(
        (a) => a.username.toLowerCase() == username.toLowerCase(),
      );
      if (duplicateUsername) {
        return {'success': false, 'message': 'Username is already taken'};
      }

      final duplicateEmail = _admins.any(
        (a) => a.email.toLowerCase() == email.toLowerCase(),
      );
      if (duplicateEmail) {
        return {'success': false, 'message': 'Email is already registered'};
      }

      // Create new admin
      final newAdmin = Admin(
        id: 'ADM${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        password: password, // In a real app, this would be hashed
        email: email,
        role: role,
      );

      _admins.add(newAdmin);

      return {
        'success': true,
        'message': 'Admin account created successfully',
        'admin': newAdmin.toJson(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating admin account: ${e.toString()}',
      };
    }
  }

  // Get all admins
  List<Admin> getAllAdmins() {
    return List.from(_admins);
  }
}
