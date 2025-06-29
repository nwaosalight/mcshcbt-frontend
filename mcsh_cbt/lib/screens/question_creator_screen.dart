import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fleather/fleather.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mcsh_cbt/features/subject/providers/subject_provider.dart';
import 'package:provider/provider.dart';
import 'package:mcsh_cbt/features/subject/models/exam_question.dart';
import '../theme.dart';
import '../models/question.dart';

class QuestionCreatorScreen extends StatefulWidget {
  final String subject;
  final Function(Question)? onQuestionCreated;
  final ExamQuestion? questionToEdit;

  const QuestionCreatorScreen({
    super.key,
    required this.subject,
    this.onQuestionCreated,
    this.questionToEdit,
  });

  @override
  State<QuestionCreatorScreen> createState() => _QuestionCreatorScreenState();
}

class _QuestionCreatorScreenState extends State<QuestionCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionNumberController = TextEditingController();
  final _optionControllers = List.generate(4, (_) => TextEditingController());

  List<String> _images = [];
  final _imagePicker = ImagePicker();
  int _correctOptionIndex = 0;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  bool _isUpdatingQuestion = false;

  late FleatherController _fleatherController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.questionToEdit != null;

    // Initialize FleatherController with empty document
    _fleatherController = FleatherController();

    if (_isEditing) {
      _initializeEditForm();
    } else {
      _setDefaultQuestionNumber();
    }
  }

  void _setDefaultQuestionNumber() {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    int nextQuestionNumber = provider.question.length + 1;
    _questionNumberController.text = nextQuestionNumber.toString();
  }

  void _initializeEditForm() {
    final question = widget.questionToEdit!;

    // Initialize Fleather controller with existing question text
    if (question.text.isNotEmpty) {
      try {
        // First try to parse as JSON (for rich text)
        final json = _tryParseJson(question.text);
        if (json != null) {
          final document = ParchmentDocument.fromJson(json);
          _fleatherController = FleatherController(document: document);
        } else {
          // If not JSON, treat as plain text
          _fleatherController = _createControllerFromPlainText(question.text);
        }
      } catch (e) {
        // If parsing fails, fall back to plain text
        _fleatherController = _createControllerFromPlainText(question.text);
      }
    } else {
      _fleatherController = FleatherController();
    }

    _questionNumberController.text = question.questionNumber.toString();

    // Populate option controllers
    for (int i = 0; i < question.options.length && i < 4; i++) {
      final option = question.options[i];
      if (option.values.isNotEmpty) {
        _optionControllers[i].text = option.values.first;
      }
    }

    // Set correct answer index
    if (question.correctAnswer.isNotEmpty) {
      final correctIndex = question.options.indexWhere(
        (option) => option.keys.first == question.correctAnswer,
      );
      if (correctIndex != -1) {
        _correctOptionIndex = correctIndex;
      }
    }

    // Set images
    if (question.image != null && question.image!.isNotEmpty) {
      _images = [question.image!];
    }
  }

  // Helper method to try parsing text as JSON
  dynamic _tryParseJson(String text) {
    try {
      return jsonDecode(text);
    } catch (e) {
      return null;
    }
  }

  // Helper method to create controller from plain text
  FleatherController _createControllerFromPlainText(String text) {
    final document = ParchmentDocument();
    if (text.isNotEmpty) {
      document.insert(0, text);
    }
    return FleatherController(document: document);
  }

  @override
  void dispose() {
    _questionNumberController.dispose();
    _fleatherController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isUploadingImage = true);

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        setState(() => _images.add(pickedFile.path));
      }
    } catch (e) {
      _showErrorSnackbar('Image picker error: ${e.toString()}');
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Image Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  String _getQuestionText() {
    return _fleatherController.document.toPlainText().trim();
  }

  // Get formatted text as JSON for storage (if rich text) or plain text
  String _getQuestionDocument() {
    final doc = _fleatherController.document;
    // Only return JSON if document has formatting
    if (_hasFormatting(doc)) {
      return jsonEncode(doc.toJson());
    }
    // Otherwise return plain text
    return doc.toPlainText();
  }

  // Check if document has any formatting
  bool _hasFormatting(ParchmentDocument doc) {
    // Simple check: if the document has more than just plain text, it has formatting
    final plainText = doc.toPlainText();
    final jsonText = jsonEncode(doc.toJson());

    // If JSON representation is significantly different from plain text, it has formatting
    return jsonText.length >
        plainText.length + 50; // Allow some overhead for JSON structure
  }

  bool _validateForm() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }

    final questionText = _getQuestionText();
    if (questionText.isEmpty) {
      _showErrorSnackbar('Please enter question text');
      return false;
    }

    // Check if all options are filled
    for (int i = 0; i < _optionControllers.length; i++) {
      if (_optionControllers[i].text.trim().isEmpty) {
        _showErrorSnackbar('Please fill all options');
        return false;
      }
    }

    return true;
  }

  Future<void> _handleQuestionUpdate() async {
    if (!_validateForm()) return;

    setState(() => _isUpdatingQuestion = true);

    try {
      final provider = Provider.of<SubjectProvider>(context, listen: false);

      final options = [
        {'a': _optionControllers[0].text.trim()},
        {'b': _optionControllers[1].text.trim()},
        {'c': _optionControllers[2].text.trim()},
        {'d': _optionControllers[3].text.trim()},
      ];

      const keys = ['a', 'b', 'c', 'd'];
      String correctAnswerKey = keys[_correctOptionIndex];

      final updatedQuestion = await provider.updateExamQuestion(
        text: _getQuestionDocument(), // Use rich text document
        opts: options,
        correctAnswer: correctAnswerKey,
        image: _images.isNotEmpty ? _images.first : null,
      );

      if (updatedQuestion != null) {
        _showSuccessSnackbar('Question updated successfully!');
        if (provider.selectedExam != null) {
          await provider.getSubjectExamQuestions(provider.selectedExam!.id);
        }
        if (mounted) {
          Navigator.pop(context, updatedQuestion);
        }
      } else {
        _showErrorSnackbar(
          provider.errorMessage.isNotEmpty
              ? provider.errorMessage
              : 'Failed to update question',
        );
      }
    } catch (e) {
      _showErrorSnackbar('Failed to update question: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingQuestion = false);
      }
    }
  }

  Future<void> _handleQuestionCreation() async {
    if (!_validateForm()) return;

    setState(() => _isUpdatingQuestion = true);

    try {
      final provider = Provider.of<SubjectProvider>(context, listen: false);

      final options = [
        {'a': _optionControllers[0].text.trim()},
        {'b': _optionControllers[1].text.trim()},
        {'c': _optionControllers[2].text.trim()},
        {'d': _optionControllers[3].text.trim()},
      ];

      const keys = ['a', 'b', 'c', 'd'];
      String correctAnswerKey = keys[_correctOptionIndex];

      final questionNumber = int.tryParse(_questionNumberController.text) ?? 1;

      final newQuestion = await provider.addExamQuestion(
        questionNumber: questionNumber,
        text: _getQuestionDocument(), // Use rich text document
        opts: options,
        correctAnswer: correctAnswerKey,
        image: _images.isNotEmpty ? _images.first : null,
      );

      if (newQuestion.isOk()) {
        _showSuccessSnackbar('Question created successfully!');

        // Call the legacy callback for backward compatibility if provided
        if (widget.onQuestionCreated != null) {
          final legacyQuestion = Question(
            label: _getQuestionText(),
            options: _optionControllers.map((c) => c.text.trim()).toList(),
            images: _images,
            selectedAnswer: _optionControllers[_correctOptionIndex].text.trim(),
          );
          widget.onQuestionCreated!(legacyQuestion);
        }

        _resetForm();
        if (mounted) {
          Navigator.pop(context, newQuestion);
        }
      } else {
        _showErrorSnackbar(newQuestion.unwrapErr());
      }
    } catch (e) {
      _showErrorSnackbar('Failed to create question: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingQuestion = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _fleatherController.clear();
    _questionNumberController.clear();
    for (var controller in _optionControllers) {
      controller.clear();
    }
    setState(() {
      _images = [];
      _correctOptionIndex = 0;
    });
    _setDefaultQuestionNumber();
  }

  Future<void> _submitQuestion() async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);

    if (provider.selectedExam == null) {
      _showErrorSnackbar('No exam selected. Please select an exam first.');
      return;
    }

    if (_isEditing) {
      await _handleQuestionUpdate();
    } else {
      await _handleQuestionCreation();
    }
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.darkPurple,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Helper method to build mathematical symbol buttons
  Widget _buildMathSymbolButton(String symbol, String description) {
    return Tooltip(
      message: description,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: () {
            // Insert the mathematical symbol at the current cursor position
            final selection = _fleatherController.selection;
            if (selection.isValid) {
              _fleatherController.document.insert(selection.baseOffset, symbol);
            } else {
              // If no selection, insert at the end
              _fleatherController.document.insert(
                _fleatherController.document.length,
                symbol,
              );
            }
            // Focus back to the editor
            _focusNode.requestFocus();
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              symbol,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Question' : 'Create Question'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.darkPurple,
        foregroundColor: AppColors.white,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.lightBlue, AppColors.white],
              ),
            ),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubjectHeader(),
                          const SizedBox(height: 24),
                          _buildQuestionNumberField(),
                          const SizedBox(height: 16),
                          _buildQuestionTextField(),
                          const SizedBox(height: 24),
                          _buildImageSection(),
                          const SizedBox(height: 24),
                          _buildOptionsSection(),
                          const SizedBox(height: 32),
                          _buildSubmitButton(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isUpdatingQuestion) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkPurple),
        ),
      ),
    );
  }

  Widget _buildSubjectHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkPurple,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          widget.subject,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Question Number *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _questionNumberController,
          decoration: InputDecoration(
            hintText: 'Enter question number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Please enter a question number';
            }
            final number = int.tryParse(value!);
            if (number == null || number <= 0) {
              return 'Please enter a valid positive number';
            }
            return null;
          },
          enabled: !_isEditing,
        ),
      ],
    );
  }

  Widget _buildQuestionTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Question Text *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // FleatherToolbar with improved styling
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    FleatherToolbar.basic(controller: _fleatherController),
                    // Mathematical symbols toolbar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Wrap(
                        spacing: 4,
                        children: [
                          _buildMathSymbolButton('∑', 'sum'),
                          _buildMathSymbolButton('∫', 'integral'),
                          _buildMathSymbolButton('√', 'sqrt'),
                          _buildMathSymbolButton('∞', 'infinity'),
                          _buildMathSymbolButton('±', 'plusminus'),
                          _buildMathSymbolButton('≠', 'notequal'),
                          _buildMathSymbolButton('≤', 'lessequal'),
                          _buildMathSymbolButton('≥', 'greaterequal'),
                          _buildMathSymbolButton('π', 'pi'),
                          _buildMathSymbolButton('θ', 'theta'),
                          _buildMathSymbolButton('α', 'alpha'),
                          _buildMathSymbolButton('β', 'beta'),
                          _buildMathSymbolButton('γ', 'gamma'),
                          _buildMathSymbolButton('δ', 'delta'),
                          _buildMathSymbolButton('μ', 'mu'),
                          _buildMathSymbolButton('σ', 'sigma'),
                          _buildMathSymbolButton('φ', 'phi'),
                          _buildMathSymbolButton('ω', 'omega'),
                          _buildMathSymbolButton('Δ', 'Delta'),
                          _buildMathSymbolButton('Σ', 'Sigma'),
                          _buildMathSymbolButton('Π', 'Pi'),
                          _buildMathSymbolButton('Ω', 'Omega'),
                          _buildMathSymbolButton('²', 'squared'),
                          _buildMathSymbolButton('³', 'cubed'),
                          _buildMathSymbolButton('¹', 'superscript1'),
                          _buildMathSymbolButton('₀', 'subscript0'),
                          _buildMathSymbolButton('₁', 'subscript1'),
                          _buildMathSymbolButton('₂', 'subscript2'),
                          _buildMathSymbolButton('₃', 'subscript3'),
                          _buildMathSymbolButton('₄', 'subscript4'),
                          _buildMathSymbolButton('₅', 'subscript5'),
                          _buildMathSymbolButton('₆', 'subscript6'),
                          _buildMathSymbolButton('₇', 'subscript7'),
                          _buildMathSymbolButton('₈', 'subscript8'),
                          _buildMathSymbolButton('₉', 'subscript9'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(height: 1, color: Colors.grey.shade200),

              // FleatherEditor
              Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                child: FleatherTheme(
                  data: FleatherThemeData(
                    paragraph: TextBlockTheme(
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black,
                      ),
                      spacing: const VerticalSpacing(top: 0, bottom: 8),
                    ),
                    heading1: TextBlockTheme(
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.3,
                      ),
                      spacing: const VerticalSpacing(top: 16, bottom: 8),
                    ),
                    heading2: TextBlockTheme(
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.3,
                      ),
                      spacing: const VerticalSpacing(top: 12, bottom: 6),
                    ),
                    heading3: TextBlockTheme(
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.3,
                      ),
                      spacing: const VerticalSpacing(top: 10, bottom: 4),
                    ),
                    lists: TextBlockTheme(
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        height: 1.4,
                      ),
                      spacing: const VerticalSpacing(top: 0, bottom: 6),
                    ),
                    quote: TextBlockTheme(
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      spacing: const VerticalSpacing(top: 8, bottom: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            width: 4,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    code: TextBlockTheme(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontFamily: 'monospace',
                        backgroundColor: Colors.grey.shade100,
                        height: 1.3,
                      ),
                      spacing: const VerticalSpacing(top: 8, bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    bold: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    italic: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                    underline: const TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.black,
                    ),
                    strikethrough: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.black,
                    ),
                    link: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    inlineCode: InlineCodeThemeData(
                      backgroundColor: Colors.grey.shade200,
                      radius: const Radius.circular(4),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontFamily: 'monospace',
                      ),
                    ),
                    heading4: TextBlockTheme(
                      style: const TextStyle(fontSize: 20),
                      spacing: VerticalSpacing.zero(),
                    ),
                    heading5: TextBlockTheme(
                      style: const TextStyle(fontSize: 18),
                      spacing: VerticalSpacing.zero(),
                    ),
                    heading6: TextBlockTheme(
                      style: const TextStyle(fontSize: 16),
                      spacing: VerticalSpacing.zero(),
                    ),
                    horizontalRule: HorizontalRuleThemeData(
                      height: 10,
                      thickness: 2,
                      color: Colors.black54,
                    ),
                  ),
                  child: FleatherEditor(
                    controller: _fleatherController,
                    focusNode: _focusNode,
                    scrollable: true,
                    autofocus: false,
                    expands: false,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Images (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _isUploadingImage ? null : _showImagePickerOptions,
              icon:
                  _isUploadingImage
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.add_photo_alternate),
              label: const Text('Add Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPurple,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _images.isEmpty
            ? _buildEmptyImagePlaceholder()
            : _buildImagePreviewList(),
      ],
    );
  }

  Widget _buildEmptyImagePlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No images added yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Image" to upload images for your question',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewList() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                width: 150,
                height: 150,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      _images[index].startsWith('http')
                          ? Image.network(
                            _images[index],
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _buildBrokenImageIcon(),
                          )
                          : Image.file(
                            File(_images[index]),
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _buildBrokenImageIcon(),
                          ),
                ),
              ),
              Positioned(
                top: 8,
                right: 24,
                child: InkWell(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrokenImageIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.red[300], size: 48),
          const SizedBox(height: 8),
          const Text(
            'Failed to load',
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Answer Options *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select the correct answer by tapping the radio button',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ..._buildOptionFields(),
      ],
    );
  }

  List<Widget> _buildOptionFields() {
    return List.generate(4, (index) {
      final optionLetter = String.fromCharCode(65 + index);
      final isSelected = _correctOptionIndex == index;

      return Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.darkPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color:
              isSelected
                  ? AppColors.darkPurple.withOpacity(0.05)
                  : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Radio<int>(
                value: index,
                groupValue: _correctOptionIndex,
                onChanged:
                    _isUpdatingQuestion
                        ? null
                        : (value) {
                          if (value != null) {
                            setState(() => _correctOptionIndex = value);
                          }
                        },
                activeColor: AppColors.darkPurple,
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.darkPurple;
                  }
                  return Colors.grey.shade400;
                }),
              ),
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.darkPurple : Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    optionLetter,
                    style: TextStyle(
                      color: isSelected ? AppColors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _optionControllers[index],
                  decoration: InputDecoration(
                    hintText: 'Enter option $optionLetter',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Please enter option $optionLetter';
                    }
                    return null;
                  },
                  enabled: !_isUpdatingQuestion,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSubmitButton() {
    return Center(
      child: SizedBox(
        width: 200,
        height: 50,
        child: ElevatedButton(
          onPressed: _isUpdatingQuestion ? null : _submitQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkPurple,
            foregroundColor: AppColors.white,
            elevation: 4,
            shadowColor: AppColors.darkPurple.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            disabledBackgroundColor: Colors.grey.shade400,
          ),
          child:
              _isUpdatingQuestion
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isEditing ? Icons.update : Icons.add, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isEditing ? 'Update Question' : 'Create Question',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
