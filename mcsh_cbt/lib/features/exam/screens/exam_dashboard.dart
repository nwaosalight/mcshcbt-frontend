import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mcsh_cbt/core/models/result.dart';
import 'package:mcsh_cbt/features/exam/providers/exam.provider.dart';
import 'package:mcsh_cbt/services/storage_service.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../features/exam/models/examination.dart';

class ExamDashboard extends StatefulWidget {
  const ExamDashboard({super.key});

  @override
  State<ExamDashboard> createState() => _ExamDashboardState();
}

class _ExamDashboardState extends State<ExamDashboard> {
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get the current user's grade ID from AuthProvider
      // final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // final gradeId = authProvider.currentUser?.gradeId ?? '';

      final storageService = await GetIt.I.getAsync<StorageService>();
      final gradeId =  storageService.readString("gradeId");

      print('gradeId: $gradeId');

      if (gradeId == null || gradeId.isEmpty) {

        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load upcoming exams
      final examProvider = Provider.of<ExamProvider>(context, listen: false);
      final result = await examProvider.getSubjectExams(gradeId, 'PUBLISHED');
 

      setState(() {
        _isLoading = false;
        if (result is Err) {
          _errorMessage = (result as Err).error;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load exams: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<AuthProvider>(context).username;

    final examProvider = Provider.of<ExamProvider>(context);
    final exams = examProvider.examinations;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              context.goNamed('login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, AppColors.background],
          ),
        ),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? _buildErrorView()
                : RefreshIndicator(
                  onRefresh: _loadExams,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Welcome section
                      Card(
                        elevation: 6,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Welcome, $userName',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: Colors.white24,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Your upcoming exams are listed below',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _buildInfoBox(
                                      title:
                                          exams
                                              .where(
                                                (e) =>
                                                    e.status ==
                                                        ExamStatus.published &&
                                                    e.attemptStatus ==
                                                        ExamAttemptStatus
                                                            .notStarted,
                                              )
                                              .length
                                              .toString(),
                                      subtitle: 'Upcoming Exams',
                                      icon: Icons.event_note,
                                      color: Colors.white24,
                                    ),
                                    const SizedBox(width: 16),
                                    _buildInfoBox(
                                      title:
                                          exams
                                              .where(
                                                (e) =>
                                                    e.attemptStatus ==
                                                    ExamAttemptStatus.completed,
                                              )
                                              .length
                                              .toString(),
                                      subtitle: 'Completed',
                                      icon: Icons.task_alt,
                                      color: Colors.white24,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Exam section title
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 16),
                        child: Row(
                          children: [
                            const Text(
                              'Your Exams',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 2,
                              width: 30,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),

                      // ...exams.map(_buildExamCard).toList(),
                      ...exams.map((e) => _buildExamCard(e)).toList(),

                      if (exams.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_note,
                                size: 80,
                                color: AppColors.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No exams available',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'When exams are scheduled, they will appear here',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadExams,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reload'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error loading exams',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadExams,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(Examination exam) {
    final bool isCompleted = exam.attemptStatus == ExamAttemptStatus.completed;

    final provider = Provider.of<ExamProvider>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getSubjectColor("TODO:").withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSubjectIcon('TODO:'),
                    color: _getSubjectColor('TODO'),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildExamDetailChip(
                            icon: Icons.subject,
                            label: 'TODO',
                            color: AppColors.primary.withOpacity(0.1),
                            textColor: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _buildExamDetailChip(
                            icon: Icons.timer,
                            label: '${exam.duration} mins',
                            color: AppColors.secondary.withOpacity(0.1),
                            textColor: AppColors.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildExamDetailChip(
                            icon: Icons.quiz,
                            label: '${exam.questionCount} questions',
                            color: AppColors.secondary.withOpacity(0.1),
                            textColor: AppColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          // if (isCompleted && exam. != null)
                          //   _buildExamDetailChip(
                          //     icon: Icons.assessment,
                          //     label: '${exam.score}%',
                          //     color: _getScoreColor(
                          //       exam.score ?? 0,
                          //     ).withOpacity(0.1),
                          //     textColor: _getScoreColor(exam.score ?? 0),
                          //   ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.event_available : Icons.event,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(exam.startDate ?? DateTime.now()),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight:
                            isCompleted ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                  ElevatedButton.icon(
                    onPressed: () {
                      provider.selectCurrentExam(exam);
                      context.goNamed('exam', extra: exam);
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start Exam'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamDetailChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return AppColors.primary;
      case 'english':
        return AppColors.secondary;
      case 'science':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate;
      case 'english':
        return Icons.book;
      case 'science':
        return Icons.science;
      default:
        return Icons.subject;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber.shade800;
    return Colors.red;
  }
}