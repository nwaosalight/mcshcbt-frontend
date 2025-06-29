import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:mcsh_cbt/core/models/result.dart';
import 'package:mcsh_cbt/features/exam/models/examination.dart';
import 'package:mcsh_cbt/features/subject/models/exam_question.dart';
import 'package:mcsh_cbt/features/subject/models/subject.dart';
import 'package:mcsh_cbt/services/examservice.dart';
import 'package:mcsh_cbt/services/questionservice.dart';
import 'package:mcsh_cbt/services/subjectservice.dart';

class SubjectProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = "";
  String get errorMessage => _errorMessage;

  List<Subject> _subjects = [];
  List<Subject> get subjects => _subjects;

  List<Examination> _subjectExams = [];
  List<Examination> get subjectExams => _subjectExams;

  List<ExamQuestion> _questions = [];
  List<ExamQuestion> get question => _questions;

  Subject? _selectedSubject;
  Subject? get selectedSubject => _selectedSubject;

  Examination? _selectedExam;
  Examination? get selectedExam => _selectedExam;

  ExamQuestion? _selectedExamQuestion;
  ExamQuestion? get selectedExamQuestion => _selectedExamQuestion;

  Future<bool> getSubjects() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final subjectService = await GetIt.I.getAsync<SubjectService>();
      final result = await subjectService.getSubjects();

      _isLoading = false;

      print(result);

      if (result?["edges"] != null) {
        _subjects = Subject.listFromJson(result?['edges'] ?? []);
        notifyListeners();
        return true;
      } else {
        _errorMessage = result?['message'] ?? 'Failed to load subjects';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error fetching subjects: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> selectSubject(Subject subject) async {
    _selectedSubject = subject;
    notifyListeners();
  }

  Future<void> selectExam(Examination exam) async {
    _selectedExam = exam;
    notifyListeners();
  }

  void selectExamQuestion(ExamQuestion question)  {
    _selectedExamQuestion = question;
    notifyListeners();
  }

  Future<List<Examination>> getSubjectExams(String subjectId) async {
    _isLoading = true;
    _errorMessage = '';
    _subjectExams = [];
    // notifyListeners();

    try {
      final examService = await GetIt.I.getAsync<ExamService>();
      // Pass the subjectId parameter to filter exams by subject
      final result = await examService.getExams(
        filter: {"subjectId": subjectId},
      );

      print(result?["edges"]);

      _isLoading = false;

      if (result?["edges"] != null) {
        _subjectExams = Examination.listFromJson(result?['edges'] ?? []);

        notifyListeners();
        return _subjectExams;
      } else {
        _errorMessage = result?['message'] ?? 'Failed to load examinations';
        notifyListeners();
        return [];
      }
    } catch (e) {
      print('Error fetching examinations: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<ExamQuestion>> getSubjectExamQuestions(String examId) async {
    print("examId");

    // _isLoading = true;
    _errorMessage = '';
    _questions = [];
    // notifyListeners();

    try {
      final qservices = await GetIt.I.getAsync<QuestionService>();
      // Pass the subjectId parameter to filter exams by subject
      final result = await qservices.getExamQuestions(examId: examId);

      print(result?["edges"]);

      _isLoading = false;

      if (result?["edges"] != null) {
        _questions = ExamQuestion.listFromJson(result?['edges'] ?? []);
        print(_questions[0].options);
        notifyListeners();
        return _questions;
      } else {
        _errorMessage = result?['message'] ?? 'Failed to load examinations';
        notifyListeners();
        return [];
      }
    } catch (e) {
      print('Error fetching examinations: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<ExamQuestion?> updateExamQuestion(
    {int? questionNumber, String? text, String? questionType, List<Map<String, dynamic>>? opts, String? correctAnswer,
    double? points, String? difficultyLevel, List<String>? tags, String? feedback, String? image,
  }) async {
    // return [];

    // _isLoading = true;
    _errorMessage = '';
    _questions = [];
    // notifyListeners();

    try {
      final qservices = await GetIt.I.getAsync<QuestionService>();
      // Pass the subjectId parameter to filter exams by subject

      if (_selectedExam == null) return null ;
      if (_selectedExamQuestion == null) return null;
      final result = await qservices.updateQuestion(
        id: _selectedExamQuestion!.id,
        text: text, 
        opts: opts,
        correctAnswer: correctAnswer, 
        image: image
      );

      print("Result");
      print(result);


      // getSubjectExamQuestions(_selectedExam!.id);
    

      _isLoading = false;

      if (result != null) {
           return  ExamQuestion.fromJson(result) ;
      } else {
        _errorMessage = result?['message'] ?? 'Failed to load examinations';
        notifyListeners();
        return null;
      }
    } catch (e) {
      print('Error fetching examinations: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }


  Future<Result<ExamQuestion, String>> addExamQuestion(
    { required int questionNumber, required String text, String? questionType, required List<Map<String, dynamic>> opts, required String correctAnswer,
    double? points, String? difficultyLevel, List<String>? tags, String? feedback, String? image,
  }) async {
    // return [];

    // _isLoading = true;
    // _errorMessage = '';
    // _questions = [];
    // notifyListeners();

    try {
      final qservices = await GetIt.I.getAsync<QuestionService>();
      // Pass the subjectId parameter to filter exams by subject

      if (_selectedExam == null) return Err("Exam not selected");
      // if (_selectedExamQuestion == null) return   Err("Question not selected");
      final result = await qservices.createQuestion(
       examId:  _selectedExam!.id,
        text: text, 
        opts: opts,
        correctAnswer: correctAnswer, 
        image: image, 
        questionNumber: questionNumber  , 
        questionType: 'MULTIPLE_CHOICE'
      );


      // getSubjectExamQuestions(_selectedExam!.id);
    

      _isLoading = false;

      if (result != null) {
           return  Ok(ExamQuestion.fromJson(result)) ;
      } else {
        _errorMessage = result?['message'] ?? 'Failed to load examinations';
        return Err(_errorMessage);
        // notifyListeners();
        // return null;
      }
    } catch (e) {
      print('Error fetching examinations: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      return Err(_errorMessage);
      // notifyListeners();
      // return null;
    }
  }
  Future<bool> deleteExamQuestion(String id) async {
   
    _errorMessage = '';
    notifyListeners();

    try {
      final qservices = await GetIt.I.getAsync<QuestionService>();
      // Pass the subjectId parameter to filter exams by subject

      if (_selectedExam == null) return false ;
      if (_selectedExamQuestion == null) return false;
      final result = await qservices.deleteQuestion(id);

      _isLoading = false;

      if (result ) {
          return true;
      } else {
        _errorMessage = "Failed to delete question";
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error fetching examinations: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
