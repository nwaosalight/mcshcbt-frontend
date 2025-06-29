import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../common/utils/app_theme.dart';
import '../../../common/widgets/custom_button.dart';
import '../providers/teacher_provider.dart';

class TeacherPendingScreen extends StatefulWidget {
  const TeacherPendingScreen({Key? key}) : super(key: key);

  @override
  State<TeacherPendingScreen> createState() => _TeacherPendingScreenState();
}

class _TeacherPendingScreenState extends State<TeacherPendingScreen> {
  @override
  void initState() {
    super.initState();
    // Check account status to see if it has been approved
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    final teacherProvider = Provider.of<TeacherProvider>(
      context,
      listen: false,
    );
    await teacherProvider.checkAccountStatus();

    // If approved, navigate to teacher dashboard
    if (teacherProvider.isApproved && mounted) {
      context.go('/teacher/dashboard');
    }
    // If rejected, show rejection reason
    else if (teacherProvider.isRejected && mounted) {
      _showRejectionDialog();
    }
  }

  void _showRejectionDialog() {
    final teacherProvider = Provider.of<TeacherProvider>(
      context,
      listen: false,
    );
    final reason =
        teacherProvider.currentTeacher?.rejectionReason ?? 'No reason provided';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Account Rejected'),
            content: Text(
              'Your account has been rejected by the admin.\n\nReason: $reason',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  teacherProvider.logout();
                  context.go('/teacher/signup');
                },
                child: const Text('Sign Up Again'),
              ),
              TextButton(
                onPressed: () {
                  teacherProvider.logout();
                  context.go('/');
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
    );
  }

  void _logout() {
    final teacherProvider = Provider.of<TeacherProvider>(
      context,
      listen: false,
    );
    teacherProvider.logout();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final teacherProvider = Provider.of<TeacherProvider>(context);
    final teacher = teacherProvider.currentTeacher;

    if (teacher == null) {
      // If no teacher is logged in, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/teacher/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.hourglass_top,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Account Pending Approval',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hello, ${teacher.firstname} ${teacher.lastname}!',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your account has been submitted for approval. Once an administrator approves your account, you\'ll be able to log in and access the teacher dashboard.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          onPressed:
                              teacherProvider.isLoading ? null : _checkStatus,
                          backgroundColor: AppColors.secondary,
                          child: const Text('Check Status'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          onPressed: _logout,
                          backgroundColor: Colors.grey.shade700,
                          child: const Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
