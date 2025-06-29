import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../theme.dart';

class ExamResultsScreen extends StatelessWidget {
  final Exam exam;
  final String studentId;
  final Duration timeSpent;
  final int answeredQuestions;
  final int markedQuestions;

  const ExamResultsScreen({
    super.key,
    required this.exam,
    required this.studentId,
    required this.timeSpent,
    required this.answeredQuestions,
    required this.markedQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final unansweredQuestions = exam.questionLen - answeredQuestions;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Submission'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lightBlue,
              AppColors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 800,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.darkPurple,
                      size: 72,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Exam Submitted Successfully',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thank you for completing the ${exam.subject} examination.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    
                    // Results Summary Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Summary',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkPurple,
                              ),
                            ),
                            const Divider(height: 32),
                            _buildSummaryItem('Subject', exam.subject),
                            _buildSummaryItem('Student ID', studentId),
                            _buildSummaryItem(
                              'Time Spent', 
                              '${timeSpent.inHours}h ${timeSpent.inMinutes.remainder(60)}m ${timeSpent.inSeconds.remainder(60)}s'
                            ),
                            const Divider(height: 32),
                            _buildSummaryItem(
                              'Questions Answered', 
                              '$answeredQuestions/${exam.questionLen}',
                              valueColor: answeredQuestions == exam.questionLen ? Colors.green : Colors.orange,
                            ),
                            _buildSummaryItem(
                              'Questions Unanswered', 
                              '$unansweredQuestions/${exam.questionLen}',
                              valueColor: unansweredQuestions == 0 ? Colors.green : Colors.orange,
                            ),
                            _buildSummaryItem(
                              'Questions Marked for Review', 
                              '$markedQuestions/${exam.questionLen}',
                            ),
                            const Divider(height: 32),
                            const Center(
                              child: Text(
                                'Your results will be available soon.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Back to Home Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkPurple,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Return to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
} 