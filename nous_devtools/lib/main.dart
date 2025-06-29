import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/python.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CodeEditorApp());
}

class CodeEditorApp extends StatelessWidget {
  const CodeEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nous Code IDE',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
          elevation: 1,
        ),
      ),
      home: const CodeEditor(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CodeEditor extends StatefulWidget {
  const CodeEditor({super.key});

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late CodeController _controller;
  String _output = 'Welcome to Code IDE!\nClick the Run button to execute your code.';
  String _currentLanguage = 'javascript';
  String? _currentFilePath;
  bool _isRunning = false;
  bool _isDarkMode = true;
  bool _isVerticalLayout = false; // For responsive layout

  @override
  void initState() {
    super.initState();
    _controller = CodeController(text: _getInitialCode(), language: javascript);
    _loadPreferences();
  }

  String _getInitialCode() {
    return '''// Welcome to Code IDE
// Write your JavaScript code here

function greetUser(name) {
    return `Hello, \${name}! Welcome to our IDE.`;
}

function calculateSum(a, b) {
    return a + b;
}

// Example usage
const userName = "Developer";
const result = greetUser(userName);
console.log(result);
console.log("Sum of 5 + 3 =", calculateSum(5, 3));''';
  }

  String _getPythonInitialCode() {
    return '''# Welcome to Code IDE
# Write your Python code here

def greet_user(name):
    return f"Hello, {name}! Welcome to our IDE."

def calculate_sum(a, b):
    return a + b

# Example usage
user_name = "Developer"
result = greet_user(user_name)
print(result)
print("Sum of 5 + 3 =", calculate_sum(5, 3))''';
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode') ?? true;
      final lastFile = prefs.getString('lastFile');

      if (mounted) {
        setState(() {
          _isDarkMode = isDark;
        });
      }

      if (lastFile != null && File(lastFile).existsSync()) {
        await _loadFile(lastFile);
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      // Fallback for when SharedPreferences isn't available
      if (mounted) {
        setState(() {
          _isDarkMode = true;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      if (_currentFilePath != null) {
        await prefs.setString('lastFile', _currentFilePath!);
      }
    } catch (e) {
      debugPrint('Error saving preferences: $e');
      // Silently fail if SharedPreferences isn't available
    }
  }

  Future<void> _loadFile(String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();
      final isPython = path.toLowerCase().endsWith('.py');

      if (mounted) {
        setState(() {
          _currentFilePath = path;
          _controller.text = content;
          _currentLanguage = isPython ? 'python' : 'javascript';
          _controller.language = isPython ? python : javascript;
        });
      }

      await _savePreferences();
    } catch (e) {
      _showError('Error loading file: $e');
    }
  }

  Future<void> _saveFile() async {
    if (_currentFilePath == null) {
      await _saveFileAs();
      return;
    }

    try {
      final file = File(_currentFilePath!);
      await file.writeAsString(_controller.text);
      _showSuccess('File saved successfully');
    } catch (e) {
      _showError('Error saving file: $e');
    }
  }

  Future<void> _saveFileAs() async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save File',
        fileName: 'untitled.${_currentLanguage == 'python' ? 'py' : 'js'}',
        type: FileType.custom,
        allowedExtensions: [_currentLanguage == 'python' ? 'py' : 'js'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(_controller.text);
        setState(() {
          _currentFilePath = result;
        });
        await _savePreferences();
        _showSuccess('File saved successfully');
      }
    } catch (e) {
      _showError('Error saving file: $e');
    }
  }

  Future<void> _createNewFile() async {
    setState(() {
      _currentFilePath = null;
      _currentLanguage = 'javascript';
      _controller.text = _getInitialCode();
      _controller.language = javascript;
      _output = 'New file created.\nClick the Run button to execute your code.';
    });
  }

  Future<void> _switchLanguage() async {
    final newLanguage = _currentLanguage == 'javascript' ? 'python' : 'javascript';
    setState(() {
      _currentLanguage = newLanguage;
      _controller.language = newLanguage == 'python' ? python : javascript;
      _controller.text = newLanguage == 'python' ? _getPythonInitialCode() : _getInitialCode();
      _currentFilePath = null;
      _output = 'Language switched to ${newLanguage.toUpperCase()}.\nClick the Run button to execute your code.';
    });
  }

  Future<void> _runCode() async {
    if (_controller.text.trim().isEmpty) {
      _showError('No code to run');
      return;
    }

    // Save file first if needed
    if (_currentFilePath == null) {
      try {
        final tempDir = Directory.systemTemp;
        final fileName = 'temp_${DateTime.now().millisecondsSinceEpoch}.${_currentLanguage == 'python' ? 'py' : 'js'}';
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsString(_controller.text);
        _currentFilePath = tempFile.path;
      } catch (e) {
        _showError('Error creating temporary file: $e');
        return;
      }
    } else {
      await _saveFile();
    }

    setState(() {
      _isRunning = true;
      _output = 'Running ${_currentLanguage.toUpperCase()} code...\n';
    });

    try {
      String? execPath;
      List<String> command;

      if (_currentLanguage == 'python') {
        final pythonPaths = await which('python') ?? await which('python3');
        execPath = pythonPaths;
        command = [execPath ?? 'python', _currentFilePath!];
      } else {
        final nodePaths = await which('node');
        execPath = nodePaths;
        command = [execPath ?? 'node', _currentFilePath!];
      }

      if (execPath == null) {
        setState(() {
          _output = 'Error: ${_currentLanguage == 'python' ? 'Python' : 'Node.js'} interpreter not found.\n'
              'Please ensure ${_currentLanguage == 'python' ? 'Python' : 'Node.js'} is installed and added to PATH.';
          _isRunning = false;
        });
        return;
      }

      final process = await Process.start(
        command[0],
        command.sublist(1),
        workingDirectory: Directory(_currentFilePath!).parent.path,
      );

      final stdout = <String>[];
      final stderr = <String>[];

      process.stdout.transform(utf8.decoder).listen((data) {
        stdout.add(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        stderr.add(data);
      });

      final exitCode = await process.exitCode;

      setState(() {
        _output = '';
        if (stdout.isNotEmpty) {
          _output += 'Output:\n${stdout.join('')}\n';
        }
        if (stderr.isNotEmpty) {
          _output += 'Errors:\n${stderr.join('')}\n';
        }
        if (stdout.isEmpty && stderr.isEmpty) {
          _output += 'Code executed successfully with no output.\n';
        }
        _output += '\nExit code: $exitCode';
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _output = 'Execution error: $e';
        _isRunning = false;
      });
    }
  }

  Future<void> _deleteFile() async {
    if (_currentFilePath == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await File(_currentFilePath!).delete();
        setState(() {
          _currentFilePath = null;
          _controller.text = _getInitialCode();
          _currentLanguage = 'javascript';
          _controller.language = javascript;
          _output = 'File deleted.\nNew file created.';
        });
        _showSuccess('File deleted successfully');
      } catch (e) {
        _showError('Error deleting file: $e');
      }
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _savePreferences();
  }

  void _toggleLayout() {
    setState(() {
      _isVerticalLayout = !_isVerticalLayout;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildToolbar() {
    return Wrap(
      children: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _createNewFile,
          tooltip: 'New File',
        ),
        IconButton(
          icon: const Icon(Icons.folder_open),
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['js', 'py', 'txt'],
            );
            if (result != null && result.files.single.path != null) {
              await _loadFile(result.files.single.path!);
            }
          },
          tooltip: 'Open File',
        ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: _saveFile,
          tooltip: 'Save',
        ),
        IconButton(
          icon: const Icon(Icons.save_alt),
          onPressed: _saveFileAs,
          tooltip: 'Save As',
        ),
        IconButton(
          icon: const Icon(Icons.swap_horiz),
          onPressed: _switchLanguage,
          tooltip: 'Switch Language',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _currentFilePath == null ? null : _deleteFile,
          tooltip: 'Delete File',
        ),
        IconButton(
          icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: _toggleTheme,
          tooltip: _isDarkMode ? 'Light Mode' : 'Dark Mode',
        ),
        IconButton(
          icon: Icon(_isVerticalLayout ? Icons.view_sidebar : Icons.view_agenda),
          onPressed: _toggleLayout,
          tooltip: _isVerticalLayout ? 'Horizontal Layout' : 'Vertical Layout',
        ),
        Container(
          margin: const EdgeInsets.all(8),
          child: ElevatedButton.icon(
            onPressed: _isRunning ? null : _runCode,
            icon: _isRunning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_isRunning ? 'Running...' : 'Run'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeEditor() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          // Code editor header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
              border: Border(
                bottom: BorderSide(
                  color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _currentLanguage == 'python' ? Icons.code : Icons.javascript,
                  color: _currentLanguage == 'python' ? Colors.blue : Colors.yellow[700],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentFilePath?.split('/').last ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentLanguage == 'python' ? Colors.blue : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentLanguage.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Code editor content
          Expanded(
            child: CodeTheme(
              data: CodeThemeData(
                styles: _isDarkMode ? monokaiSublimeTheme : githubTheme,
              ),
              child: CodeField(
                controller: _controller,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                expands: true, // This makes it fill available space
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputPanel() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
        border: Border.all(
          color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
              border: Border(
                bottom: BorderSide(
                  color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: const Text(
              'Output',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                _output,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: _isDarkMode ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Code IDE'),
          actions: [_buildToolbar()],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Automatically switch to vertical layout on narrow screens
            final shouldUseVerticalLayout = _isVerticalLayout || constraints.maxWidth < 800;
            
            if (shouldUseVerticalLayout) {
              return Column(
                children: [
                  // Code Editor (70% of height)
                  Expanded(
                    flex: 7,
                    child: _buildCodeEditor(),
                  ),
                  // Output Panel (30% of height)
                  Expanded(
                    flex: 3,
                    child: _buildOutputPanel(),
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  // Code Editor (75% of width)
                  Expanded(
                    flex: 75,
                    child: _buildCodeEditor(),
                  ),
                  // Output Panel (25% of width)
                  Expanded(
                    flex: 25,
                    child: _buildOutputPanel(),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}