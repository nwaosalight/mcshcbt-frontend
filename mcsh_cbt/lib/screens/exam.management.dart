import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:mcsh_cbt/services/examservice.dart';

// Assuming these are defined in your project
enum ExamStatus { draft, published, archived }
enum ExamAttemptStatus { notStarted, inProgress, completed }

class Examination {
  final String id;
  final String uuid;
  final String title;
  final String? description;
  final int duration;
  final double? passmark;
  final bool shuffleQuestions;
  final bool allowReview;
  final bool showResults;
  final DateTime? startDate;
  final DateTime? endDate;
  final ExamStatus status;
  final String? instructions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ExamAttemptStatus attemptStatus;
  final int questionCount;
  final int totalPoints;
  final String? subjectId;
  final String? gradeId;
  final Map<String, dynamic>? subject;
  final Map<String, dynamic>? grade;

  Examination({
    required this.id,
    required this.uuid,
    required this.title,
    this.description,
    required this.duration,
    this.passmark,
    required this.shuffleQuestions,
    required this.allowReview,
    required this.showResults,
    this.startDate,
    this.endDate,
    required this.status,
    this.instructions,
    required this.createdAt,
    required this.updatedAt,
    required this.attemptStatus,
    required this.questionCount,
    required this.totalPoints,
    this.subjectId,
    this.gradeId,
    this.subject,
    this.grade,
  });

  factory Examination.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print('Invalid date format: $dateStr');
        return null;
      }
    }

    return Examination(
      id: json['id'] ?? '',
      uuid: json['uuid'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      duration: json['duration'] ?? 0,
      passmark: json['passmark']?.toDouble(),
      shuffleQuestions: json['shuffleQuestions'] ?? false,
      allowReview: json['allowReview'] ?? false,
      showResults: json['showResults'] ?? false,
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      status: _parseExamStatus(json['status']),
      instructions: json['instructions'],
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(json['updatedAt']) ?? DateTime.now(),
      attemptStatus: _parseAttemptStatus(json['attemptStatus']),
      questionCount: json['questionCount'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      subjectId: json['subjectId'],
      gradeId: json['gradeId'],
      subject: json['subject'],
      grade: json['grade'],
    );
  }

  static ExamStatus _parseExamStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return ExamStatus.draft;
      case 'published':
        return ExamStatus.published;
      case 'archived':
        return ExamStatus.archived;
      default:
        return ExamStatus.draft;
    }
  }

  static ExamAttemptStatus _parseAttemptStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'notstarted':
      case 'not_started':
        return ExamAttemptStatus.notStarted;
      case 'inprogress':
      case 'in_progress':
        return ExamAttemptStatus.inProgress;
      case 'completed':
        return ExamAttemptStatus.completed;
      default:
        return ExamAttemptStatus.notStarted;
    }
  }
}

class AppColors {
  static const Color darkPurple = Color(0xFF4B0082);
  static const Color red = Color(0xFFFF0000);
  static const Color black = Color(0xFF000000);
  static const Color lightBlue = Color(0xFFADD8E6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightPurple = Color(0xFF9370DB);
  static const Color darkGrey = Color(0xFF5A5A5A);
  static const Color green = Color(0xFF4CAF50);
  static const Color orange = Color(0xFFFF9800);
}

class AdminExamsManagementPage extends StatefulWidget {
  const AdminExamsManagementPage({super.key});

  @override
  _AdminExamsManagementPageState createState() => _AdminExamsManagementPageState();
}

class _AdminExamsManagementPageState extends State<AdminExamsManagementPage> {
  ExamService? _examService;
  List<Examination> _exams = [];
  List<Examination> _filteredExams = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _endCursor; // For cursor-based pagination
  static const int _pageSize = 20;
  bool _hasMore = true;
  int _totalCount = 0;

  final Map<String, dynamic> _filters = {
    'status': null,
    'attemptStatus': null,
    'title': '',
    'dateFrom': null,
    'dateTo': null,
  };

  final TextEditingController _titleFilterController = TextEditingController();
  Examination? _selectedExam;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _passmarkController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  ExamStatus? _status;
  bool _shuffleQuestions = false;
  bool _allowReview = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      final ExamService examService = await GetIt.I.getAsync<ExamService>();
      setState(() {
        _examService = examService;
        _isLoading = false;
      });
      await _loadExams();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize exam service: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleFilterController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _passmarkController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadExams({bool loadMore = false}) async {
    if (_examService == null) {
      setState(() {
        _errorMessage = 'Exam service not initialized';
        _isLoading = false;
      });
      return;
    }

    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _endCursor = null; // Reset cursor for new search
        _exams.clear();
        _filteredExams.clear();
      });
    }

    try {
      // Build filter object according to GraphQL schema
      final Map<String, dynamic> apiFilter = {};
      if (_filters['title'].isNotEmpty) {
        apiFilter['search'] = _filters['title']; // Use 'search' instead of 'title'
      }
      if (_filters['status'] != null) {
        apiFilter['status'] = _filters['status'].toString().split('.').last.toUpperCase();
      }
      if (_filters['dateFrom'] != null) {
        apiFilter['startDateFrom'] = _filters['dateFrom'].toIso8601String();
      }
      if (_filters['dateTo'] != null) {
        apiFilter['startDateTo'] = _filters['dateTo'].toIso8601String();
      }

      final Map<String, dynamic> sort = {
        'field': 'CREATED_AT',
        'direction': 'DESC',
      };

      // Use cursor-based pagination
      final Map<String, dynamic> pagination = {
        'first': _pageSize,
        if (_endCursor != null && loadMore) 'after': _endCursor,
      };

      final result = await _examService!.getExams(
        filter: apiFilter.isNotEmpty ? apiFilter : null,
        sort: sort,
        pagination: pagination,
      );

      if (result != null) {
        final edges = result['edges'] as List<dynamic>? ?? [];
        final pageInfo = result['pageInfo'] as Map<String, dynamic>? ?? {};
        _totalCount = result['totalCount'] ?? 0;

        final newExams = edges.map((edge) {
          final node = edge['node'] as Map<String, dynamic>;
          return Examination.fromJson(node);
        }).toList();

        // Get the end cursor for next page
        String? newEndCursor;
        if (edges.isNotEmpty) {
          newEndCursor = edges.last['cursor'] as String?;
        }

        setState(() {
          if (loadMore) {
            _exams.addAll(newExams);
          } else {
            _exams = newExams;
          }
          _filteredExams = _exams;
          _endCursor = newEndCursor;
          _hasMore = pageInfo['hasNextPage'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No data received';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load exams: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _loadMoreExams() {
    if (_hasMore && !_isLoading) {
      _loadExams(loadMore: true);
    }
  }

  void _applyFilters() {
    _loadExams();
  }

  void _showUpdateExamDialog(Examination exam) {
    _selectedExam = exam;
    _titleController.text = exam.title;
    _descriptionController.text = exam.description ?? '';
    _durationController.text = exam.duration.toString();
    _passmarkController.text = exam.passmark?.toString() ?? '';
    _instructionsController.text = exam.instructions ?? '';
    _startDate = exam.startDate;
    _endDate = exam.endDate;
    _status = exam.status;
    _shuffleQuestions = exam.shuffleQuestions;
    _allowReview = exam.allowReview;
    _showResults = exam.showResults;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Update Exam: ${exam.title}'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 2,
                      ),
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter duration';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _passmarkController,
                        decoration: const InputDecoration(labelText: 'Passmark (%)'),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: _instructionsController,
                        decoration: const InputDecoration(labelText: 'Instructions'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildDatePicker('Start Date', _startDate, (date) {
                        setDialogState(() {
                          _startDate = date;
                        });
                      }),
                      _buildDatePicker('End Date', _endDate, (date) {
                        setDialogState(() {
                          _endDate = date;
                        });
                      }),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ExamStatus>(
                        value: _status,
                        items: ExamStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_formatExamStatus(status)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _status = value;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Exam Status'),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Shuffle Questions'),
                        value: _shuffleQuestions,
                        onChanged: (value) {
                          setDialogState(() {
                            _shuffleQuestions = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Allow Review'),
                        value: _allowReview,
                        onChanged: (value) {
                          setDialogState(() {
                            _allowReview = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Show Results'),
                        value: _showResults,
                        onChanged: (value) {
                          setDialogState(() {
                            _showResults = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _submitExamUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPurple,
                  ),
                  child: const Text('Update', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitExamUpdate() async {
    if (_formKey.currentState!.validate() && _selectedExam != null && _examService != null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        await _examService!.updateExam(
          id: _selectedExam!.id,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          duration: int.parse(_durationController.text),
          passmark: _passmarkController.text.isEmpty ? null : double.parse(_passmarkController.text),
          instructions: _instructionsController.text.isEmpty ? null : _instructionsController.text,
          startDate: _startDate,
          endDate: _endDate,
          status: _status?.toString().split('.').last,
          shuffleQuestions: _shuffleQuestions,
          allowReview: _allowReview,
          showResults: _showResults,
        );

        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Close update dialog
        await _loadExams();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam updated successfully')),
        );
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update exam: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _publishExam(Examination exam) async {
    if (_examService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam service not initialized')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _examService!.publishExam(exam.id);
      Navigator.pop(context); // Close loading
      await _loadExams();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam published successfully')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish exam: ${e.toString()}')),
      );
    }
  }

  Future<void> _archiveExam(Examination exam) async {
    if (_examService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam service not initialized')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      await _examService!.archiveExam(exam.id);
      Navigator.pop(context); // Close loading
      await _loadExams();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam archived successfully')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to archive exam: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteExam(Examination exam) async {
    if (_examService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam service not initialized')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${exam.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        await _examService!.deleteExam(exam.id);
        Navigator.pop(context); // Close loading
        await _loadExams();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam deleted successfully')),
        );
      } catch (e) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete exam: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildDatePicker(String label, DateTime? date, Function(DateTime) onDateSelected) {
    return ListTile(
      title: Text('$label: ${date != null ? DateFormat.yMd().format(date) : "Not set"}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
    );
  }

  String _formatExamStatus(ExamStatus status) {
    switch (status) {
      case ExamStatus.draft:
        return 'Draft';
      case ExamStatus.published:
        return 'Published';
      case ExamStatus.archived:
        return 'Archived';
    }
  }

  String _formatExamAttemptStatus(ExamAttemptStatus status) {
    switch (status) {
      case ExamAttemptStatus.notStarted:
        return 'Not Started';
      case ExamAttemptStatus.inProgress:
        return 'In Progress';
      case ExamAttemptStatus.completed:
        return 'Completed';
    }
  }

  IconData _getAttemptStatusIcon(ExamAttemptStatus status) {
    switch (status) {
      case ExamAttemptStatus.notStarted:
        return Icons.play_circle_outline;
      case ExamAttemptStatus.inProgress:
        return Icons.timelapse;
      case ExamAttemptStatus.completed:
        return Icons.check_circle;
    }
  }

  Color _getAttemptStatusColor(ExamAttemptStatus status) {
    switch (status) {
      case ExamAttemptStatus.notStarted:
        return AppColors.darkGrey;
      case ExamAttemptStatus.inProgress:
        return AppColors.orange;
      case ExamAttemptStatus.completed:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exams Management ($_totalCount)'),
        backgroundColor: AppColors.darkPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExams,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading && _exams.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadExams,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredExams.isEmpty
                        ? const Center(child: Text('No exams found'))
                        : _buildExamsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _titleFilterController,
              decoration: InputDecoration(
                labelText: 'Search by title',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _filters['title'] = _titleFilterController.text;
                    _applyFilters();
                  },
                ),
              ),
              onSubmitted: (value) {
                _filters['title'] = value;
                _applyFilters();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ExamStatus>(
                    value: _filters['status'],
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Exam Statuses'),
                      ),
                      ...ExamStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(_formatExamStatus(status)),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filters['status'] = value;
                        _applyFilters();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Exam Status',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _filters['dateFrom'] == null
                          ? 'Start Date'
                          : DateFormat.yMd().format(_filters['dateFrom']),
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _filters['dateFrom'] = date;
                          _applyFilters();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _filters['dateTo'] == null
                          ? 'End Date'
                          : DateFormat.yMd().format(_filters['dateTo']),
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _filters['dateTo'] = date;
                          _applyFilters();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filters['status'] = null;
                        _filters['attemptStatus'] = null;
                        _filters['title'] = '';
                        _filters['dateFrom'] = null;
                        _filters['dateTo'] = null;
                        _titleFilterController.clear();
                        _applyFilters();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reset Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoading && _hasMore && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadMoreExams();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: _filteredExams.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredExams.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final exam = _filteredExams[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${_formatExamStatus(exam.status)}'),
                  Row(
                    children: [
                      Icon(
                        _getAttemptStatusIcon(exam.attemptStatus),
                        color: _getAttemptStatusColor(exam.attemptStatus),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Attempt: ${_formatExamAttemptStatus(exam.attemptStatus)}',
                        style: TextStyle(
                          color: _getAttemptStatusColor(exam.attemptStatus),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (exam.startDate != null && exam.endDate != null)
                    Text('${DateFormat.yMd().format(exam.startDate!)} - ${DateFormat.yMd().format(exam.endDate!)}'),
                  Text('Questions: ${exam.questionCount} | Points: ${exam.totalPoints} | Duration: ${exam.duration}min'),
                  if (exam.subject != null) Text('Subject: ${exam.subject!['name'] ?? 'Unknown'}'),
                                    if (exam.grade != null) Text('Grade: ${exam.grade!['name'] ?? 'Unknown'}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.darkPurple),
                    onPressed: () => _showUpdateExamDialog(exam),
                    tooltip: 'Edit Exam',
                  ),
                  if (exam.status == ExamStatus.draft)
                    IconButton(
                      icon: const Icon(Icons.publish, color: AppColors.green),
                      onPressed: () => _publishExam(exam),
                      tooltip: 'Publish Exam',
                    ),
                  if (exam.status == ExamStatus.published)
                    IconButton(
                      icon: const Icon(Icons.archive, color: AppColors.orange),
                      onPressed: () => _archiveExam(exam),
                      tooltip: 'Archive Exam',
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.red),
                    onPressed: () => _deleteExam(exam),
                    tooltip: 'Delete Exam',
                  ),
                ],
              ),
              onTap: () => _showUpdateExamDialog(exam),
            ),
          );
        },
      ),
    );
  }
}