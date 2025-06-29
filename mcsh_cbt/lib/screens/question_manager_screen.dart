import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fleather/fleather.dart';
import 'package:mcsh_cbt/features/subject/models/exam_question.dart';
import 'package:mcsh_cbt/features/subject/providers/subject_provider.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../models/exam.dart';
import '../models/question.dart';
import 'question_creator_screen.dart';

class QuestionManagerScreen extends StatefulWidget {
  final String subject;
  final List<ExamQuestion> initialQuestions;
  final Function(List<ExamQuestion>) onSave;
  final String? examId; // Add examId parameter

  const QuestionManagerScreen({
    super.key,
    required this.subject,
    required this.initialQuestions,
    required this.onSave,
    this.examId, // Optional examId
  });

  @override
  State<QuestionManagerScreen> createState() => _QuestionManagerScreenState();
}

class _QuestionManagerScreenState extends State<QuestionManagerScreen> {
  late List<ExamQuestion> _questions;
  bool _isModified = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.initialQuestions);
    // Do not call _fetchQuestions here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch questions after dependencies are available
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    if (!mounted) return; // Prevent operations if widget is disposed

    setState(() {
      _isLoading = true;
    });

    try {
      final subjectProvider = Provider.of<SubjectProvider>(
        context,
        listen: false,
      );

      // Check if we have an examId and need to set the selected exam
      if (widget.examId != null &&
          subjectProvider.selectedExam?.id != widget.examId) {
        // Find the exam in the provider's subject exams list
        final exam = subjectProvider.subjectExams.firstWhere(
          (exam) => exam.id == widget.examId,
          orElse: () => throw Exception('Exam not found'),
        );

        // Set the selected exam
        await subjectProvider.selectExam(exam);
        print("Selected exam set: ${exam.id}");
      }

      // Now check if we have a selected exam
      if (subjectProvider.selectedExam == null) {
        print("No exam selected - cannot fetch questions");
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No exam selected. Please select an exam first.'),
              backgroundColor: AppColors.red,
            ),
          );
        }
        return;
      }

      print("Fetching questions for exam: ${subjectProvider.selectedExam!.id}");
      if (subjectProvider.selectedExam == null) return;
      final fetchedQuestions = await subjectProvider.getSubjectExamQuestions(
        subjectProvider.selectedExam!.id,
      );

      if (mounted) {
        setState(() {
          _questions = fetchedQuestions;
          _isLoading = false;
        });
      }

      print("Fetched ${fetchedQuestions.length} questions");
    } catch (e) {
      print("Error in _fetchQuestions: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch questions: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshQuestions() async {
    await _fetchQuestions();
  }

  void _addQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuestionCreatorScreen(
              subject: widget.subject,
              onQuestionCreated: (question) async {
                // Question creation is handled in the QuestionCreatorScreen
                // This callback is called when the question is successfully created
                print("Question created callback - refreshing questions");

                // Refresh the questions list to show the new question
                await _refreshQuestions();

                // Mark as modified
                setState(() {
                  _isModified = true;
                });
              },
            ),
      ),
    ).then((_) {
      // Also refresh when returning to this screen
      // This handles cases where the callback might not work properly
      print("Returned from question creator - refreshing");
      _refreshQuestions();
    });
  }

  void _editQuestion(int index) {
    final provider = Provider.of<SubjectProvider>(context, listen: false);

    provider.selectExamQuestion(_questions[index]);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuestionCreatorScreen(
              subject: widget.subject,
              questionToEdit: _questions[index],
              onQuestionCreated: (question) async {
                // Question editing is handled in the QuestionCreatorScreen
                // This callback is called when the question is successfully updated
                print("Question updated callback - refreshing questions");

                // Refresh the questions list to show the updated question
                await _refreshQuestions();

                // Mark as modified
                setState(() {
                  _isModified = true;
                });
              },
            ),
      ),
    ).then((_) {
      // Also refresh when returning to this screen
      // This handles cases where the callback might not work properly
      print("Returned from question editor - refreshing");
      _refreshQuestions();
    });
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Question'),
            content: const Text(
              'Are you sure you want to delete this question?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    final provider = Provider.of<SubjectProvider>(
                      context,
                      listen: false,
                    );
                    final success = await provider.deleteExamQuestion(
                      _questions[index].id,
                    );

                    if (success) {
                      await _refreshQuestions();

                      setState(() {
                        _isModified = true;
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Question deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.errorMessage),
                            backgroundColor: AppColors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete question: $e'),
                          backgroundColor: AppColors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _saveChanges() async {
    // Save changes logic here
    widget.onSave(_questions);
    setState(() {
      _isModified = false;
    });
  }

  void _previewImage(String imagePath) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: const Text('Image Preview'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Flexible(
                  child:
                      imagePath.startsWith('http')
                          ? Image.network(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.red[300],
                                      size: 64,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Failed to load image'),
                                  ],
                                ),
                              );
                            },
                          )
                          : Image.file(
                            File(imagePath),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.red[300],
                                      size: 64,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Failed to load image'),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }

  void _previewExam() {
    final exam = Exam(
      subject: widget.subject,
      questionLen: _questions.length,
      questions: List.from(_questions),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${widget.subject} Preview'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Questions: ${_questions.length}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Questions Preview:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q${index + 1}: ${question.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Use rich text rendering for question text
                            SizedBox(
                              height: 100,
                              child: _buildQuestionText(question.text),
                            ),
                            if (question.image != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.image,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'image attached',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        if (question.image != null) {
                                          _previewImage(question.image ?? "");
                                        }
                                      },
                                      child: const Text('View'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildImagePreview(String imagePath) {
    return GestureDetector(
      onTap: () => _previewImage(imagePath),
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
              imagePath.startsWith('http')
                  ? Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.red[300],
                          size: 24,
                        ),
                      );
                    },
                  )
                  : Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.red[300],
                          size: 24,
                        ),
                      );
                    },
                  ),
        ),
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

  // Helper method to create controller from plain text
  FleatherController _createControllerFromPlainText(String text) {
    final document = ParchmentDocument();
    if (text.isNotEmpty) {
      document.insert(0, text);
    }
    return FleatherController(document: document);
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: FleatherTheme(
            data: FleatherThemeData(
              paragraph: TextBlockTheme(
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black,
                ),
                spacing: const VerticalSpacing(top: 0, bottom: 8),
              ),
              heading1: TextBlockTheme(
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.3,
                ),
                spacing: const VerticalSpacing(top: 12, bottom: 6),
              ),
              heading2: TextBlockTheme(
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.3,
                ),
                spacing: const VerticalSpacing(top: 10, bottom: 4),
              ),
              heading3: TextBlockTheme(
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.3,
                ),
                spacing: const VerticalSpacing(top: 8, bottom: 4),
              ),
              lists: TextBlockTheme(
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  height: 1.4,
                ),
                spacing: const VerticalSpacing(top: 0, bottom: 6),
              ),
              quote: TextBlockTheme(
                style: const TextStyle(
                  fontSize: 16,
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
                  fontSize: 14,
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
                color: Colors.black,
              ),
              italic: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black,
              ),
              underline: const TextStyle(
                decoration: TextDecoration.underline,
                color: Colors.black,
              ),
              strikethrough: const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.black,
              ),
              link: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              inlineCode: InlineCodeThemeData(
                backgroundColor: Colors.grey.shade200,
                radius: const Radius.circular(4),
                style: const TextStyle(
                  fontSize: 14,
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
        return Text(
          questionText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        );
      }
    } catch (e) {
      // If parsing fails, fall back to plain text
      return Text(
        questionText,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject} Questions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Questions',
            onPressed: _isLoading ? null : _refreshQuestions,
          ),
          IconButton(
            icon: const Icon(Icons.remove_red_eye),
            tooltip: 'Preview Exam',
            onPressed: _questions.isNotEmpty ? _previewExam : null,
          ),
          IconButton(
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save),
            tooltip: 'Save Changes',
            onPressed: _isModified && !_isLoading ? _saveChanges : null,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addQuestion,
        backgroundColor: _isLoading ? Colors.grey : AppColors.darkPurple,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.lightBlue, AppColors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Info bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkPurple,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.subject,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Consumer<SubjectProvider>(
                      builder: (context, subjectProvider, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_questions.length} Questions',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (subjectProvider.selectedExam != null)
                              Text(
                                'Exam: ${subjectProvider.selectedExam!.id}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    if (_isModified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Unsaved Changes',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Question list or empty state
              Expanded(
                child:
                    _isLoading
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.darkPurple,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading questions...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                        : _questions.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                          onRefresh: _refreshQuestions,
                          color: AppColors.darkPurple,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _questions.length,
                            itemBuilder: (context, index) {
                              final question = _questions[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Question number and controls
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.darkPurple,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Q${index + 1}',
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: AppColors.darkPurple,
                                            ),
                                            onPressed:
                                                () => _editQuestion(index),
                                            tooltip: 'Edit Question',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: AppColors.red,
                                            ),
                                            onPressed:
                                                () => _deleteQuestion(index),
                                            tooltip: 'Delete Question',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Question text
                                      _buildQuestionText(question.text),

                                      // Image preview
                                      if (question.image != null) ...[
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          height: 60,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: [question.image].length,
                                            itemBuilder: (context, imageIndex) {
                                              final images = [
                                                question.image ?? "",
                                              ];
                                              return _buildImagePreview(
                                                images[imageIndex],
                                              );
                                            },
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 16),

                                      // Options
                                      ...question.options.asMap().entries.map((
                                        entry,
                                      ) {
                                        final optionIndex = entry.key;
                                        final optionMap = entry.value;

                                        final optionKey = optionMap.keys.first;
                                        final optionText =
                                            optionMap.values.first;

                                        final isCorrect =
                                            optionKey == question.correctAnswer;
                                        final optionLetter =
                                            optionKey.toUpperCase();

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                isCorrect
                                                    ? AppColors.darkPurple
                                                        .withOpacity(0.1)
                                                    : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isCorrect
                                                      ? AppColors.darkPurple
                                                      : Colors.grey.withOpacity(
                                                        0.3,
                                                      ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      isCorrect
                                                          ? AppColors.darkPurple
                                                          : Colors.grey[300],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    optionLetter,
                                                    style: TextStyle(
                                                      color:
                                                          isCorrect
                                                              ? AppColors.white
                                                              : Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(optionText)),
                                              if (isCorrect)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'Correct',
                                                    style: TextStyle(
                                                      color: AppColors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.question_mark, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Questions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add your first question',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _addQuestion,
            icon: const Icon(Icons.add),
            label: const Text('Add Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLoading ? Colors.grey : AppColors.darkPurple,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
