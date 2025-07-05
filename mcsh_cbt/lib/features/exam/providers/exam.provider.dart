import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mcsh_cbt/core/models/result.dart';
import 'package:mcsh_cbt/features/exam/models/examination.dart';
import 'package:mcsh_cbt/features/exam/models/selected.answer.dart';
import 'package:mcsh_cbt/features/subject/models/exam_question.dart';
import 'package:mcsh_cbt/services/examservice.dart';
import 'package:mcsh_cbt/services/questionservice.dart';
import 'package:mcsh_cbt/services/storage_service.dart';
import 'package:mcsh_cbt/services/studentservice.dart';

class ExamProvider extends ChangeNotifier {
  // Add the missing state variables
  bool _isLoading = false;
  String _errorMessage = '';
  Examination? _currentExam;
  List<Examination> _examinations = [];
  List<ExamQuestion> _questions = [];

  // Getters for accessing the state
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Examination? get currentExam => _currentExam;
  List<Examination> get examinations => _examinations;
  List<ExamQuestion> get questions => _questions;

  void selectCurrentExam(Examination exam) {
    _currentExam = exam;
    notifyListeners();
  }

  Future<Result<List<Examination>, String>> getSubjectExams(
    String gradeId,
    String status,
  ) async {
    try {
      final examService = await GetIt.I.getAsync<ExamService>();

      final result = await examService.getExams(
        filter: {"gradeId": gradeId, "status": status},
      );
      if (result?["edges"] != null) {
        _examinations = Examination.listFromJson(result?['edges'] ?? []);
        notifyListeners();
        return Ok(_examinations);
      } else {
        _errorMessage = result?['message'] ?? 'Failed to load examinations';
        notifyListeners();
        return Err(_errorMessage);
      }
    } catch (e) {
      print('Error fetching examinations: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return Err(_errorMessage);
    }
  }

  Future<Result<List<Map<String, dynamic>>, String>> getStudentExam() async {
    final studentExamService = await GetIt.I.getAsync<StudentExamService>();
    final storageService = await GetIt.I.getAsync<StorageService>();

    try {
      if (_currentExam == null) return Err("No exam selected");
      final userId = storageService.readString("userId");
      final result = await studentExamService.getStudentExams(
        filter: {"studentId": userId, "examId": _currentExam?.id},
      );
      print('result: $result');
      final edges = (result?['edges'] ?? []) as List;
      final nodes =
          edges
              .map((e) => (e as Map<String, dynamic>)['node'])
              .whereType<Map<String, dynamic>>()
              .toList();
      return Ok(nodes);
    } catch (e) {
      print('Error fetching student exam: $e');
      return Err(e.toString());
    }
  }

  Future<Result<List<Examination>, String>> getAllExams(
    Map<String, dynamic> filter,
  ) async {
    try {
      final examService = await GetIt.I.getAsync<ExamService>();

      final result = await examService.getExams(filter: filter);

      
      if (result?["edges"] != null) {
        final examinations = Examination.listFromJson(result?['edges'] ?? []);
        notifyListeners();
        return Ok(examinations);
      } else {
        final errorMessage =
            result?['message'] ?? 'Failed to load examinations';
        notifyListeners();
        return Err(errorMessage);
      }
    } catch (e) {
      print('Error fetching examinations: $e');
      // _isLoading = false;
      // _errorMessage = e.toString();
      notifyListeners();
      return Err(e.toString());
    }
  }

  // Future<Result<Examination> updateExam(Map<String, dynamic> filter) async {
  //   try {
  //     final examService = await GetIt.I.getAsync<ExamService>();

  //     final result = await examService.updateExam(filter: filter);

  //     print(result);
  //     if (result?["edges"] != null) {
  //         final examinations =  Examination.listFromJson(result?['edges'] ?? []);
  //       notifyListeners();
  //       return Ok(examinations);
  //     } else {
  //       final errorMessage = result?['message'] ?? 'Failed to load examinations';
  //       notifyListeners();
  //       return Err(errorMessage);
  //     }
  //   } catch (e) {
  //     print('Error fetching examinations: $e');
  //     // _isLoading = false;
  //     // _errorMessage = e.toString();
  //     notifyListeners();
  //     return Err(e.toString());
  //   }
  // }

  Future<Result<bool, String>> submitExam(
    String studentExamId,
    List<SubmitAnswerInput> selectedAnswers,
  ) async {
    try {
      final studentExamService = await GetIt.I.getAsync<StudentExamService>();
      final result = await studentExamService.submitExam(
        studentExamId: studentExamId,
        answers: selectedAnswers.map((ans) => ans.toJson()).toList(),
      );

      // The result should contain the submitted StudentExam data
      if (result != null && result['id'] != null) {
        return Ok(true);
      } else {
        return Err('Submission failed - no data returned');
      }
    } catch (error) {
      print('Error submitting exam: $error');
      return Err("Failed to submit exam: $error");
    }
  }

  Future<Result<List<ExamQuestion>, String>> getExamQuestions() async {
    _questions = [];

    if (_currentExam == null) return Err("No Exam selected");

    try {
      final questionService = await GetIt.I.getAsync<QuestionService>();

      final result = await questionService.getExamQuestions(
        examId: _currentExam!.id,
      );

      print(result);
      if (result?["edges"] != null) {
        _questions = ExamQuestion.listFromJson(result?['edges'] ?? []);
        notifyListeners();
        return Ok(_questions);
      } else {
        _errorMessage =
            result?['message'] ?? 'Failed to load examination questions';
        notifyListeners();
        return Err(_errorMessage);
      }
    } catch (e) {
      print('Error fetching examination question: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return Err(_errorMessage);
    }
  }

  Future<List<Examination>> createExam({
    required String title,
    String? description,
    required String subjectId,
    required String gradeId,
    required int duration,
    double? passmark,
    bool? shuffleQuestions,
    bool? allowReview,
    bool? showResults,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
  }) async {
    // Set loading state at the beginning
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final examService = await GetIt.I.getAsync<ExamService>();

      print("title: $title");
      final result = await examService.createExam(
        title: title,
        description: description,
        subjectId: subjectId,
        gradeId: gradeId,
        duration: duration,
        passmark: passmark,
        shuffleQuestions: shuffleQuestions,
        allowReview: allowReview,
        showResults: showResults,
        startDate: startDate,
        endDate: endDate,
        instructions: instructions,
      );

      // print('Create exam result: $result');

      _isLoading = false;

      if (result != null) {
        // Assuming the created exam is returned in result['data']
        // You might need to adjust this based on your API response structure
        final newExam = Examination.fromJson(result);
        _examinations.add(newExam);
        notifyListeners();
        return [newExam];
      } else {
        _errorMessage = result?['message'] ?? 'Failed to create examination';
        notifyListeners();
        return [];
      }
    } catch (e) {
      print('Error creating examination: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return [];
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
    _examinations = [];
    _questions = [];
    notifyListeners();
  }
}
