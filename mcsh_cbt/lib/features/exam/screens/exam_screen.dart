import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/app_theme.dart';
import '../../../core/models/question.dart';
import '../../../core/providers/auth_provider.dart';
import '../../question/providers/question_provider.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  String _examId = '';
  Map<String, dynamic> _examData = {};
  List<Question> _questions = [];
  Map<int, int> _userAnswers = {};
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _showSubmitDialog = false;
  bool _isSubmitting = false;

  // Timer
  late Timer _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeExam();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _initializeExam() async {
    // Get exam ID from route parameters
    final params = GoRouterState.of(context).uri.queryParameters;
    if (params.containsKey('examId')) {
      setState(() {
        _examId = params['examId']!;
      });
      await _loadExamData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid exam')));
        context.goNamed('examDashboard');
      }
    }
  }

  Future<void> _loadExamData() async {
    try {
      // In a real app, this would load from an API
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock exam data
      final examData = {
        'id': _examId,
        'title':
            _examId == '1'
                ? 'Mathematics Term Examination'
                : _examId == '2'
                ? 'English Language Test'
                : 'General Exam',
        'subject':
            _examId == '1'
                ? 'Mathematics'
                : _examId == '2'
                ? 'English'
                : 'General',
        'duration': _examId == '1' ? 45 : 60,
        'totalQuestions': _examId == '1' ? 20 : 25,
        'instructions':
            'Read each question carefully. Choose the best answer from the options provided. You have limited time to complete this exam.',
      };

      // Load questions
      await Provider.of<QuestionProvider>(
        context,
        listen: false,
      ).loadQuestions();
      final questions =
          Provider.of<QuestionProvider>(context, listen: false).questions;

      // Limit questions to match exam requirements
      final limitedQuestions =
          questions.take(examData['totalQuestions'] as int).toList();

      setState(() {
        _examData = examData;
        _questions = limitedQuestions;
        _remainingSeconds = (examData['duration'] as int) * 60;
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading exam: $e')));
        context.goNamed('examDashboard');
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer.cancel();
          _submitExam();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _selectAnswer(int questionIndex, int answerIndex) {
    setState(() {
      _userAnswers[questionIndex] = answerIndex;
    });
  }

  void _showConfirmSubmitDialog() {
    final unansweredCount = _questions.length - _userAnswers.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Submit Exam'),
            content:
                unansweredCount > 0
                    ? Text(
                      'You have $unansweredCount unanswered questions. Are you sure you want to submit?',
                    )
                    : const Text('Are you sure you want to submit your exam?'),
            actions: [
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitExam,
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('SUBMIT'),
              ),
            ],
          ),
    );
  }

  Future<void> _submitExam() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Close submit dialog if shown
      if (_showSubmitDialog && mounted) {
        Navigator.of(context).pop();
      }

      // Cancel timer
      _timer.cancel();

      // Calculate score (in a real app, this would be done on the server)
      int correctAnswers = 0;

      for (int i = 0; i < _questions.length; i++) {
        if (_userAnswers[i] == _questions[i].correctOption) {
          correctAnswers++;
        }
      }

      final score = (correctAnswers / _questions.length * 100).round();

      // Simulate API call to save results
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Navigate to results screen
      context.goNamed(
        'examResults',
        queryParameters: {
          'examId': _examId,
          'score': score.toString(),
          'correctAnswers': correctAnswers.toString(),
          'totalQuestions': _questions.length.toString(),
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting exam: $e')));
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];
    final userAnswer = _userAnswers[index];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Question ${index + 1}/${_questions.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(question.difficulty),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    question.difficulty,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (question.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: question.imageUrls.length,
                  itemBuilder: (context, imgIndex) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          question.imageUrls[imgIndex],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            ...List.generate(
              question.options.length,
              (i) => RadioListTile<int>(
                title: Text(question.options[i]),
                value: i,
                groupValue: userAnswer,
                onChanged: (value) => _selectAnswer(index, value!),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton.icon(
                    onPressed: _previousQuestion,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('PREVIOUS'),
                  )
                else
                  const SizedBox(),
                if (_currentQuestionIndex < _questions.length - 1)
                  ElevatedButton.icon(
                    onPressed: _nextQuestion,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('NEXT'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _showConfirmSubmitDialog,
                    icon: const Icon(Icons.check),
                    label: const Text('SUBMIT'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _userAnswers.length / _questions.length,
            backgroundColor: Colors.grey.shade200,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            '${_userAnswers.length}/${_questions.length} questions answered',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Loading Exam...' : _examData['title']),
        actions: [
          if (!_isLoading)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _remainingSeconds < 300 ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade100,
                    child: Row(
                      children: [
                        Expanded(child: _buildProgressIndicator()),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _showConfirmSubmitDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('SUBMIT'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [_buildQuestionCard(_currentQuestionIndex)],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: _previousQuestion,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text('PREVIOUS'),
                        ),
                        Text(
                          '${_currentQuestionIndex + 1}/${_questions.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton(
                          onPressed:
                              _currentQuestionIndex < _questions.length - 1
                                  ? _nextQuestion
                                  : _showConfirmSubmitDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: Text(
                            _currentQuestionIndex < _questions.length - 1
                                ? 'NEXT'
                                : 'SUBMIT',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
