// main.dart or setup.dart
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mcsh_cbt/hive.dart';
import 'package:mcsh_cbt/services/authservice.dart';
import 'package:mcsh_cbt/services/config.dart';
import 'package:mcsh_cbt/services/examservice.dart';
import 'package:mcsh_cbt/services/gradeservice.dart';
import 'package:mcsh_cbt/services/notificationservice.dart';
import 'package:mcsh_cbt/services/questionservice.dart';
import 'package:mcsh_cbt/services/storage_service.dart';
import 'package:mcsh_cbt/services/studentservice.dart';
import 'package:mcsh_cbt/services/subjectservice.dart';
import 'package:mcsh_cbt/services/userservice.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  // Step 1: Initialize Hive first before any other services
  await initHiveForGraphQL();
  
  // Step 2: Register and initialize StorageService
  getIt.registerSingletonAsync<StorageService>(() async {
    final service = StorageService();
    await service.init();
    return service;
  });
  
  // Step 3: Wait for StorageService to initialize
  await getIt.isReady<StorageService>();
  
  // Step 4: Register GraphQLConfig with the initialized StorageService
  getIt.registerSingleton<GraphQLConfig>(GraphQLConfig.instance);
  
  // Step 5: Initialize GraphQLConfig
  await getIt<GraphQLConfig>().initialize();
  
  // Step 6: Register all services that depend on GraphQLClient
  // Using factory to ensure we get a fresh client each time
  getIt.registerFactoryAsync<GraphQLClient>(() async {
    final clientNotifier = await getIt<GraphQLConfig>().getClient();
    return clientNotifier.value;
  });
  
  // Step 7: Register all other services
  getIt.registerLazySingletonAsync<AuthService>(() async {
    final client = await getIt.getAsync<GraphQLClient>();
    return AuthService(client);
  });
  
  getIt.registerLazySingletonAsync<ExamService>(() async {
    final client = await getIt.getAsync<GraphQLClient>();
    return ExamService(client);
  });
  
  getIt.registerLazySingletonAsync<GradeService>(() async {
    final client = await getIt.getAsync<GraphQLClient>();
    return GradeService(client);
  });
  
  getIt.registerLazySingletonAsync<QuestionService>(() async {
    final client = await getIt.getAsync<GraphQLClient>();
    return QuestionService(client);
  });
  
  getIt.registerLazySingletonAsync<StudentExamService>(() async {
    final client = await getIt.getAsync<GraphQLClient>();
    return StudentExamService(client);
  });
  
  getIt.registerLazySingletonAsync<SubjectService>(() async {
    final client = await getIt.getAsync<GraphQLClient>();
    return SubjectService(client);
  });
  
  getIt.registerLazySingletonAsync<UserService>(() async {
    final client = await getIt.getAsync<GraphQLClient>();
    return UserService(client);
  });
  
  getIt.registerLazySingletonAsync<NotificationService>(() async {
    final client = await getIt.getAsync<GraphQLClient>();
    return NotificationService(client);
  });
}