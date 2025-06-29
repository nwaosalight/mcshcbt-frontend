import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mcsh_cbt/features/exam/providers/exam.provider.dart';
import 'package:provider/provider.dart';
import 'package:mcsh_cbt/features/subject/providers/subject_provider.dart';
import '../theme.dart';

class CreateExaminationScreen extends StatefulWidget {
  const CreateExaminationScreen({super.key});

  @override
  State<CreateExaminationScreen> createState() => _CreateExaminationScreenState();
}

class _CreateExaminationScreenState extends State<CreateExaminationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _passmarkController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _shuffleQuestions = false;
  bool _allowReview = true;
  bool _showResults = true;
  bool _isLoading = false;
  
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy HH:mm');
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _passmarkController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime({required bool isStartDate}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.darkPurple,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.darkPurple,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        setState(() {
          if (isStartDate) {
            _startDate = selectedDateTime;
            // If end date is before start date, clear it
            if (_endDate != null && _endDate!.isBefore(selectedDateTime)) {
              _endDate = null;
            }
          } else {
            _endDate = selectedDateTime;
          }
        });
      }
    }
  }

  Future<void> _createExamination() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
      final examProvider = Provider.of<ExamProvider>(context, listen: false);
      
      if (subjectProvider.selectedSubject == null) {
        _showErrorSnackBar('No subject selected');
        return;
      }

      final result = await examProvider.createExam(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        subjectId: subjectProvider.selectedSubject!.id,
        gradeId:  "${subjectProvider.selectedSubject!.gradeId}"  ,
        duration: int.parse(_durationController.text),
        passmark: _passmarkController.text.isEmpty 
            ? null 
            : double.parse(_passmarkController.text),
        shuffleQuestions: _shuffleQuestions,
        allowReview: _allowReview,
        showResults: _showResults,
        startDate: _startDate,
        endDate: _endDate,
        instructions: _instructionsController.text.trim().isEmpty 
            ? null 
            : _instructionsController.text.trim(),
      );

      if (result.isNotEmpty && mounted) {
        _showSuccessSnackBar('Examination created successfully!');
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        _showErrorSnackBar('Failed to create examination  ${examProvider.errorMessage}');
      }
    } catch (e) {
      _showErrorSnackBar('Error creating examination: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDateTimeCard({
    required String title,
    required DateTime? dateTime,
    required VoidCallback onTap,
    required bool isRequired,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.darkPurple,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title${isRequired ? ' *' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateTime != null 
                          ? _dateFormat.format(dateTime)
                          : 'Select ${title.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: dateTime != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.darkPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.darkPurple,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Examination'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Examination',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create an examination for ${subjectProvider.selectedSubject?.name ?? 'Selected Subject'}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information
                        _buildSectionTitle('Basic Information'),
                        _buildTextField(
                          controller: _titleController,
                          label: 'Examination Title',
                          hintText: 'Enter examination title',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter examination title';
                            }
                            if (value.trim().length < 3) {
                              return 'Title must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description (Optional)',
                          hintText: 'Enter examination description',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        
                        // Examination Settings
                        _buildSectionTitle('Examination Settings'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _durationController,
                                label: 'Duration (minutes)',
                                hintText: 'e.g., 60',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter duration';
                                  }
                                  final duration = int.tryParse(value);
                                  if (duration == null || duration <= 0) {
                                    return 'Please enter valid duration';
                                  }
                                  if (duration > 480) {
                                    return 'Duration cannot exceed 8 hours';
                                  }
                                  return null;
                                },
                                suffixIcon: const Icon(Icons.timer),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _passmarkController,
                                label: 'Pass Mark % (Optional)',
                                hintText: 'e.g., 60',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d{0,2}(\.\d{0,2})?'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final passmark = double.tryParse(value);
                                    if (passmark == null || passmark < 0 || passmark > 100) {
                                      return 'Enter valid percentage (0-100)';
                                    }
                                  }
                                  return null;
                                },
                                suffixIcon: const Icon(Icons.percent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Schedule
                        _buildSectionTitle('Schedule (Optional)'),
                        _buildDateTimeCard(
                          title: 'Start Date & Time',
                          dateTime: _startDate,
                          onTap: () => _selectDateTime(isStartDate: true),
                          isRequired: false,
                        ),
                        const SizedBox(height: 12),
                        _buildDateTimeCard(
                          title: 'End Date & Time',
                          dateTime: _endDate,
                          onTap: () => _selectDateTime(isStartDate: false),
                          isRequired: false,
                        ),
                        const SizedBox(height: 24),
                        
                        // Exam Options
                        _buildSectionTitle('Examination Options'),
                        _buildSwitchCard(
                          title: 'Shuffle Questions',
                          subtitle: 'Randomize question order for each student',
                          value: _shuffleQuestions,
                          onChanged: (value) => setState(() => _shuffleQuestions = value),
                        ),
                        const SizedBox(height: 12),
                        _buildSwitchCard(
                          title: 'Allow Review',
                          subtitle: 'Students can review and change answers',
                          value: _allowReview,
                          onChanged: (value) => setState(() => _allowReview = value),
                        ),
                        const SizedBox(height: 12),
                        _buildSwitchCard(
                          title: 'Show Results',
                          subtitle: 'Display results immediately after submission',
                          value: _showResults,
                          onChanged: (value) => setState(() => _showResults = value),
                        ),
                        const SizedBox(height: 24),
                        
                        // Instructions
                        _buildSectionTitle('Instructions (Optional)'),
                        _buildTextField(
                          controller: _instructionsController,
                          label: 'Examination Instructions',
                          hintText: 'Enter instructions for students...',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                
                // Create Button
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createExamination,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Create Examination',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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