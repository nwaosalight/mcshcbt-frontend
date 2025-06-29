import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:mcsh_cbt/services/studentservice.dart';
import 'package:mcsh_cbt/theme.dart';

class ExamResultDashboard extends StatefulWidget {
  final String? studentId; 

  const ExamResultDashboard({
    super.key,
    this.studentId,
  });

  @override
  State<ExamResultDashboard> createState() => _ExamResultDashboardState();
}

class _ExamResultDashboardState extends State<ExamResultDashboard> {
  
  List<Map<String, dynamic>> _examResults = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExamResults();
  }

  Future<void> _loadExamResults() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final StudentExamService examService = await GetIt.I.getAsync<StudentExamService>();

      // Fetch exam results using studentExams query
      final result = await examService.getStudentExams(
        filter: widget.studentId != null ? {'studentId': widget.studentId} : null,
        pagination: {'first': 10}, // Fetch first 10 results
      );

      if (result != null && result['edges'] != null) {
        setState(() {
          _examResults = (result['edges'] as List<dynamic>)
              .map((edge) => edge['node'] as Map<String, dynamic>)
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No exam results found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }

    print(_errorMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results'),
        backgroundColor: AppColors.darkPurple,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkPurple),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading results',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.red,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadExamResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPurple,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_examResults.isEmpty) {
      return const Center(
        child: Text('No exam results found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExamResults,
      color: AppColors.darkPurple,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _examResults.length,
        itemBuilder: (context, index) {
          final examResult = _examResults[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildResultCard(examResult),
          );
        },
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> examResult) {
    final exam = examResult['exam'] as Map<String, dynamic>?;
    final isPassed = examResult['isPassed'] as bool? ?? false;
    final score = (examResult['score'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetailedReview(examResult),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultHeader(examResult),
              const SizedBox(height: 16),
              _buildScoreCard(examResult),
              const SizedBox(height: 16),
              _buildExamDetails(examResult),
              const SizedBox(height: 16),
              _buildPerformanceMetrics(examResult),
              const SizedBox(height: 16),
              _buildTimeStatistics(examResult),
              const SizedBox(height: 16),
              _buildActionButtons(examResult),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader(Map<String, dynamic> examResult) {
    final exam = examResult['exam'] as Map<String, dynamic>?;
    final isPassed = examResult['isPassed'] as bool? ?? false;
    final score = (examResult['score'] as num?)?.toDouble() ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPassed
              ? [Colors.green.shade400, Colors.green.shade600]
              : [AppColors.red.withOpacity(0.8), AppColors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.cancel,
            color: AppColors.white,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            isPassed ? 'Congratulations!' : 'Better Luck Next Time',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            exam?['title']?.toString() ?? 'Exam',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withOpacity(0.9),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Your Score: ',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.white.withOpacity(0.9),
                    ),
              ),
              Text(
                '${score.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(Map<String, dynamic> examResult) {
    final score = (examResult['score'] as num?)?.toDouble() ?? 0.0;
    final isPassed = examResult['isPassed'] as bool? ?? false;
    final exam = examResult['exam'] as Map<String, dynamic>?;
    final passmark = (exam?['passmark'] as num?)?.toDouble() ?? 50.0;

    return Column(
      children: [
        Text(
          'Score Breakdown',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildScoreItem(
                'Your Score',
                '${score.toStringAsFixed(1)}%',
                isPassed ? Colors.green : AppColors.red,
              ),
            ),
            Expanded(
              child: _buildScoreItem(
                'Pass Mark',
                '${passmark.toStringAsFixed(1)}%',
                AppColors.darkPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            isPassed ? Colors.green : AppColors.red,
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          isPassed ? 'PASSED' : 'FAILED',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isPassed ? Colors.green : AppColors.red,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.darkGrey,
              ),
        ),
      ],
    );
  }

  Widget _buildExamDetails(Map<String, dynamic> examResult) {
    final exam = examResult['exam'] as Map<String, dynamic>?;
    final startTime = examResult['startTime'] as String?;
    final endTime = examResult['endTime'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exam Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Exam Title', exam?['title']?.toString() ?? 'N/A'),
        _buildDetailRow('Description', exam?['description']?.toString() ?? 'N/A'),
        _buildDetailRow('Duration', '${exam?['duration']?.toString() ?? '0'} minutes'),
        _buildDetailRow('Total Questions', exam?['questionCount']?.toString() ?? '0'),
        _buildDetailRow('Total Points', exam?['totalPoints']?.toString() ?? '0'),
        if (startTime != null)
          _buildDetailRow('Started At', _formatDateTime(startTime)),
        if (endTime != null)
          _buildDetailRow('Completed At', _formatDateTime(endTime)),
        _buildDetailRow('Status', examResult['status']?.toString() ?? 'N/A'),
      ],
    );
  }

  Widget _buildPerformanceMetrics(Map<String, dynamic> examResult) {
    final answeredCount = (examResult['answeredCount'] as num?)?.toInt() ?? 0;
    final markedCount = (examResult['markedCount'] as num?)?.toInt() ?? 0;
    final exam = examResult['exam'] as Map<String, dynamic>?;
    final totalQuestions = (exam?['questionCount'] as num?)?.toInt() ?? 0;
    final unansweredCount = totalQuestions - answeredCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Answered',
                answeredCount.toString(),
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Marked',
                markedCount.toString(),
                Colors.orange,
                Icons.flag,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Unanswered',
                unansweredCount.toString(),
                AppColors.red,
                Icons.help_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.darkGrey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStatistics(Map<String, dynamic> examResult) {
    final timeSpent = (examResult['timeSpent'] as num?)?.toInt() ?? 0;
    final exam = examResult['exam'] as Map<String, dynamic>?;
    final duration = (exam?['duration'] as num?)?.toInt() ?? 0;
    final remainingTime = (examResult['remainingTime'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Statistics',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTimeCard(
                'Time Spent',
                _formatDuration(timeSpent),
                AppColors.darkPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeCard(
                'Total Duration',
                _formatDuration(duration * 60), // Convert minutes to seconds
                AppColors.lightPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: duration > 0 ? (timeSpent / (duration * 60)) : 0,
          backgroundColor: Colors.grey.shade300,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.darkPurple),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          'Time Utilization: ${duration > 0 ? ((timeSpent / (duration * 60)) * 100).toStringAsFixed(1) : 0}%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.darkGrey,
              ),
        ),
      ],
    );
  }

  Widget _buildTimeCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.access_time, color: color, size: 28),


          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.darkGrey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGrey,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> examResult) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showDetailedReview(examResult),
            icon: const Icon(Icons.visibility),
            label: const Text('View Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkPurple,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _shareResults(examResult),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkPurple,
              side: const BorderSide(color: AppColors.darkPurple),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showDetailedReview(Map<String, dynamic> examResult) {
    // Placeholder for detailed review navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for exam: ${examResult['exam']['title']}'),
        backgroundColor: AppColors.darkPurple,
      ),
    );
  }

  void _shareResults(Map<String, dynamic> examResult) {
    // Placeholder for share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing results for exam: ${examResult['exam']['title']}'),
        backgroundColor: AppColors.darkPurple,
      ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }
}