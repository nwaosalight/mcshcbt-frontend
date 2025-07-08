import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mcsh_cbt/features/exam/models/examination.dart';
import 'package:mcsh_cbt/features/subject/models/exam_question.dart';
import 'package:mcsh_cbt/features/subject/providers/subject_provider.dart';
import 'package:mcsh_cbt/screens/question_manager_screen.dart';
import 'package:provider/provider.dart';
import '../theme.dart';

class SubjectExaminationsScreen extends StatefulWidget {

  const SubjectExaminationsScreen({
    super.key,
    
  });

  @override
  State<SubjectExaminationsScreen> createState() => _SubjectExaminationsScreenState();
}

class _SubjectExaminationsScreenState extends State<SubjectExaminationsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<Examination> _examinations = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchExaminations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchExaminations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
      if (subjectProvider.selectedSubject == null) return;
      final exams = await subjectProvider.getSubjectExams(subjectProvider.selectedSubject!.id);
      
      setState(() {
        _examinations = exams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load examinations: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Examination> get _filteredExaminations {
    if (_searchQuery.isEmpty) return _examinations;
    
    return _examinations.where((exam) => 
      exam.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (exam.description != null && exam.description!.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();
  }

  void _navigateToQuestions(String subject, Examination exam ) async{
    List<ExamQuestion> questions = [];
 
    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
    await subjectProvider.selectExam(exam);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionManagerScreen(
          subject: subject,
          initialQuestions: questions,
          onSave: (updatedQuestions) {
            // final examIndex = DummyData.exams.indexWhere(
            //   (exam) => exam.subject == subject
            // );
            
            // if (examIndex != -1) {
            //   DummyData.exams[examIndex] = DummyData.exams[examIndex].copyWith(
            //     questions: updatedQuestions,
            //     questionLen: updatedQuestions.length,
            //   );
            // } else {
            //   DummyData.exams.add(
            //     Exam(
            //       subject: subject,
            //       questionLen: questionCount,
            //       questions: updatedQuestions,
            //     ),
            //   );
            // }
          },
        ),
      ),
    );
  }

  void _navigateToExamDetails(Examination exam) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${exam.title}')),
    );

    _navigateToQuestions(exam.title, exam);
  }
  
  void _createNewExam() {
    context.pushNamed("createExam");
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('Creating new examination')),
    // );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}';
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading examinations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchExaminations,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPurple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(Examination exam, [bool isGridView = false]) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToExamDetails(exam),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isGridView ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                    decoration: BoxDecoration(
                      color: AppColors.darkPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assignment,
                      color: AppColors.darkPurple,
                      size: isSmallScreen ? 20 : 28,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: isGridView ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (exam.description != null && exam.description!.isNotEmpty && (!isGridView || screenWidth > 600))
                          Text(
                            exam.description!,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.grey[700],
                            ),
                            maxLines: isGridView ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        
                        Wrap(
                          spacing: isSmallScreen ? 6 : 12,
                          runSpacing: isSmallScreen ? 4 : 8,
                          children: [
                            _buildDetailChip(
                              Icons.timer,
                              _formatDuration(exam.duration),
                              isSmallScreen,
                            ),
                            if (!isGridView || screenWidth > 800)
                              _buildDetailChip(
                                Icons.calendar_today,
                                dateFormat.format(exam.createdAt),
                                isSmallScreen,
                              ),
                          ],
                        ),
                        
                        if (!isGridView || screenWidth > 500)
                          Column(
                            children: [
                              SizedBox(height: isSmallScreen ? 4 : 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: isSmallScreen ? 12 : 16,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: isSmallScreen ? 2 : 4),
                                  Text(
                                    'Created by Admin',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 4
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 12 : 14,
            color: Colors.grey[700],
          ),
          SizedBox(width: isSmallScreen ? 2 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 360 ? 48.0 : 64.0;

    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth < 360 ? 16 : 24),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: iconSize,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No examinations yet',
                style: TextStyle(
                  fontSize: screenWidth < 360 ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first examination for ${subjectProvider.selectedSubject?.name}',
                style: TextStyle(
                  fontSize: screenWidth < 360 ? 14 : 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createNewExam,
                icon: const Icon(Icons.add),
                label: const Text('Create Examination'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPurple,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth < 360 ? 16 : 24,
                    vertical: screenWidth < 360 ? 10 : 12
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);

    return AppBar(
      title: _isSearching
        ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search examinations...',
              border: InputBorder.none,
            ),
            style: const TextStyle(color: Colors.black),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          )
        : Text('${subjectProvider.selectedSubject?.subjectCode} Examinations'),
      centerTitle: false,
      titleSpacing: _isSearching ? 0 : null,
      leading: _isSearching
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          )
        : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {             
              setState(() {
                _isSearching = true;
              });
            },
          ),
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
          IconButton(onPressed: _fetchExaminations, icon: Icon(Icons.refresh_outlined))
      ],
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filter Examinations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildFilterSection(
                          title: 'Duration',
                          children: [
                            _buildFilterChip('Under 30 min'),
                            _buildFilterChip('30-60 min'),
                            _buildFilterChip('Over 60 min'),
                          ],
                        ),
                        const Divider(height: 32),
                        _buildFilterSection(
                          title: 'Created Date',
                          children: [
                            _buildFilterChip('Last 7 days'),
                            _buildFilterChip('Last 30 days'),
                            _buildFilterChip('Older'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkPurple,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: children,
        )
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = false;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        // TODO: Implement filter logic
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.darkPurple.withOpacity(0.2),
      checkmarkColor: AppColors.darkPurple,
      side: isSelected
        ? BorderSide(color: AppColors.darkPurple)
        : BorderSide(color: Colors.grey[300]!),
    );
  }

  Widget _buildExaminationsContent() {
    return _isLoading
      ? const Center(
          child: CircularProgressIndicator(
            color: AppColors.darkPurple,
          ),
        )
      : _errorMessage.isNotEmpty
        ? _buildErrorView()
        : _examinations.isEmpty
          ? _buildEmptyState()
          : _filteredExaminations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No results found for "$_searchQuery"',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return ListView.builder(
                      itemCount: _filteredExaminations.length,
                      itemBuilder: (context, index) {
                        return _buildExamCard(_filteredExaminations[index]);
                      },
                    );
                  } else {
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 800 ? 2 : 1),
                        childAspectRatio: constraints.maxWidth > 1100 ? 2.0 : (constraints.maxWidth > 800 ? 2.2 : 2.5),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _filteredExaminations.length,
                      itemBuilder: (context, index) {
                        return _buildExamCard(_filteredExaminations[index], true);
                      },
                    );
                  }
                },
              );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = screenSize.width < 360 ? 12.0 : 16.0;

    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
    
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        floatingActionButton: FloatingActionButton(
          onPressed: _createNewExam,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, horizontalPadding, horizontalPadding, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Examinations',
                        style: TextStyle(
                          fontSize: screenSize.width < 360 ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage all examinations for ${subjectProvider.selectedSubject?.subjectCode}',
                        style: TextStyle(
                          fontSize: screenSize.width < 360 ? 14 : 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: _buildExaminationsContent(), 
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}