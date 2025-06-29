import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/question_provider.dart';

class TeacherSubjectScreen extends StatefulWidget {
  const TeacherSubjectScreen({super.key});

  @override
  State<TeacherSubjectScreen> createState() => _TeacherSubjectScreenState();
}

class _TeacherSubjectScreenState extends State<TeacherSubjectScreen> {
  bool _isLoading = true;
  final _subjectController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final questionProvider = Provider.of<QuestionProvider>(
      context,
      listen: false,
    );
    setState(() {
      _isLoading = true;
    });

    await questionProvider.loadQuestions();

    setState(() {
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Subject'),
        content: Form(
          key: _formKey,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g. Mathematics',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject name';
                }
                return null;
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // In a real app, this would add a new subject to the database
                Navigator.of(ctx).pop();
                _subjectController.clear();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subject added successfully'),
                  ),
                );

                // Refresh subjects
                _loadSubjects();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _navigateToQuestionCreator(String subject) {
    context.goNamed('questionCreator', queryParameters: {'subject': subject});
  }

  void _navigateToQuestionManager(String subject) {
    context.goNamed('questionManager', queryParameters: {'subject': subject});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              context.goNamed('roleSelection');
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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search subjects...',
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Consumer<QuestionProvider>(
                        builder: (context, questionProvider, _) {
                          final allSubjects = questionProvider.questionsBySubject.keys.toList();
                          final filteredSubjects = _searchQuery.isEmpty
                              ? allSubjects
                              : allSubjects
                                  .where((subject) => subject.toLowerCase().contains(_searchQuery.toLowerCase()))
                                  .toList();

                          if (filteredSubjects.isEmpty) {
                            return _buildEmptyState(_searchQuery.isNotEmpty);
                          }

                          return _buildSubjectList(filteredSubjects, questionProvider);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: _showAddSubjectDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearchEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.subject, size: 70, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            isSearchEmpty ? 'No Subjects Available' : 'No Subjects Found',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearchEmpty ? 'Add a subject to get started' : 'Try a different search term',
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (!isSearchEmpty) const SizedBox(height: 24),
          if (!isSearchEmpty)
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          if (isSearchEmpty) const SizedBox(height: 24),
          if (isSearchEmpty)
            ElevatedButton.icon(
              onPressed: _showAddSubjectDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Subject'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectList(
    List<String> subjects,
    QuestionProvider questionProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subjects.length,
      itemBuilder: (ctx, index) {
        final subject = subjects[index];
        final questionCount =
            questionProvider.questionsBySubject[subject]?.length ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getSubjectIcon(subject),
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$questionCount question${questionCount != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _navigateToQuestionManager(subject),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View Questions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: BorderSide(color: AppColors.secondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToQuestionCreator(subject),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Question'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
      case 'history':
        return Icons.history_edu;
      case 'geography':
        return Icons.public;
      case 'art':
        return Icons.palette;
      case 'music':
        return Icons.music_note;
      case 'physical education':
        return Icons.fitness_center;
      default:
        return Icons.subject;
    }
  }
}