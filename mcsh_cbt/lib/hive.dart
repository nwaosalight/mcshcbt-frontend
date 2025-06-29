import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

Future<void> initHiveForGraphQL() async {
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  
  // Initialize for GraphQL Flutter
  await initHiveForFlutter();
}