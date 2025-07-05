import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fleather/fleather.dart';
import 'package:mcsh_cbt/core/models/result.dart';
import 'package:mcsh_cbt/features/exam/models/selected.answer.dart';
import 'package:mcsh_cbt/features/exam/providers/exam.provider.dart';
import 'package:mcsh_cbt/features/subject/models/exam_question.dart';
import 'package:provider/provider.dart';

import '../theme.dart';

class ExamScreen extends StatefulWidget {
  final int? examDurationMinutes; // Add exam duration parameter
  
  const ExamScreen({Key? key, this.examDurationMinutes}) : super(key: key);

  @override
  _ExamScreenState createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  Future<Result<List<ExamQuestion>, String>>? _questionsFuture;
  List<ExamQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  Map<String, String?> _answers = {};
  bool _isSubmitting = false;
  final PageController _pageController = PageController();

  // Timer related variables
  Timer? _examTimer;
  late Duration _remainingTime;
  bool _isTimerActive = false;
  bool _timeWarningShown = false;

  @override
  void initState() {
    super.initState();
    // Initialize timer duration (default to 60 minutes if not provided)
    final durationMinutes = widget.examDurationMinutes ?? 60;
    _remainingTime = Duration(minutes: durationMinutes);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_questionsFuture == null) {
      _questionsFuture = getExamQuestions();
      _loadQuestions();
    }
  }

  Future<Result<List<ExamQuestion>, String>> getExamQuestions() {
    final provider = Provider.of<ExamProvider>(context, listen: false);
    return provider.getExamQuestions();
  }

  void _loadQuestions() async {
    final result = await _questionsFuture!;
    if (result.isOk()) {
      setState(() {
        _questions = result.unwrap();
        _answers = {for (var question in _questions) question.id: null};
      });
      _startTimer(); // Start timer after questions are loaded
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load questions: ${result.unwrapErr()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  void _startTimer() {
    if (_isTimerActive) return;
    
    _isTimerActive = true;
    _examTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        _timeUp();
      } else {
        setState(() {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        });
        
        // Show warning when 5 minutes left
        if (_remainingTime.inMinutes == 5 && !_timeWarningShown) {
          _showTimeWarning();
        }
      }
    });
  }

  void _showTimeWarning() {
    _timeWarningShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Time Warning', style: TextStyle(color: Colors.orange)),
          ],
        ),
        content: Text('You have 5 minutes remaining. Please complete your exam soon.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _timeUp() {
    _examTimer?.cancel();
    _isTimerActive = false;
    
    if (!_isSubmitting) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.access_time, color: AppColors.red),
              SizedBox(width: 8),
              Text('Time Up!', style: TextStyle(color: AppColors.red)),
            ],
          ),
          content: Text('Your exam time has elapsed. Your answers will be submitted automatically.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _submitExam(isAutoSubmit: true);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _selectAnswer(String answer) {
    setState(() {
      _answers[_questions[_currentQuestionIndex].id] = answer;
    });
  }

  void _goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitExam({bool isAutoSubmit = false}) async {
    final provider = Provider.of<ExamProvider>(context, listen: false);

    setState(() => _isSubmitting = true);
    _examTimer?.cancel(); // Stop the timer

    try {
      final studentExams = await provider.getStudentExam();
      if (studentExams.isErr()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(studentExams.unwrapErr()))
          );
        }
        return;
      }

      final studentExam = studentExams.unwrap()[0];

      final submitAnswers = _answers.entries
          .map((entry) => SubmitAnswerInput(
                studentExamId: studentExam['id'],
                questionId: entry.key,
                selectedAnswer: entry.value,
              ))
          .toList();

      final result = await provider.submitExam(studentExam["id"], submitAnswers);

      if (result.isOk()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAutoSubmit 
                ? 'Exam submitted automatically due to time limit!' 
                : 'Exam submitted successfully!'),
              backgroundColor: isAutoSubmit ? Colors.orange : Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await Future.delayed(Duration(milliseconds: 500));
          context.goNamed("login");
        }
      } else {
        if (mounted) {
          if (result.unwrapErr() == 'Failed to submit exam: Exception: This exam has already been submitted') {
             ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logging out... Exam already submitted'),
              backgroundColor: AppColors.darkPurple,
            ),
          );
            context.goNamed("login");
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Submission failed: ${result.unwrapErr()}'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Submit Exam', style: TextStyle(color: AppColors.darkPurple)),
        content: Text('Are you sure you want to submit your answers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.darkGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkPurple),
            onPressed: () {
              Navigator.of(context).pop();
              _submitExam();
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Color _getTimerColor() {
    if (_remainingTime.inMinutes <= 5) {
      return AppColors.red;
    } else if (_remainingTime.inMinutes <= 15) {
      return Colors.orange;
    }
    return Colors.green;
  }

  Widget _buildTimerWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getTimerColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getTimerColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: _getTimerColor(), size: 16),
          SizedBox(width: 4),
          Text(
            _formatTime(_remainingTime),
            style: TextStyle(
              color: _getTimerColor(),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to try parsing text as JSON
  dynamic _tryParseJson(String text) {
    try {
      return jsonDecode(text);
    } catch (e) {
      return null;
    }
  }

  // Helper method to render question text with rich formatting
  Widget _buildQuestionText(String questionText) {
    try {
      // First try to parse as JSON (for rich text)
      final json = _tryParseJson(questionText);
      if (json != null) {
        final document = ParchmentDocument.fromJson(json);
        final controller = FleatherController(document: document);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.lightPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightPurple.withOpacity(0.3)),
          ),
          child: FleatherTheme(
            data: FleatherThemeData(
              paragraph: TextBlockTheme(
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.w600,
                ),
                spacing: const VerticalSpacing(top: 0, bottom: 8),
              ),
              heading1: TextBlockTheme(
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                  height: 1.3,
                ),
                spacing: const VerticalSpacing(top: 12, bottom: 6),
              ),
              heading2: TextBlockTheme(
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                  height: 1.3,
                ),
                spacing: const VerticalSpacing(top: 10, bottom: 4),
              ),
              heading3: TextBlockTheme(
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                  height: 1.3,
                ),
                spacing: const VerticalSpacing(top: 8, bottom: 4),
              ),
              lists: TextBlockTheme(
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.darkGrey,
                  height: 1.4,
                ),
                spacing: const VerticalSpacing(top: 0, bottom: 6),
              ),
              quote: TextBlockTheme(
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                spacing: const VerticalSpacing(top: 8, bottom: 6),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(width: 4, color: Colors.grey.shade400),
                  ),
                ),
              ),
              code: TextBlockTheme(
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'monospace',
                  backgroundColor: Colors.grey.shade100,
                  height: 1.3,
                ),
                spacing: const VerticalSpacing(top: 8, bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              bold: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
              ),
              italic: const TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.darkGrey,
              ),
              underline: const TextStyle(
                decoration: TextDecoration.underline,
                color: AppColors.darkGrey,
              ),
              strikethrough: const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: AppColors.darkGrey,
              ),
              link: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              inlineCode: InlineCodeThemeData(
                backgroundColor: Colors.grey.shade200,
                radius: const Radius.circular(4),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'monospace',
                ),
              ),
              heading4: TextBlockTheme(
                style: const TextStyle(fontSize: 20),
                spacing: VerticalSpacing.zero(),
              ),
              heading5: TextBlockTheme(
                style: const TextStyle(fontSize: 18),
                spacing: VerticalSpacing.zero(),
              ),
              heading6: TextBlockTheme(
                style: const TextStyle(fontSize: 16),
                spacing: VerticalSpacing.zero(),
              ),
              horizontalRule: HorizontalRuleThemeData(
                height: 10,
                thickness: 2,
                color: Colors.black54,
              ),
            ),
            child: FleatherEditor(
              controller: controller,
              readOnly: true,
              scrollable: false,
              expands: false,
              padding: const EdgeInsets.all(12),
            ),
          ),
        );
      } else {
        // If not JSON, treat as plain text
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightPurple.withOpacity(0.3)),
          ),
          child: Text(
            questionText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGrey,
            ),
          ),
        );
      }
    } catch (e) {
      // If parsing fails, fall back to plain text
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.lightPurple.withOpacity(0.3)),
        ),
        child: Text(
          questionText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGrey,
          ),
        ),
      );
    }
  }

  Widget _buildQuestionCard(ExamQuestion question) {
    final currentAnswer = _answers[question.id];

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionText(question.text),
          SizedBox(height: 20),
          if (question.image != null && question.image!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  question.image!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ...question.options.map((option) {
            final key = option.keys.first;
            final value = option.values.first;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: currentAnswer == key
                        ? AppColors.darkPurple
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _selectAnswer(key),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: currentAnswer == key
                                  ? AppColors.darkPurple
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: currentAnswer == key
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.darkPurple,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPaginationIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightPurple,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _currentQuestionIndex > 0 && !_isSubmitting
                    ? () => _goToQuestion(_currentQuestionIndex - 1)
                    : null,
                child: Text('Previous', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPurple,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: !_isSubmitting
                    ? (_currentQuestionIndex < _questions.length - 1
                        ? () => _goToQuestion(_currentQuestionIndex + 1)
                        : _showSubmitConfirmation)
                    : null,
                child: _isSubmitting &&
                        _currentQuestionIndex == _questions.length - 1
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        _currentQuestionIndex < _questions.length - 1
                            ? 'Next'
                            : 'Submit',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_questions.length, (index) {
                final isAnswered = _answers[_questions[index].id] != null;
                return GestureDetector(
                  onTap: !_isSubmitting ? () => _goToQuestion(index) : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isAnswered ? Colors.green : Colors.grey.shade200,
                      border: Border.all(
                        color: _currentQuestionIndex == index
                            ? AppColors.darkPurple
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAnswered
                              ? AppColors.white
                              : AppColors.darkGrey,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.darkPurple),
              ),
              SizedBox(height: 16),
              Text(
                'Submitting your exam...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGrey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait while we process your answers',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGrey.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Exam Questions', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.darkPurple,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isTimerActive)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: _buildTimerWidget()),
            ),
          if (_questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '${_currentQuestionIndex + 1}/${_questions.length}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<Result<List<ExamQuestion>, String>>(
            future: _questionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.darkPurple),
                  ),
                );
              }

              if (snapshot.hasError || snapshot.data?.isErr() == true) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Error loading questions',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        snapshot.data?.unwrapErr() ?? snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.darkGrey),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkPurple,
                        ),
                        onPressed: () {
                          setState(() {
                            _questionsFuture = getExamQuestions();
                          });
                          _loadQuestions();
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (_questions.isEmpty) {
                return Center(
                  child: Text(
                    'No questions available',
                    style: TextStyle(fontSize: 18, color: AppColors.darkGrey),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: _isSubmitting
                          ? NeverScrollableScrollPhysics()
                          : NeverScrollableScrollPhysics(),
                      itemCount: _questions.length,
                      onPageChanged: (index) {
                        setState(() => _currentQuestionIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return _buildQuestionCard(_questions[index]);
                      },
                    ),
                  ),
                  _buildPaginationIndicator(),
                ],
              );
            },
          ),
          // Loading overlay
          if (_isSubmitting) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _examTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}