import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mcsh_cbt/services/framents.dart';

class SubjectService {
  final GraphQLClient _client;

  SubjectService(this._client);

  // Get Subject by ID
  static const String getSubjectQuery = '''
    ${GraphQLFragments.subjectDetailFields}
    ${GraphQLFragments.userFields}
    ${GraphQLFragments.examFields}
    ${GraphQLFragments.errorFields}
    
    query GetSubject(\$id: ID!) {
      subject(id: \$id) {
        ... on Subject {
          ...SubjectDetailFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> getSubject(String id) async {
    final QueryOptions options = QueryOptions(
      document: gql(getSubjectQuery),
      variables: {'id': id},
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['subject']['__typename'] == 'Error') {
      throw Exception(result.data?['subject']['message']);
    }

    return result.data?['subject'];
  }

  // Get Subject by Code
  static const String getSubjectByCodeQuery = '''
    ${GraphQLFragments.subjectDetailFields}
    ${GraphQLFragments.userFields}
    ${GraphQLFragments.examFields}
    ${GraphQLFragments.errorFields}
    
    query GetSubjectByCode(\$code: String!) {
      subjectByCode(code: \$code) {
        ... on Subject {
          ...SubjectDetailFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> getSubjectByCode(String code) async {
    final QueryOptions options = QueryOptions(
      document: gql(getSubjectByCodeQuery),
      variables: {'subjectCode': code},
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['subjectByCode']['__typename'] == 'Error') {
      throw Exception(result.data?['subjectByCode']['message']);
    }

    return result.data?['subjectByCode'];
  }

  // Get Subjects with Filtering, Sorting, and Pagination
  static const String getSubjectsQuery = '''
    ${GraphQLFragments.subjectFields}
    ${GraphQLFragments.pageInfoFields}
    ${GraphQLFragments.errorFields}
    
    query GetSubjects(\$filter: SubjectFilterInput, \$sort: SubjectSortInput, \$pagination: PaginationInput) {
      subjects(filter: \$filter, sort: \$sort, pagination: \$pagination) {
        ... on SubjectConnection {
          edges {
            cursor
            node {
              ...SubjectFields
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

  Future<Map<String, dynamic>?> getSubjects({
    Map<String, dynamic>? filter,
    Map<String, dynamic>? sort,
    Map<String, dynamic>? pagination,
  }) async {
    final QueryOptions options = QueryOptions(
      document: gql(getSubjectsQuery),
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

    if (result.data?['subjects']['__typename'] == 'Error') {
      throw Exception(result.data?['subjects']['message']);
    }

    return result.data?['subjects'];
  }

  // Create Subject
  static const String createSubjectMutation = '''
    ${GraphQLFragments.subjectFields}
    ${GraphQLFragments.errorFields}
    
    mutation CreateSubject(\$input: CreateSubjectInput!) {
      createSubject(input: \$input) {
        ... on Subject {
          ...SubjectFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> createSubject({
    required String subjectCode,
    required String name,
    String? description,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(createSubjectMutation),
      variables: {
        'input': {
          'code': subjectCode,
          'name': name,
          if (description != null) 'description': description,
        },
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['createSubject']['__typename'] == 'Error') {
      throw Exception(result.data?['createSubject']['message']);
    }

    return result.data?['createSubject'];
  }

  // Update Subject
  static const String updateSubjectMutation = '''
    ${GraphQLFragments.subjectFields}
    ${GraphQLFragments.errorFields}
    
    mutation UpdateSubject(\$id: ID!, \$input: UpdateSubjectInput!) {
      updateSubject(id: \$id, input: \$input) {
        ... on Subject {
          ...SubjectFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> updateSubject({
    required String id,
    String? code,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(updateSubjectMutation),
      variables: {
        'id': id,
        'input': {
          if (code != null) 'code': code,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (isActive != null) 'isActive': isActive,
        },
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['updateSubject']['__typename'] == 'Error') {
      throw Exception(result.data?['updateSubject']['message']);
    }

    return result.data?['updateSubject'];
  }

  // Delete Subject
  static const String deleteSubjectMutation = '''
    ${GraphQLFragments.errorFields}
    
    mutation DeleteSubject(\$id: ID!) {
      deleteSubject(id: \$id) {
        success
        error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<bool> deleteSubject(String id) async {
    final MutationOptions options = MutationOptions(
      document: gql(deleteSubjectMutation),
      variables: {'id': id},
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['deleteSubject']['error'] != null) {
      throw Exception(result.data?['deleteSubject']['error']['message']);
    }

    return result.data?['deleteSubject']['success'] ?? false;
  }
}