import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mcsh_cbt/features/exam/models/examination.dart';
import 'package:mcsh_cbt/features/exam/screens/exam_dashboard.dart';
import 'package:mcsh_cbt/screens/create.examination.dart';
import 'package:mcsh_cbt/screens/exam.management.dart';
import 'package:mcsh_cbt/screens/exam_screen.dart';
import 'package:mcsh_cbt/screens/login_screen.dart';
import 'package:mcsh_cbt/screens/result.management.screen.dart';
import 'package:mcsh_cbt/screens/student.management.dart';
import 'package:mcsh_cbt/screens/subject_examination.dart';
import 'package:mcsh_cbt/screens/teacher.management.dart';
import 'package:mcsh_cbt/screens/teacher_subject_screen.dart';

import '../../features/auth/screens/admin_dashboard_screen.dart';
import '../../features/auth/screens/admin_login_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/teacher_login_screen.dart';
import '../../features/auth/screens/teacher_pending_screen.dart';
import '../../features/auth/screens/teacher_signup_screen.dart';
import '../../features/exam/screens/exam_results_screen.dart';
import '../../features/question/screens/question_creator_screen.dart';
import '../../features/question/screens/question_manager_screen.dart';
import '../../screens/signup.screen.dart' show SignupScreen;

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Role Selection - Initial Route
      GoRoute(
        path: '/',
        name: 'roleSelection',
        builder: (context, state) => const RoleSelectionScreen(),
        // builder: (context, state) => const LoginScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/teacher/login',
        name: 'teacherLogin',
        builder: (context, state) => const TeacherLoginScreen(),
      ),
      GoRoute(
        path: '/teacher/signup',
        name: 'teacherSignup',
        builder: (context, state) => const TeacherSignupScreen(),
      ),
      GoRoute(
        path: '/teacher/pending',
        name: 'teacherPending',
        builder: (context, state) => const TeacherPendingScreen(),
      ),
      GoRoute(
        path: '/admin/login',
        name: 'adminLogin',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/teachermanagement',
        name: 'adminTeacherManagement',
        builder: (context, state) => const TeacherManagementScreen(),
      ),
      GoRoute(
        path: '/admin/examsMangement',
        name: 'adminExamsManagement',
        builder: (context, state) => const AdminExamsManagementPage(),
      ),
      GoRoute(
        path: '/admin/resultsManagement',
        name: 'adminResultsManagement',
        builder: (context, state) => const ExamResultDashboard(),
      ),
      // Teacher Routes
      GoRoute(
        path: '/teacher/subjects',
        name: 'teacherSubjects',
        builder: (context, state) => const TeacherSubjectScreen(),
      ),
      GoRoute(
        path: '/teacher/question-creator',
        name: 'questionCreator',
        builder: (context, state) => const QuestionCreatorScreen(),
      ),
      GoRoute(
        path: '/teacher/question-manager',
        name: 'questionManager',
        builder: (context, state) {
          // Extract the subject from query parameters
          final subject = state.uri.queryParameters['subject'] ?? '';
          return QuestionManagerScreen(subjectId: subject);
        },
      ),
      // Student Routes
      GoRoute(
        path: '/student/dashboard',
        name: 'examDashboard',
        builder: (context, state) => const ExamDashboard(),
      ),
      GoRoute(
        path: '/student/exam',
        name: 'exam',
        builder: (context, state) {
          return ExamScreen();
        },
      ),
      GoRoute(
        path: '/student/results',
        name: 'examResults',
        builder: (context, state) => const ExamResultsScreen(),
      ),
      GoRoute(
        path: '/subject/exams',
        name: 'subjectExams',
        builder: (context, state) => const SubjectExaminationsScreen(),
      ),
      GoRoute(
        path: '/subject/exams/create',
        name: 'createExam',
        builder: (context, state) => const CreateExaminationScreen(),
      ),
      GoRoute(
        path: '/students',
        name: 'students',
        builder: (context, state) => const StudentManagementScreen(),
      ),
    ],
  );
}
