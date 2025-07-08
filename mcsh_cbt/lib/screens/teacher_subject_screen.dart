import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mcsh_cbt/features/subject/providers/subject_provider.dart';
import 'package:mcsh_cbt/features/subject/models/subject.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../data/dummy_data.dart';
import '../models/question.dart';
import '../models/exam.dart';
import 'question_manager_screen.dart';

class TeacherSubjectScreen extends StatefulWidget {
  const TeacherSubjectScreen({super.key});

  @override
  State<TeacherSubjectScreen> createState() => _TeacherSubjectScreenState();
}

class _TeacherSubjectScreenState extends State<TeacherSubjectScreen> {
  final _subjectController = TextEditingController();
  final _subjectcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Fetch subjects when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubjects();
    });
  }

  Future<void> _fetchSubjects() async {
    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
    await subjectProvider.getSubjects();
    setState(() {
      _isInitialized = true;
    });
  }
  
  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addSubject() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: 'Enter subject name',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectcodeController,
              decoration: const InputDecoration(
                hintText: 'Enter subject a code',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Enter brief description',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final subject = _subjectController.text.trim();
              final description = _descriptionController.text.trim();
              final code = _subjectcodeController.text.trim();
              
              if (subject.isNotEmpty) {
                // TODO: Implement add subject with description via provider
                // This would need to be updated in the Subject model and provider
                _subjectController.clear();
                _descriptionController.clear();
                _subjectcodeController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading subjects',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchSubjects,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkPurple,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsGrid(List<Subject> subjects) {
    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
    if (subjects.isEmpty) {
      return const Center(
        child: Text(
          'No subjects available.\nAdd a subject to get started.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,  // Adjusted to make cards taller
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        
        // Get question count for this subject
        int questionCount = 0;
        try {
          final existingExam = DummyData.exams.firstWhere(
            (exam) => exam.subject == subject.name,
          );
          questionCount = existingExam.questionLen;
        } catch (e) {
          // No exam found, count remains 0
        }
        
        // Get description (assuming it's part of the Subject model)
        // If not available in model, use placeholder description
        String description = subject.description ??  _getDefaultDescription(subject.name);
        
        return InkWell(
          onTap: ()  {
            subjectProvider.selectSubject(subject);
            context.pushNamed("subjectExams");
          },
          borderRadius: BorderRadius.circular(12),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getSubjectIcon(subject.name),
                    size: 36,
                    color: AppColors.darkPurple,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subject.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                   Text(
                    "GRADE: ${subject.gradeName}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$questionCount questions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDefaultDescription(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return 'Numbers, algebra, geometry, and mathematical concepts';
      case 'english':
        return 'Language arts, reading comprehension, and writing skills';
      case 'science':
        return 'Study of natural world, physics, chemistry, and biology';
      case 'social studies':
        return 'History, geography, cultures, and civic education';
      case 'computer science':
        return 'Programming, algorithms, and digital technology';
      default:
        return 'Course materials and assessment questions';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.goNamed("roleSelection");
            },
          ),

        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        backgroundColor: AppColors.darkPurple,
        child: const Icon(Icons.add),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a Subject',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkPurple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a subject to create or edit exam questions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                
                Expanded(
                  child: Consumer<SubjectProvider>(
                    builder: (context, subjectProvider, _) {
                      if (!_isInitialized && subjectProvider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.darkPurple,
                          ),
                        );
                      }
                      
                      if (subjectProvider.errorMessage.isNotEmpty) {
                        return _buildErrorView(subjectProvider.errorMessage);
                      }
                      
                      return _buildSubjectsGrid(subjectProvider.subjects);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate;
      case 'english':
        return Icons.menu_book;
      case 'science':
        return Icons.science;
      case 'social studies':
        return Icons.public;
      case 'computer science':
        return Icons.computer;
      default:
        return Icons.school;
    }
  }
}