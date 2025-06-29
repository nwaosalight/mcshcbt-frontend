import 'dart:async';
import 'package:flutter/foundation.dart';

// Status of teacher account
enum TeacherStatus { pending, approved, rejected }

// Model for Teacher
class Teacher {
  final String id;
  final String firstname;
  final String lastname;
  final String email;
  final String password; // In a real app, this would be hashed
  List<String> subjects;
  List<String> grades;
  TeacherStatus status;
  String? rejectionReason;

  Teacher({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.password,
    required this.subjects,
    required this.grades,
    this.status = TeacherStatus.pending,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      // We wouldn't include password in toJson in a real app
      'subjects': subjects,
      'grades': grades,
      'status': status.toString(),
      'rejectionReason': rejectionReason,
    };
  }

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      email: json['email'],
      password: json['password'],
      subjects: List<String>.from(json['subjects']),
      grades: List<String>.from(json['grades']),
      status: _statusFromString(json['status']),
      rejectionReason: json['rejectionReason'],
    );
  }

  static TeacherStatus _statusFromString(String status) {
    switch (status) {
      case 'TeacherStatus.approved':
        return TeacherStatus.approved;
      case 'TeacherStatus.rejected':
        return TeacherStatus.rejected;
      default:
        return TeacherStatus.pending;
    }
  }
}

class TeacherService {
  // Simulate a database using an in-memory list
  final List<Teacher> _teachers = [];

  // For notifications
  final StreamController<String> _notificationController =
      StreamController<String>.broadcast();
  Stream<String> get notifications => _notificationController.stream;

  // Singleton pattern
  static final TeacherService _instance = TeacherService._internal();

  factory TeacherService() {
    return _instance;
  }

  TeacherService._internal();

  // Signup method
  Future<Map<String, dynamic>> signup({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    required List<String> subjects,
    required List<String> grades,
  }) async {
    try {
      // Input validation
      if (firstname.isEmpty ||
          lastname.isEmpty ||
          email.isEmpty ||
          password.isEmpty) {
        return {'success': false, 'message': 'All fields are required'};
      }

      // Email validation (basic pattern check)
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
        };
      }

      // Password strength check
      if (password.length < 8) {
        return {
          'success': false,
          'message': 'Password must be at least 8 characters long',
        };
      }

      final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);
      final hasNumbers = RegExp(r'[0-9]').hasMatch(password);

      if (!hasLetters || !hasNumbers) {
        return {
          'success': false,
          'message': 'Password must contain both letters and numbers',
        };
      }

      // Check for duplicate email
      final existingTeacher = _teachers.any(
        (teacher) => teacher.email.toLowerCase() == email.toLowerCase(),
      );
      if (existingTeacher) {
        return {'success': false, 'message': 'Email is already registered'};
      }

      // Create a new teacher with auto-generated ID
      final newTeacher = Teacher(
        id: 'TCH${DateTime.now().millisecondsSinceEpoch}',
        firstname: firstname,
        lastname: lastname,
        email: email,
        password: password, // In a real app, we would hash this
        subjects: subjects,
        grades: grades,
        status: TeacherStatus.pending,
      );

      // Add to our in-memory database
      _teachers.add(newTeacher);

      // Notify admins (in a real app, this would send an actual notification)
      _notifyAdmins(
        'New teacher signup: ${newTeacher.firstname} ${newTeacher.lastname}',
      );

      return {
        'success': true,
        'message': 'Signup successful! Your account is pending approval.',
        'teacher': newTeacher.toJson(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during signup: ${e.toString()}',
      };
    }
  }

  // Login method
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Find teacher by email
      final teacher = _teachers.firstWhere(
        (t) => t.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('Invalid email or password'),
      );

      // Check password (in a real app, we would compare hashed passwords)
      if (teacher.password != password) {
        throw Exception('Invalid email or password');
      }

      // Check account status
      switch (teacher.status) {
        case TeacherStatus.pending:
          return {
            'success': false,
            'message': 'Your account is awaiting admin approval.',
            'status': 'pending',
          };
        case TeacherStatus.rejected:
          return {
            'success': false,
            'message':
                'Your account has been rejected${teacher.rejectionReason != null ? ': ${teacher.rejectionReason}' : '.'}',
            'status': 'rejected',
          };
        case TeacherStatus.approved:
          return {
            'success': true,
            'message': 'Login successful',
            'teacher': teacher.toJson(),
            'status': 'approved',
          };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'status': 'error'};
    }
  }

  // Admin: Get all pending teachers
  List<Teacher> getPendingTeachers() {
    return _teachers
        .where((teacher) => teacher.status == TeacherStatus.pending)
        .toList();
  }

  // Admin: Approve teacher
  Future<bool> approveTeacher({
    required String teacherId,
    List<String>? subjects,
    List<String>? grades,
  }) async {
    try {
      final index = _teachers.indexWhere((t) => t.id == teacherId);
      if (index == -1) {
        return false;
      }

      // Update teacher status and optionally subjects and grades
      final teacher = _teachers[index];
      teacher.status = TeacherStatus.approved;

      if (subjects != null) {
        teacher.subjects = subjects;
      }

      if (grades != null) {
        teacher.grades = grades;
      }

      // Notify the teacher (in a real app, this would send an email or in-app notification)
      _notifyTeacher(
        teacher.email,
        'Your account has been approved. You can now log in to the Mountain Crest CBT system.',
      );

      return true;
    } catch (e) {
      debugPrint('Error approving teacher: ${e.toString()}');
      return false;
    }
  }

  // Admin: Reject teacher
  Future<bool> rejectTeacher({
    required String teacherId,
    String? reason,
  }) async {
    try {
      final index = _teachers.indexWhere((t) => t.id == teacherId);
      if (index == -1) {
        return false;
      }

      // Update teacher status and add rejection reason
      final teacher = _teachers[index];
      teacher.status = TeacherStatus.rejected;
      teacher.rejectionReason = reason;

      // Notify the teacher (in a real app, this would send an email or in-app notification)
      _notifyTeacher(
        teacher.email,
        'Your account has been rejected${reason != null ? ' for the following reason: $reason' : '.'}',
      );

      return true;
    } catch (e) {
      debugPrint('Error rejecting teacher: ${e.toString()}');
      return false;
    }
  }

  // Admin: Update teacher subjects and grades
  Future<bool> updateTeacherAssignments({
    required String teacherId,
    required List<String> subjects,
    required List<String> grades,
  }) async {
    try {
      final index = _teachers.indexWhere((t) => t.id == teacherId);
      if (index == -1) {
        return false;
      }

      // Update teacher's subjects and grades
      final teacher = _teachers[index];
      teacher.subjects = subjects;
      teacher.grades = grades;

      // Notify the teacher (in a real app, this would send an email or in-app notification)
      _notifyTeacher(
        teacher.email,
        'Your teaching assignments have been updated. Please check your dashboard for details.',
      );

      return true;
    } catch (e) {
      debugPrint('Error updating teacher assignments: ${e.toString()}');
      return false;
    }
  }

  // Get teacher by ID
  Teacher? getTeacherById(String id) {
    try {
      return _teachers.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get all teachers
  List<Teacher> getAllTeachers() {
    return List.from(_teachers);
  }

  // Helper method to notify admins (simplified for this example)
  void _notifyAdmins(String message) {
    _notificationController.add('ADMIN: $message');
    debugPrint('Admin notification: $message');
  }

  // Helper method to notify a teacher (simplified for this example)
  void _notifyTeacher(String email, String message) {
    _notificationController.add('TEACHER-$email: $message');
    debugPrint('Teacher notification to $email: $message');
  }

  // Dispose method to clean up resources
  void dispose() {
    _notificationController.close();
  }
}
