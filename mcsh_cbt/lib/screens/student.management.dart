import 'package:flutter/material.dart';
import 'package:mcsh_cbt/theme.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:mcsh_cbt/core/models/result.dart';
import 'package:mcsh_cbt/features/exam/models/userconnection.dart';
import 'package:mcsh_cbt/features/exam/models/gradeconnection.dart';
import 'package:mcsh_cbt/services/gradeservice.dart';
import 'package:mcsh_cbt/services/userservice.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Services
  late GradeService _gradeService;
  late UserService _userService;
  
  // State variables
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Data
  List<UserNode> _students = [];
  List<UserNode> _pendingStudents = [];
  List<Grade> _grades = [];
  
  // Selected values
  String? _selectedGradeId;
  UserNode? _selectedStudent;
  
  // Form controllers
  final _searchController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
    _loadInitialData();
  }

  Future<void> _initializeServices() async {
    _gradeService = await GetIt.I.getAsync<GradeService>();
    _userService = await GetIt.I.getAsync<UserService>();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadStudents(),
      _loadPendingStudents(),
      _loadGrades(),
    ]);
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final result = await _userService.getUsers(filter: {"role": "STUDENT", "status": "APPROVED"});
      if (result?["edges"] != null) {
        setState(() {
          _students = UserNode.listFromJson(result!['edges']);
        });
      }
    } catch (e) {
      _showError('Failed to load students: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingStudents() async {
    try {
      final result = await _userService.getUsers(filter: {"role": "STUDENT", "status": "PENDING"});
      if (result?["edges"] != null) {
        setState(() {
          _pendingStudents = UserNode.listFromJson(result!['edges']);
        });
      }
    } catch (e) {
      _showError('Failed to load pending students: $e');
    }
  }

  Future<void> _loadGrades() async {
    try {
      final result = await _gradeService.getGrades();
      if (result?["edges"] != null) {
        setState(() {
          final gradeConnection = GradeConnection.fromJson(result!);
          _grades = gradeConnection.edges.map((edge) => edge.node).toList();
        });
      }
    } catch (e) {
      _showError('Failed to load grades: $e');
    }
  }

  Future<void> _enrollStudent(String studentId, String gradeId) async {
    setState(() => _isLoading = true);
    try {
      final success = await _gradeService.enrollStudent(
        studentId: studentId,
        gradeId: gradeId,
      );
      
      if (success) {
        _showSuccess('Student enrolled successfully!');
        await _loadStudents(); // Refresh the list
      } else {
        _showError('Failed to enroll student');
      }
    } catch (e) {
      _showError('Error enrolling student: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveStudent(String studentId) async {
    setState(() => _isLoading = true);
    try {
      final result = await _userService.updateUser(
        id: studentId,
        status: "APPROVED",
      );
      
      if (result != null) {
        _showSuccess('Student approved successfully!');
        await Future.wait([_loadStudents(), _loadPendingStudents()]);
      } else {
        _showError('Failed to approve student');
      }
    } catch (e) {
      _showError('Error approving student: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectStudent(String studentId) async {
    setState(() => _isLoading = true);
    try {
      final success = await _userService.deleteUser(studentId);
      
      if (success) {
        _showSuccess('Student rejected successfully!');
        await _loadPendingStudents();
      } else {
        _showError('Failed to reject student');
      }
    } catch (e) {
      _showError('Error rejecting student: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStudentProfile(UserNode student) async {
    setState(() => _isLoading = true);
    try {
      final result = await _userService.updateUser(
        id: student.id,
        firstName: _firstNameController.text.isNotEmpty ? _firstNameController.text : null,
        lastName: _lastNameController.text.isNotEmpty ? _lastNameController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );
      
      if (result != null) {
        _showSuccess('Student profile updated successfully!');
        await _loadStudents();
        Navigator.of(context).pop();
      } else {
        _showError('Failed to update student profile');
      }
    } catch (e) {
      _showError('Error updating student profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showEnrollDialog(UserNode student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enroll ${student.firstName} ${student.lastName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Grade:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGradeId,
              decoration: const InputDecoration(
                labelText: 'Grade',
                border: OutlineInputBorder(),
              ),
              items: _grades.map((grade) {
                return DropdownMenuItem(
                  value: grade.id,
                  child: Text(grade.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedGradeId = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _selectedGradeId != null
                ? () {
                    Navigator.of(context).pop();
                    _enrollStudent(student.id, _selectedGradeId!);
                  }
                : null,
            child: const Text('Enroll'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(UserNode student) {
    _firstNameController.text = student.firstName;
    _lastNameController.text = student.lastName;
    _emailController.text = student.email;
    _phoneController.text = student.phoneNumber ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${student.firstName} ${student.lastName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateStudentProfile(student),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(UserNode student, {bool isPending = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.darkPurple,
          child: Text(
            '${student.firstName[0]}${student.lastName[0]}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('${student.firstName} ${student.lastName}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.email),
            if (student.phoneNumber != null) Text('Phone: ${student.phoneNumber}'),
            if (student.grade != null) Text('Grade: ${student.grade!.name}'),
          ],
        ),
        trailing: isPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approveStudent(student.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _rejectStudent(student.id),
                  ),
                ],
              )
            : PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Profile'),
                  ),
                  const PopupMenuItem(
                    value: 'enroll',
                    child: Text('Enroll to Grade'),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditDialog(student);
                      break;
                    case 'enroll':
                      _showEnrollDialog(student);
                      break;
                  }
                },
              ),
      ),
    );
  }

  Widget _buildStudentsTab() {
    List<UserNode> filteredStudents = _students;
    
    if (_searchController.text.isNotEmpty) {
      filteredStudents = _students.where((student) {
        final searchLower = _searchController.text.toLowerCase();
        return student.firstName.toLowerCase().contains(searchLower) ||
               student.lastName.toLowerCase().contains(searchLower) ||
               student.email.toLowerCase().contains(searchLower);
      }).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search Students',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredStudents.isEmpty
                  ? const Center(child: Text('No students found'))
                  : ListView.builder(
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        return _buildStudentCard(filteredStudents[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPendingTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _pendingStudents.isEmpty
            ? const Center(child: Text('No pending approvals'))
            : ListView.builder(
                itemCount: _pendingStudents.length,
                itemBuilder: (context, index) {
                  return _buildStudentCard(_pendingStudents[index], isPending: true);
                },
              );
  }

  Widget _buildStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Statistics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Total Students', _students.length.toString()),
                      _buildStatCard('Pending Approval', _pendingStudents.length.toString()),
                      _buildStatCard('Total Grades', _grades.length.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Students by Grade',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ..._grades.map((grade) {
                    final studentsInGrade = _students.where((student) => 
                        student.grade?.id == grade.id).length;
                    return ListTile(
                      title: Text(grade.name),
                      trailing: Text('$studentsInGrade students'),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.darkPurple,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.darkGrey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.darkPurple,
        title: const Text('Student Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Students', icon: Icon(Icons.people)),
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentsTab(),
          _buildPendingTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}