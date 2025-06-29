

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mcsh_cbt/core/models/result.dart';
import 'package:mcsh_cbt/features/exam/models/examination.dart';
import 'package:mcsh_cbt/features/exam/models/gradeconnection.dart';
import 'package:mcsh_cbt/features/exam/models/userconnection.dart';
import 'package:mcsh_cbt/services/gradeservice.dart';
import 'package:mcsh_cbt/services/subjectservice.dart';
import 'package:mcsh_cbt/services/userservice.dart';

import '../../subject/models/subject.dart';


class UserProvider extends ChangeNotifier {
  // Add the missing state variables
  bool _isLoading = false;
  String _errorMessage = '';

  

  GradeConnection? _grades = null;
  List<UserNode> _teachers = [];
  List<UserNode> _students = [];
  List<Subject> _subjects = [];




  List<UserNode> get  teacher => _teachers;
  GradeConnection? get grades => _grades;
  List<Subject> get subject => _subjects;
  List<UserNode> get students => _students;

 Future<Result<GradeConnection?, String>>  getGrades() async {

  try {
      final gradeService = await GetIt.I.getAsync<GradeService>();

      final result = await gradeService.getGrades();
      
      print(result);
      if (result != null) {
          _grades =  GradeConnection.fromJson(result);
        _isLoading = true; 
        notifyListeners();
        return Ok(_grades);
      } else {
        _errorMessage = result?['message'] ?? 'Failed to load examinations';
        notifyListeners();
        return Err(_errorMessage);
      }
    } catch (e) {
      print('Error fetching grades: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return Err(_errorMessage);
    }

 }

  Future<Result<List<Subject>, String>> getSubjects() async {
  try {
    final subjectService = await GetIt.I.getAsync<SubjectService>();
    final result = await subjectService.getSubjects();
    
    print(result);
    
    if (result != null && result["edges"] != null) {
      _subjects = Subject.listFromJson(result['edges']);
      notifyListeners();
      return Ok(_subjects);
    }
    
    // If we reach here, either result is null or result["edges"] is null
    _errorMessage = "No subjects data found";
    notifyListeners();
    return Err(_errorMessage);
    
  } catch (e) {
    print('Error fetching subjects: $e');
    _isLoading = false;
    _errorMessage = e.toString();
    notifyListeners();
    return Err(_errorMessage);
  }
}


  Future<Result<List<UserNode>, String>> getUser({required String role}) async {
    try {
      final userService = await GetIt.I.getAsync<UserService>();

      final result = await userService.getUsers(filter: {"role": role});
      
      print(result);
      if (result?["edges"] != null) {
         if (role == "TEACHER") {
          _teachers =  UserNode.listFromJson(result?['edges'] ?? []);
         } else if (role == "STUDENT") {
          _students =  UserNode.listFromJson(result?['edges'] ?? []);
         }
        _isLoading = true; 
        notifyListeners();
        return Ok(_teachers);
      } else {
        _errorMessage = result?['message'] ?? 'Failed to load examinations';
        notifyListeners();
        return Err(_errorMessage);
      }
    } catch (e) {
      print('Error fetching users: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return Err(_errorMessage);
    }
  }

  

  // Method to clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Method to reset the provider state
  void reset() {
    _isLoading = false;
    _errorMessage = '';
    _teachers = [];
    _grades = null;
    notifyListeners();
  }



}