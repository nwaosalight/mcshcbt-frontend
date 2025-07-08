import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mcsh_cbt/features/exam/providers/user.provider.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:mcsh_cbt/core/models/result.dart';
import 'package:mcsh_cbt/features/exam/models/gradeconnection.dart';
import 'package:mcsh_cbt/features/exam/models/userconnection.dart';
import 'package:mcsh_cbt/features/subject/models/subject.dart';
import 'package:mcsh_cbt/services/userservice.dart';
import 'package:mcsh_cbt/services/gradeservice.dart';
import 'package:mcsh_cbt/services/subjectservice.dart';
import '../theme.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  State<TeacherManagementScreen> createState() =>
      _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen>
    with TickerProviderStateMixin {
  
  // Tab Controller
  late TabController _tabController;
  
  // Form Controllers
  final _gradeNameController = TextEditingController();
  final _gradeDescriptionController = TextEditingController();
  final _gradeAcademicYearController = TextEditingController();
  final _subjectNameController = TextEditingController();
  final _subjectDescriptionController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  final _searchController = TextEditingController();

  // Form Keys
  final _gradeFormKey = GlobalKey<FormState>();
  final _subjectFormKey = GlobalKey<FormState>();

  // State Variables
  String? selectedGradeId;
  String? selectedSubjectId;
  String? selectedTeacherIdForAssignment;
  String? selectedGradeIdForSubject; // New variable for subject creation
  bool _isProcessing = false;
  List<UserNode> _filteredTeachers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gradeNameController.dispose();
    _gradeDescriptionController.dispose();
    _gradeAcademicYearController.dispose();
    _subjectNameController.dispose();
    _subjectDescriptionController.dispose();
    _subjectCodeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.getUser(role: "TEACHER");
    await userProvider.getGrades();
    await userProvider.getSubjects();
    _filterTeachers();
  }

  void _filterTeachers() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final searchTerm = _searchController.text.toLowerCase();
    
    if (searchTerm.isEmpty) {
      _filteredTeachers = userProvider.teacher;
    } else {
      _filteredTeachers = userProvider.teacher.where((teacher) {
        return teacher.fullName.toLowerCase().contains(searchTerm) ||
               teacher.email.toLowerCase().contains(searchTerm);
      }).toList();
    }
    setState(() {});
  }

  // Success and Error Handlers
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // Teacher Management Methods
  Future<void> _approveTeacher(UserNode teacher) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final userService = await GetIt.I.getAsync<UserService>();
      final result = await userService.updateUser(
        id: teacher.id,
        role: "TEACHER",
      );

      if (result != null) {
        _showSuccess('${teacher.fullName} approved as TEACHER');
        _refreshData();
      }
    } catch (e) {
      _showError('Failed to approve teacher: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _assignGradeToTeacher() async {
    if (selectedTeacherIdForAssignment == null || selectedGradeId == null) {
      _showError('Please select both teacher and grade');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final gradeService = await GetIt.I.getAsync<GradeService>();
      
      final success = await gradeService.assignTeacher(
        teacherId: selectedTeacherIdForAssignment!,
        subjectIds: [selectedSubjectId!],
        gradeIds: [selectedGradeId!],
      );

      if (success) {
        _showSuccess('Grade assigned successfully');
        setState(() => selectedGradeId = null);
        _refreshData();
      } else {
        throw Exception('Assignment failed');
      }
    } catch (e) {
      _showError('Failed to assign grade: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _assignSubjectToTeacher() async {
    if (selectedTeacherIdForAssignment == null || selectedSubjectId == null) {
      _showError('Please select both teacher and subject');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final gradeService = await GetIt.I.getAsync<GradeService>();
      final success = await gradeService.assignTeacher(
        teacherId: selectedTeacherIdForAssignment!,
        gradeIds: [selectedGradeId!],
        subjectIds: [selectedSubjectId!],
      );

      if (success) {
        _showSuccess('Subject assigned successfully');
        setState(() => selectedSubjectId = null);
        _refreshData();
      } else {
        throw Exception('Assignment failed');
      }
    } catch (e) {
      _showError('Failed to assign subject: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Grade Creation Methods
  Future<void> _createGrade() async {
    if (!_gradeFormKey.currentState!.validate()) return;
    
    setState(() => _isProcessing = true);

    try {
      final gradeService = await GetIt.I.getAsync<GradeService>();
      final result = await gradeService.createGrade(
        name: _gradeNameController.text.trim(),
        description: _gradeDescriptionController.text.trim().isEmpty 
            ? null 
            : _gradeDescriptionController.text.trim(),
        academicYear: _gradeAcademicYearController.text.trim(),
      );

      if (result != null) {
        _showSuccess('Grade created successfully');
        _clearGradeForm();
        _refreshData();
      }
    } catch (e) {
      _showError('Failed to create grade: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _clearGradeForm() {
    _gradeNameController.clear();
    _gradeDescriptionController.clear();
    _gradeAcademicYearController.clear();
    _gradeFormKey.currentState?.reset();

    setState(() {
      selectedGradeIdForSubject = null;
    });
  }

  // Subject Creation Methods
  Future<void> _createSubject() async {
    if (!_subjectFormKey.currentState!.validate()) return;
    
    if (selectedGradeIdForSubject == null) {
      _showError('Please select a grade for the subject');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final subjectService = await GetIt.I.getAsync<SubjectService>();
      final result = await subjectService.createSubject(
        name: _subjectNameController.text.trim(),
        description: _subjectDescriptionController.text.trim(),
        subjectCode: _subjectCodeController.text.trim(),
        gradeId: selectedGradeIdForSubject!,
      );

      if (result != null) {
        _showSuccess('Subject created successfully');
        _clearSubjectForm();
        _refreshData();
      }
    } catch (e) {
      _showError('Failed to create subject: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _clearSubjectForm() {
    _subjectNameController.clear();
    _subjectDescriptionController.clear();
    _subjectCodeController.clear();
    selectedGradeIdForSubject = null;
    _subjectFormKey.currentState?.reset();
    setState(() {});
  }

  // UI Building Methods
  Widget _buildTeacherManagementTab() {
    final userProvider = Provider.of<UserProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assignment Section
          _buildAssignmentCard(userProvider),
          const SizedBox(height: 24),
          
          // Search Bar
          _buildSearchBar(),
          const SizedBox(height: 16),

          // Teachers List
          _buildTeachersList(),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(UserProvider userProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teacher Assignment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            const SizedBox(height: 16),

            // Teacher Selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Teacher',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              value: selectedTeacherIdForAssignment,
              items: userProvider.teacher
                  .where((teacher) => teacher.role == 'TEACHER')
                  .map((teacher) {
                    return DropdownMenuItem<String>(
                      value: teacher.id,
                      child: Text(teacher.fullName),
                    );
                  })
                  .toList(),
              onChanged: _isProcessing ? null : (value) {
                setState(() => selectedTeacherIdForAssignment = value);
              },
            ),

            const SizedBox(height: 16),

            // Grade Assignment Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Grade',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grade),
                    ),
                    value: selectedGradeId,
                    items: userProvider.grades?.edges.map((edge) {
                      return DropdownMenuItem<String>(
                        value: edge.node.id,
                        child: Text(edge.node.name),
                      );
                    }).toList(),
                    onChanged: _isProcessing ? null : (value) {
                      setState(() => selectedGradeId = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: (_isProcessing ||
                          selectedTeacherIdForAssignment == null ||
                          selectedGradeId == null)
                      ? null
                      : _assignGradeToTeacher,
                  icon: _isProcessing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.assignment_ind),
                  label: const Text('Assign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPurple,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Subject Assignment Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Subject',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.subject),
                    ),
                    value: selectedSubjectId,
                    items: userProvider.subject.map((subject) {
                      return DropdownMenuItem<String>(
                        value: subject.id,
                        child: Text(subject.name),
                      );
                    }).toList(),
                    onChanged: _isProcessing ? null : (value) {
                      setState(() => selectedSubjectId = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: (_isProcessing ||
                          selectedTeacherIdForAssignment == null ||
                          selectedSubjectId == null)
                      ? null
                      : _assignSubjectToTeacher,
                  icon: _isProcessing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.assignment),
                  label: const Text('Assign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPurple,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'Search Teachers',
        hintText: 'Search by name or email...',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => _filterTeachers(),
    );
  }

  Widget _buildTeachersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teachers (${_filteredTeachers.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkPurple,
          ),
        ),
        const SizedBox(height: 8),
        
        _filteredTeachers.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No teachers found'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredTeachers.length,
                itemBuilder: (context, index) {
                  final teacher = _filteredTeachers[index];
                  final needsApproval = teacher.role.isEmpty ||
                      teacher.role == 'null' ||
                      teacher.role != 'TEACHER';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: needsApproval ? Colors.orange : AppColors.lightBlue,
                        child: Text(
                          teacher.fullName.isNotEmpty
                              ? teacher.fullName.substring(0, 1).toUpperCase()
                              : 'T',
                          style: const TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        teacher.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(teacher.email),
                          const SizedBox(height: 4),
                          Text(
                            needsApproval ? 'Status: Pending Approval' : 'Status: ${teacher.role}',
                            style: TextStyle(
                              fontSize: 12,
                              color: needsApproval ? Colors.orange : AppColors.darkGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing: needsApproval
                          ? ElevatedButton.icon(
                              onPressed: _isProcessing ? null : () => _approveTeacher(teacher),
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: AppColors.white,
                              ),
                            )
                          : const Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 24,
                            ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildGradeCreationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _gradeFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Grade',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _gradeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Grade Name *',
                        hintText: 'e.g., Grade 10, Year 1',
                        prefixIcon: Icon(Icons.grade),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Grade name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _gradeDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional description for the grade',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _gradeAcademicYearController,
                      decoration: const InputDecoration(
                        labelText: 'Academic Year *',
                        hintText: 'e.g., 2024-2025',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Academic year is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _createGrade,
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.add),
                            label: const Text('Create Grade'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkPurple,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _clearGradeForm,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildExistingGradesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCreationTab() {
    final userProvider = Provider.of<UserProvider>(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _subjectFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Subject',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _subjectNameController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name *',
                        hintText: 'e.g., Mathematics, English Literature',
                        prefixIcon: Icon(Icons.subject),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Subject name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _subjectCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Code',
                        hintText: 'e.g., MATH101, ENG201',
                        prefixIcon: Icon(Icons.code),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _subjectDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional description for the subject',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Grade *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.grade),
                      ),
                      value: selectedGradeIdForSubject,
                      items: userProvider.grades?.edges.map((edge) {
                        return DropdownMenuItem<String>(
                          value: edge.node.id,
                          child: Text(edge.node.name),
                        );
                      }).toList(),
                      onChanged: _isProcessing ? null : (value) {
                        setState(() => selectedGradeIdForSubject = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a grade';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _createSubject,
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.add),
                            label: const Text('Create Subject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkPurple,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _clearSubjectForm,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildExistingSubjectsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingGradesList() {
    final userProvider = Provider.of<UserProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Existing Grades',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkPurple,
          ),
        ),
        const SizedBox(height: 8),
        
        userProvider.grades?.edges.isEmpty ?? true
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No grades found'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: userProvider.grades?.edges.length ?? 0,
                itemBuilder: (context, index) {
                  final grade = userProvider.grades!.edges[index].node;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.lightBlue,
                        child: Icon(Icons.grade, color: AppColors.darkPurple),
                      ),
                      title: Text(grade.name),
                      subtitle: Text(grade.academicYear),
                      trailing: grade.isActive
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.pause_circle, color: Colors.orange),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildExistingSubjectsList() {
    final userProvider = Provider.of<UserProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Existing Subjects',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkPurple,
          ),
        ),
        const SizedBox(height: 8),
        
        userProvider.subject.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No subjects found'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: userProvider.subject.length,
                itemBuilder: (context, index) {
                  final subject = userProvider.subject[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.lightBlue,
                        child: Icon(Icons.subject, color: AppColors.darkPurple),
                      ),
                      title: Text(subject.name),
                      subtitle: Text(subject.subjectCode),
                      trailing: subject.isActive
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.pause_circle, color: Colors.orange),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final userProvider = Provider.of<UserProvider>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkPurple,
            ),
          ),
          const SizedBox(height: 24),

          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Teachers',
                  userProvider.teacher.length.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Grades',
                  (userProvider.grades?.edges.length ?? 0).toString(),
                  Icons.grade,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Subjects',
                  userProvider.subject.length.toString(),
                  Icons.subject,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending Approvals',
                  userProvider.teacher.where((t) => t.role != 'TEACHER').length.toString(),
                  Icons.pending_actions,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkPurple,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.grade),
                  label: const Text('Create Grade'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPurple,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric( vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(2),
                  icon: const Icon(Icons.subject),
                  label: const Text('Create Subject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPurple,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _tabController.animateTo(0),
            icon: const Icon(Icons.person_add),
            label: const Text('Manage Teachers'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkPurple,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teacher Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.goNamed("roleSelection");
            },
          ),
        ],
        backgroundColor: AppColors.darkPurple,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.darkGrey,
          indicatorColor: AppColors.lightBlue,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Teachers'),
            Tab(icon: Icon(Icons.grade), text: 'Grades'),
            Tab(icon: Icon(Icons.subject), text: 'Subjects'),
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeacherManagementTab(),
          _buildGradeCreationTab(),
          _buildSubjectCreationTab(),
          _buildOverviewTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: AppColors.darkPurple,
        child: const Icon(Icons.refresh, color: AppColors.white),
      ),
    );
  }
}