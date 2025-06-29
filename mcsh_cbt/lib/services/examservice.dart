

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mcsh_cbt/services/framents.dart';

class ExamService {
  final GraphQLClient _client;

  ExamService(this._client);

  // Get Exam by ID
  static const String getExamQuery = '''
    ${GraphQLFragments.examDetailFields}
    ${GraphQLFragments.subjectFields}
    ${GraphQLFragments.gradeFields}
    ${GraphQLFragments.userFields}
    ${GraphQLFragments.errorFields}
    
    query GetExam(\$id: ID!) {
      exam(id: \$id) {
        ... on Exam {
          ...ExamDetailFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> getExam(String id) async {
    final QueryOptions options = QueryOptions(
      document: gql(getExamQuery),
      variables: {'id': id},
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['exam']['__typename'] == 'Error') {
      throw Exception(result.data?['exam']['message']);
    }

    return result.data?['exam'];
  }

  // Get Exams with Filtering, Sorting, and Pagination
  static const String getExamsQuery = '''
    ${GraphQLFragments.examFields}
    ${GraphQLFragments.pageInfoFields}
    ${GraphQLFragments.errorFields}
    
    query GetExams(\$filter: ExamFilterInput, \$sort: ExamSortInput, \$pagination: PaginationInput) {
      exams(filter: \$filter, sort: \$sort, pagination: \$pagination) {
        ... on ExamConnection {
          edges {
            cursor
            node {
              ...ExamFields
            }
          }
          pageInfo {
            ...PageInfoFields
          }
          totalCount
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> getExams({
    Map<String, dynamic>? filter,
    Map<String, dynamic>? sort,
    Map<String, dynamic>? pagination,
  }) async {
    final QueryOptions options = QueryOptions(
      document: gql(getExamsQuery),
      variables: {
        'filter': filter,
        'sort': sort,
        'pagination': pagination,
      },
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['exams']['__typename'] == 'Error') {
      throw Exception(result.data?['exams']['message']);
    }

    return result.data?['exams'];
  }

  // Create Exam
  static const String createExamMutation = '''
    ${GraphQLFragments.examFields}
    ${GraphQLFragments.errorFields}
    
    mutation CreateExam(\$input: CreateExamInput!) {
      createExam(input: \$input) {
        ... on Exam {
          ...ExamFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> createExam({
    required String title,
    String? description,
    required String subjectId,
    required String gradeId,
    required int duration,
    double? passmark,
    bool? shuffleQuestions,
    bool? allowReview,
    bool? showResults,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(createExamMutation),
      variables: {
        'input': {
          'title': title,
          if (description != null) 'description': description,
          'subjectId': subjectId,
          'gradeId': gradeId,
          'duration': duration,
          if (passmark != null) 'passmark': passmark,
          if (shuffleQuestions != null) 'shuffleQuestions': shuffleQuestions,
          if (allowReview != null) 'allowReview': allowReview,
          if (showResults != null) 'showResults': showResults,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          if (instructions != null) 'instructions': instructions,
        },
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['createExam']['__typename'] == 'Error') {
      throw Exception(result.data?['createExam']['message']);
    }

    return result.data?['createExam'];
  }

  // Update Exam
  static const String updateExamMutation = '''
    ${GraphQLFragments.examFields}
    ${GraphQLFragments.errorFields}
    
    mutation UpdateExam(\$id: ID!, \$input: UpdateExamInput!) {
      updateExam(id: \$id, input: \$input) {
        ... on Exam {
          ...ExamFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> updateExam({
    required String id,
    String? title,
    String? description,
    String? subjectId,
    String? gradeId,
    int? duration,
    double? passmark,
    bool? shuffleQuestions,
    bool? allowReview,
    bool? showResults,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? instructions,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(updateExamMutation),
      variables: {
        'id': id,
        'input': {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (subjectId != null) 'subjectId': subjectId,
          if (gradeId != null) 'gradeId': gradeId,
          if (duration != null) 'duration': duration,
          if (passmark != null) 'passmark': passmark,
          if (shuffleQuestions != null) 'shuffleQuestions': shuffleQuestions,
          if (allowReview != null) 'allowReview': allowReview,
          if (showResults != null) 'showResults': showResults,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          if (status != null) 'status': status,
          if (instructions != null) 'instructions': instructions,
        },
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['updateExam']['__typename'] == 'Error') {
      throw Exception(result.data?['updateExam']['message']);
    }

    return result.data?['updateExam'];
  }

  // Delete Exam
  static const String deleteExamMutation = '''
    ${GraphQLFragments.errorFields}
    
    mutation DeleteExam(\$id: ID!) {
      deleteExam(id: \$id) {
        success
        error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<bool> deleteExam(String id) async {
    final MutationOptions options = MutationOptions(
      document: gql(deleteExamMutation),
      variables: {'id': id},
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['deleteExam']['error'] != null) {
      throw Exception(result.data?['deleteExam']['error']['message']);
    }

    return result.data?['deleteExam']['success'] ?? false;
  }

  // Publish Exam
  static const String publishExamMutation = '''
    ${GraphQLFragments.examFields}
    ${GraphQLFragments.errorFields}
    
    mutation PublishExam(\$id: ID!) {
      publishExam(id: \$id) {
        ... on Exam {
          ...ExamFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> publishExam(String id) async {
    final MutationOptions options = MutationOptions(
      document: gql(publishExamMutation),
      variables: {'id': id},
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['publishExam']['__typename'] == 'Error') {
      throw Exception(result.data?['publishExam']['message']);
    }

    return result.data?['publishExam'];
  }

  // Archive Exam
  static const String archiveExamMutation = '''
    ${GraphQLFragments.examFields}
    ${GraphQLFragments.errorFields}
    
    mutation ArchiveExam(\$id: ID!) {
      archiveExam(id: \$id) {
        ... on Exam {
          ...ExamFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> archiveExam(String id) async {
    final MutationOptions options = MutationOptions(
      document: gql(archiveExamMutation),
      variables: {'id': id},
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['archiveExam']['__typename'] == 'Error') {
      throw Exception(result.data?['archiveExam']['message']);
    }

    return result.data?['archiveExam'];
  }
}