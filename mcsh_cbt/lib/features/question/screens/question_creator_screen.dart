import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/app_theme.dart';
import '../../../core/models/question.dart';
import '../providers/question_provider.dart';

class QuestionCreatorScreen extends StatefulWidget {
  const QuestionCreatorScreen({super.key});

  @override
  State<QuestionCreatorScreen> createState() => _QuestionCreatorScreenState();
}

class _QuestionCreatorScreenState extends State<QuestionCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  String _subject = '';
  String _difficulty = 'Easy';
  int _correctOption = 0;
  final List<File> _images = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  final List<String> _difficultyLevels = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    // Get subject from route parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final params = GoRouterState.of(context).uri.queryParameters;
      if (params.containsKey('subject')) {
        setState(() {
          _subject = params['subject']!;
        });
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_subject.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create question object
      final question = Question(
        id: '', // Will be set by the provider
        question: _questionController.text.trim(),
        options: _optionControllers.map((c) => c.text.trim()).toList(),
        correctOption: _correctOption,
        subject: _subject,
        difficulty: _difficulty,
      );

      // Save the question with images
      final success = await Provider.of<QuestionProvider>(
        context,
        listen: false,
      ).addQuestion(question, _images);

      if (!mounted) return;

      if (success) {
        // Show success message and go back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question saved successfully')),
        );
        context.goNamed('teacherSubjects');
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save question')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving question: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Question'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveQuestion,
            icon: const Icon(Icons.save),
            label: const Text('SAVE'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryLight.withOpacity(0.3),
                      AppColors.background,
                    ],
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 1200 : 600,
                        ),
                        child:
                            isDesktop
                                ? _buildDesktopLayout()
                                : _buildMobileLayout(),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Header with subject
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.subject, color: AppColors.primary, size: 32),
              const SizedBox(width: 16),
              Text(
                _subject.isEmpty
                    ? 'Create Question'
                    : 'Create Question for $_subject',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Two-column layout
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - Question and metadata
            Expanded(
              flex: 5,
              child: Card(
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
                        'Question Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Subject field
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _subject.isEmpty ? 'No subject selected' : _subject,
                          style: TextStyle(
                            color:
                                _subject.isEmpty ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Difficulty dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(),
                        ),
                        value: _difficulty,
                        items:
                            _difficultyLevels.map((level) {
                              return DropdownMenuItem<String>(
                                value: level,
                                child: Text(level),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _difficulty = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Question text field
                      const Text(
                        'Question Text',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter your question here',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a question';
                          }
                          return null;
                        },
                        maxLines: 5,
                      ),
                      const SizedBox(height: 24),

                      // Image section
                      const Text(
                        'Images (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_images.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'No images added yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      if (_images.isNotEmpty)
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _images.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 16),
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _images[index],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 20,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              spreadRadius: 1,
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('ADD IMAGE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Right column - Options
            Expanded(
              flex: 4,
              child: Card(
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
                        'Answer Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select the correct answer using the radio buttons',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Option fields
                      for (int i = 0; i < _optionControllers.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Radio<int>(
                                value: i,
                                groupValue: _correctOption,
                                activeColor: AppColors.primary,
                                onChanged: (value) {
                                  setState(() {
                                    _correctOption = value!;
                                  });
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Option ${i + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: _optionControllers[i],
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Enter answer option',
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter an option';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            'SAVE QUESTION',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Make sure all fields are filled correctly',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Subject field
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
            child: Text(
              _subject.isEmpty ? 'No subject selected' : _subject,
              style: TextStyle(
                color: _subject.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Difficulty dropdown
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Difficulty',
              border: OutlineInputBorder(),
            ),
            value: _difficulty,
            items:
                _difficultyLevels.map((level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _difficulty = value!;
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // Question text field
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: TextFormField(
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: 'Question',
              border: OutlineInputBorder(),
              hintText: 'Enter your question here',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a question';
              }
              return null;
            },
            maxLines: 3,
          ),
        ),

        const SizedBox(height: 16),

        // Image section
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Images',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_images.isEmpty)
                    const Text(
                      'No images added (optional)',
                      style: TextStyle(color: Colors.grey),
                    ),
                  if (_images.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _images[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.close, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('ADD IMAGE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Options section
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option fields
                  for (int i = 0; i < _optionControllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: i,
                            groupValue: _correctOption,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                _correctOption = value!;
                              });
                            },
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _optionControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Option ${i + 1}',
                                border: const OutlineInputBorder(),
                                hintText: 'Enter option ${i + 1}',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter option ${i + 1}';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: 300,
          child: ElevatedButton(
            onPressed: _saveQuestion,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text('SAVE QUESTION'),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
