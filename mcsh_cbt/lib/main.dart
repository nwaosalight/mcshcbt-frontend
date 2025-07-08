import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mcsh_cbt/features/exam/providers/exam.provider.dart';
import 'package:mcsh_cbt/features/exam/providers/user.provider.dart';
import 'package:mcsh_cbt/features/subject/providers/subject_provider.dart';
import 'package:mcsh_cbt/setup.dart';
import 'package:provider/provider.dart';

import 'common/utils/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/admin_provider.dart';
import 'features/auth/providers/teacher_provider.dart';
import 'features/question/providers/question_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style to match our theme
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.primary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await setupLocator(); // Await dependency setup
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QuestionProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Mountain Crest Exam CBT',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}