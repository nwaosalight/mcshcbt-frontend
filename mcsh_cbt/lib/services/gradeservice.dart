


import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mcsh_cbt/services/framents.dart';

class GradeService {
  final GraphQLClient _client;

  GradeService(this._client);

  // Get Grade by ID
  static const String getGradeQuery = '''
    ${GraphQLFragments.gradeDetailFields}
    ${GraphQLFragments.userFields}
    ${GraphQLFragments.examFields}
    ${GraphQLFragments.errorFields}
    
    query GetGrade(\$id: ID!) {
      grade(id: \$id) {
        ... on Grade {
          ...GradeDetailFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> getGrade(String id) async {
    final QueryOptions options = QueryOptions(
      document: gql(getGradeQuery),
      variables: {'id': id},
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['grade']['__typename'] == 'Error') {
      throw Exception(result.data?['grade']['message']);
    }

    return result.data?['grade'];
  }

  // Get Grades with Filtering, Sorting, and Pagination
  static const String getGradesQuery = '''
    ${GraphQLFragments.gradeFields}
    ${GraphQLFragments.pageInfoFields}
    ${GraphQLFragments.errorFields}
    
    query GetGrades(\$filter: GradeFilterInput, \$sort: GradeSortInput, \$pagination: PaginationInput) {
      grades(filter: \$filter, sort: \$sort, pagination: \$pagination) {
        ... on GradeConnection {
          edges {
            cursor
            node {
              ...GradeFields
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

  Future<Map<String, dynamic>?> getGrades({
    Map<String, dynamic>? filter,
    Map<String, dynamic>? sort,
    Map<String, dynamic>? pagination,
  }) async {
    final QueryOptions options = QueryOptions(
      document: gql(getGradesQuery),
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

    if (result.data?['grades']['__typename'] == 'Error') {
      throw Exception(result.data?['grades']['message']);
    }

    return result.data?['grades'];
  }

  // Create Grade
  static const String createGradeMutation = '''
    ${GraphQLFragments.gradeFields}
    ${GraphQLFragments.errorFields}
    
    mutation CreateGrade(\$input: CreateGradeInput!) {
      createGrade(input: \$input) {
        ... on Grade {
          ...GradeFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> createGrade({
    required String name,
    String? description,
    required String academicYear,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(createGradeMutation),
      variables: {
        'input': {
          'name': name,
          if (description != null) 'description': description,
          'academicYear': academicYear,
        },
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    

    if (result.data?['createGrade']['__typename'] == 'Error') {
      throw Exception(result.data?['createGrade']['message']);
    }

    return result.data?['createGrade'];
    
  }

  static const String updateGradeMutation = '''
    ${GraphQLFragments.gradeFields}
    ${GraphQLFragments.errorFields}
    
    mutation UpdateGrade(\$id: ID!, \$input: UpdateGradeInput!) {
      updateGrade(id: \$id, input: \$input) {
        ... on Grade {
          ...GradeFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> updateGrade({
    required String id,
    String? name,
    String? description,
    String? academicYear,
    bool? isActive,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(updateGradeMutation),
      variables: {
        'id': id,
        'input': {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (academicYear != null) 'academicYear': academicYear,
          if (isActive != null) 'isActive': isActive,
        },
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['updateGrade']['__typename'] == 'Error') {
      throw Exception(result.data?['updateGrade']['message']);
    }

    return result.data?['updateGrade'];
  }

  static const String deleteGradeMutation = '''
    ${GraphQLFragments.errorFields}
    
    mutation DeleteGrade(\$id: ID!) {
      deleteGrade(id: \$id) {
        success
        error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<bool> deleteGrade(String id) async {
    final MutationOptions options = MutationOptions(
      document: gql(deleteGradeMutation),
      variables: {'id': id},
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['deleteGrade']['error'] != null) {
      throw Exception(result.data?['deleteGrade']['error']['message']);
    }

    return result.data?['deleteGrade']['success'] ?? false;
  }

  static const String assignTeacherMutation = '''
    ${GraphQLFragments.errorFields}
    
    mutation AssignTeacher(\$input: AssignTeacherInput!) {
      assignTeacher(input: \$input) {
        success
        error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<bool> assignTeacher({
  required String teacherId,
  List<String>? subjectIds,
  List<String>? gradeIds,
}) async {
  // Ensure we're sending empty arrays instead of null when no IDs are provided
  final input = {
    'teacherId': teacherId,
    'subjectIds': subjectIds ?? [],
    'gradeIds': gradeIds ?? [],
  };

  final MutationOptions options = MutationOptions(
    document: gql(assignTeacherMutation),
    variables: {'input': input},
  );

  try {
    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['assignTeacher']['error'] != null) {
      throw Exception(result.data?['assignTeacher']['error']['message']);
    }

    return result.data?['assignTeacher']['success'] ?? false;
  } catch (e) {
    throw Exception('Failed to assign teacher: $e');
  }
}
  // Enroll Student
  static const String enrollStudentMutation = '''
    ${GraphQLFragments.errorFields}
    
    mutation EnrollStudent(\$input: EnrollStudentInput!) {
      enrollStudent(input: \$input) {
        success
        error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<bool> enrollStudent({
    required String studentId,
    required String gradeId,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(enrollStudentMutation),
      variables: {
        'input': {
          'studentId': studentId,
          'gradeId': gradeId,
        },
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['enrollStudent']['error'] != null) {
      throw Exception(result.data?['enrollStudent']['error']['message']);
    }

    return result.data?['enrollStudent']['success'] ?? false;
  }
}

