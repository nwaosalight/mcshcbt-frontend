import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/models/question.dart';
import '../../../services/storage_service.dart';

class QuestionProvider with ChangeNotifier {
  List<Question> _questions = [];
  Map<String, List<Question>> _questionsBySubject = {};
  bool _isLoading = false;
  String _error = '';

  List<Question> get questions => _questions;
  Map<String, List<Question>> get questionsBySubject => _questionsBySubject;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadQuestions() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // In a real app, this would load from a database or API
      // Simulating a network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // For now we'll use hardcoded data
      // Later this could use StorageService to load from local storage

      // Reset the collections
      _questions = [];
      _questionsBySubject = {};

      // Load the questions and organize by subject
      _loadDummyData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load questions: $e';
      notifyListeners();
    }
  }

  void _loadDummyData() {
    // This would be replaced with actual data loading
    final mathQuestions = [
      Question(
        id: '1',
        question: 'What is 2 + 2?',
        options: ['3', '4', '5', '6'],
        correctOption: 1,
        subject: 'Mathematics',
        difficulty: 'Easy',
      ),
      Question(
        id: '2',
        question: 'What is the square root of 16?',
        options: ['2', '4', '8', '16'],
        correctOption: 1,
        subject: 'Mathematics',
        difficulty: 'Easy',
      ),
    ];

    final englishQuestions = [
      Question(
        id: '3',
        question: 'Which of these is a pronoun?',
        options: ['Run', 'She', 'Jump', 'Fast'],
        correctOption: 1,
        subject: 'English',
        difficulty: 'Easy',
      ),
    ];

    // Add all questions to the main list
    _questions = [...mathQuestions, ...englishQuestions];

    // Organize by subject
    _questionsBySubject = {
      'Mathematics': mathQuestions,
      'English': englishQuestions,
    };
  }

  Future<bool> addQuestion(Question question, List<File> images) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Generate a unique ID (in a real app this would come from the backend)
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      // Process images (in a real app this would upload to a server)
      List<String> imageUrls = [];

      if (images.isNotEmpty) {
        final storageService = StorageService();
        for (var image in images) {
          // Save image to local storage and get path
          // final imagePath = await storageService.saveImage(
          //   image,
          //   'question_${id}_${imageUrls.length}',
          // );
          // imageUrls.add(imagePath);
        }
      }

      // Create the new question with the ID and image URLs
      final newQuestion = Question(
        id: id,
        question: question.question,
        options: question.options,
        correctOption: question.correctOption,
        subject: question.subject,
        difficulty: question.difficulty,
        imageUrls: imageUrls,
      );

      // Add to lists
      _questions.add(newQuestion);

      // Update the subject map
      if (!_questionsBySubject.containsKey(newQuestion.subject)) {
        _questionsBySubject[newQuestion.subject] = [];
      }
      _questionsBySubject[newQuestion.subject]!.add(newQuestion);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to add question: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuestion(Question question, List<File> newImages) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Find the question index
      final index = _questions.indexWhere((q) => q.id == question.id);
      if (index == -1) {
        throw Exception('Question not found');
      }

      // Process new images
      List<String> imageUrls = List.from(question.imageUrls);

      if (newImages.isNotEmpty) {
        final storageService = StorageService();
        for (var image in newImages) {
          // Save image to local storage and get path
          // final imagePath = await storageService.saveImage(
          //   image,
          //   'question_${question.id}_${imageUrls.length}',
          // );
          // imageUrls.add(imagePath);
        }
      }

      // Create updated question
      final updatedQuestion = Question(
        id: question.id,
        question: question.question,
        options: question.options,
        correctOption: question.correctOption,
        subject: question.subject,
        difficulty: question.difficulty,
        imageUrls: imageUrls,
      );

      // Update in main list
      _questions[index] = updatedQuestion;

      // Update in subject map - first remove from old subject if changed
      final oldQuestion = _questions[index];
      if (oldQuestion.subject != updatedQuestion.subject) {
        _questionsBySubject[oldQuestion.subject]?.removeWhere(
          (q) => q.id == updatedQuestion.id,
        );

        // Add to new subject
        if (!_questionsBySubject.containsKey(updatedQuestion.subject)) {
          _questionsBySubject[updatedQuestion.subject] = [];
        }
      } else {
        // Update in current subject
        final subjectIndex = _questionsBySubject[updatedQuestion.subject]!
            .indexWhere((q) => q.id == updatedQuestion.id);
        if (subjectIndex != -1) {
          _questionsBySubject[updatedQuestion.subject]![subjectIndex] =
              updatedQuestion;
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to update question: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteQuestion(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Find the question
      final question = _questions.firstWhere((q) => q.id == id);

      // Remove from main list
      _questions.removeWhere((q) => q.id == id);

      // Remove from subject map
      _questionsBySubject[question.subject]?.removeWhere((q) => q.id == id);

      // If the subject is now empty, remove it
      if (_questionsBySubject[question.subject]?.isEmpty ?? false) {
        _questionsBySubject.remove(question.subject);
      }

      // Delete images
      if (question.imageUrls.isNotEmpty) {
        final storageService = StorageService();
        for (var imageUrl in question.imageUrls) {
          // await storageService.deleteImage(imageUrl);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to delete question: $e';
      notifyListeners();
      return false;
    }
  }

  List<String> getSubjects() {
    return _questionsBySubject.keys.toList();
  }

  int getQuestionCountBySubject(String subject) {
    return _questionsBySubject[subject]?.length ?? 0;
  }
}
