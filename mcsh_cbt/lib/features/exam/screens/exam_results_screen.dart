import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/app_theme.dart';
import '../../../core/providers/auth_provider.dart';

class ExamResultsScreen extends StatefulWidget {
  const ExamResultsScreen({super.key});

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  String _examId = '';
  int _score = 0;
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  Map<String, dynamic> _examData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResultData();
    });
  }

  Future<void> _loadResultData() async {
    final params = GoRouterState.of(context).uri.queryParameters;

    if (params.containsKey('examId')) {
      setState(() {
        _examId = params['examId']!;
        _score = int.tryParse(params['score'] ?? '0') ?? 0;
        _correctAnswers = int.tryParse(params['correctAnswers'] ?? '0') ?? 0;
        _totalQuestions = int.tryParse(params['totalQuestions'] ?? '0') ?? 0;
      });

      await _loadExamData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid exam result')));
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
                : _examId == '3'
                ? 'Science Quiz'
                : 'General Exam',
        'subject':
            _examId == '1'
                ? 'Mathematics'
                : _examId == '2'
                ? 'English'
                : _examId == '3'
                ? 'Science'
                : 'General',
        'duration':
            _examId == '1'
                ? 45
                : _examId == '2'
                ? 60
                : 30,
        'date': DateTime.now(),
      };

      setState(() {
        _examData = examData;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading exam data: $e')));
      }
    }
  }

  String _getPerformanceText(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 70) return 'Very Good';
    if (score >= 60) return 'Good';
    if (score >= 50) return 'Average';
    if (score >= 40) return 'Below Average';
    return 'Poor';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber.shade800;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<AuthProvider>(context).username;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.goNamed('examDashboard'),
            tooltip: 'Go to Dashboard',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Score card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Text(
                              'Your Score',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 150,
                                  width: 150,
                                  child: CircularProgressIndicator(
                                    value: _score / 100,
                                    strokeWidth: 15,
                                    backgroundColor: Colors.grey.shade200,
                                    color: _getScoreColor(_score),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '$_score%',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: _getScoreColor(_score),
                                      ),
                                    ),
                                    Text(
                                      _getPerformanceText(_score),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    'Correct',
                                    _correctAnswers.toString(),
                                    Colors.green,
                                  ),
                                  _buildStatItem(
                                    'Incorrect',
                                    (_totalQuestions - _correctAnswers)
                                        .toString(),
                                    Colors.red,
                                  ),
                                  _buildStatItem(
                                    'Total',
                                    _totalQuestions.toString(),
                                    AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Exam details
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Exam Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailItem('Exam', _examData['title']),
                            _buildDetailItem('Subject', _examData['subject']),
                            _buildDetailItem(
                              'Duration',
                              '${_examData['duration']} minutes',
                            ),
                            _buildDetailItem('Student', userName),
                            _buildDetailItem(
                              'Date',
                              _formatDate(_examData['date']),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Feedback
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Feedback',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(_generateFeedback()),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // In a real app, this would download or share results
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Results downloaded'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('DOWNLOAD'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.goNamed('examDashboard'),
                            icon: const Icon(Icons.dashboard),
                            label: const Text('DASHBOARD'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _generateFeedback() {
    if (_score >= 80) {
      return 'Excellent work! You have demonstrated a strong understanding of the subject matter. Keep up the great work!';
    } else if (_score >= 60) {
      return 'Good job! You have shown a solid grasp of the material. With a bit more focus on certain areas, you can excel even further.';
    } else if (_score >= 40) {
      return 'You have shown some understanding of the material, but there is room for improvement. Consider reviewing the topics again and seeking additional help if needed.';
    } else {
      return 'It looks like you might be struggling with this subject. Don\'t worry - it\'s a learning process. Consider revisiting the material and seeking extra help from your teacher.';
    }
  }
}
