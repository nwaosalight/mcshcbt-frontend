import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mcsh_cbt/services/config.dart';
import 'package:mcsh_cbt/services/framents.dart';

class AuthService {
  final GraphQLClient _client;

  AuthService(this._client);

  // Sign Up
  static const String signupMutation = '''
    ${GraphQLFragments.userFields}
    
    mutation Signup(\$input: CreateUserInput!) {
      signup(input: \$input) {
        token
        user {
          ...UserFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? role,
    String? phoneNumber,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(signupMutation),
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

    return result.data?['signup'];
  }

  // Login
  static const String loginMutation = '''
    ${GraphQLFragments.userFields}
    ${GraphQLFragments.errorFields}
    
    mutation Login(\$input: LoginInput!) {
      login(input: \$input) {
        ... on AuthPayload {
          token
          user {
            ...UserFields
          }
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(loginMutation),
      variables: {
        'input': {
          'email': email,
          'password': password,
        },
      },
    );



    final QueryResult result = await _client.mutate(options);



    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['login']['__typename'] == 'Error') {
      throw Exception(result.data?['login']['message']);
    }

    final String? token = result.data?['login']['token'];
    if (token != null) {
      await GraphQLConfig.instance.setToken(token);
    }

    return result.data?['login'];
  }

  // Logout
  static const String logoutMutation = '''
    mutation Logout {
      logout {
        success
        error {
          message
          code
        }
      }
    }
  ''';

  Future<bool> logout() async {
    final MutationOptions options = MutationOptions(
      document: gql(logoutMutation),
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['logout']['success'] == true) {
      await GraphQLConfig.instance.clearToken();
      return true;
    }

    return false;
  }

  // Current User
  static const String meQuery = '''
    ${GraphQLFragments.userDetailFields}
    ${GraphQLFragments.subjectFields}
    ${GraphQLFragments.gradeFields}
    ${GraphQLFragments.notificationFields}
    
    query Me {
      me {
        ... on User {
          ...UserDetailFields
        }
        ... on Error {
          message
          code
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final QueryOptions options = QueryOptions(
      document: gql(meQuery),
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['me']['__typename'] == 'Error') {
      throw Exception(result.data?['me']['message']);
    }

    return result.data?['me'];
  }
}