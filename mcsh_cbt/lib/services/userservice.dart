import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mcsh_cbt/services/framents.dart';

class UserService {
  final GraphQLClient _client;

  UserService(this._client);

  // Get User by ID
  static const String getUserQuery = '''
    ${GraphQLFragments.userDetailFields}
    ${GraphQLFragments.subjectFields}
    ${GraphQLFragments.gradeFields}
    ${GraphQLFragments.notificationFields}
    ${GraphQLFragments.errorFields}
    
    query GetUser(\$id: ID!) {
      user(id: \$id) {
        ... on User {
          ...UserDetailFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> getUser(String id) async {
    final QueryOptions options = QueryOptions(
      document: gql(getUserQuery),
      variables: {'id': id},
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['user']['__typename'] == 'Error') {
      throw Exception(result.data?['user']['message']);
    }

    return result.data?['user'];
  }

  // Get Users with Filtering, Sorting, and Pagination
  static const String getUsersQuery = '''
    ${GraphQLFragments.userFields}
    ${GraphQLFragments.pageInfoFields}
    ${GraphQLFragments.errorFields}
    
    query GetUsers(\$filter: UserFilterInput, \$sort: UserSortInput, \$pagination: PaginationInput) {
      users(filter: \$filter, sort: \$sort, pagination: \$pagination) {
        ... on UserConnection {
          edges {
            cursor
            node {
              ...UserFields
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

  Future<Map<String, dynamic>?> getUsers({
    Map<String, dynamic>? filter,
    Map<String, dynamic>? sort,
    Map<String, dynamic>? pagination,
  }) async {
    final QueryOptions options = QueryOptions(
      document: gql(getUsersQuery),
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

    if (result.data?['users']['__typename'] == 'Error') {
      throw Exception(result.data?['users']['message']);
    }

    return result.data?['users'];
  }

  // Create User
  static const String createUserMutation = '''
    ${GraphQLFragments.userFields}
    ${GraphQLFragments.errorFields}
    
    mutation CreateUser(\$input: CreateUserInput!) {
      createUser(input: \$input) {
        ... on User {
          ...UserFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? role,
    String? phoneNumber,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(createUserMutation),
      variables: {
        'input': {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'role': role,
          'phoneNumber': phoneNumber,
        },
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['createUser']['__typename'] == 'Error') {
      throw Exception(result.data?['createUser']['message']);
    }

    return result.data?['createUser'];
  }

  // Update User
  static const String updateUserMutation = '''
    ${GraphQLFragments.userFields}
    ${GraphQLFragments.errorFields}
    
    mutation UpdateUser(\$id: ID!, \$input: UpdateUserInput!) {
      updateUser(id: \$id, input: \$input) {
        ... on User {
          ...UserFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> updateUser({
    required String id,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? role,
    String? status,
    String? profileImage,
    String? phoneNumber,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(updateUserMutation),
      variables: {
        'id': id,
        'input': {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (email != null) 'email': email,
          if (password != null) 'password': password,
          if (role != null) 'role': role,
          if (status != null) 'status': status,
          if (profileImage != null) 'profileImage': profileImage,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['updateUser']['__typename'] == 'Error') {
      throw Exception(result.data?['updateUser']['message']);
    }

    return result.data?['updateUser'];
  }

  // Delete User
  static const String deleteUserMutation = '''
    ${GraphQLFragments.errorFields}
    
    mutation DeleteUser(\$id: ID!) {
      deleteUser(id: \$id) {
        success
        error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<bool> deleteUser(String id) async {
    final MutationOptions options = MutationOptions(
      document: gql(deleteUserMutation),
      variables: {'id': id},
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['deleteUser']['error'] != null) {
      throw Exception(result.data?['deleteUser']['error']['message']);
    }

    return result.data?['deleteUser']['success'] ?? false;
  }
}
