import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mcsh_cbt/services/framents.dart';

class NotificationService {
  final GraphQLClient _client;

  NotificationService(this._client);

  // Get Notification by ID
  static const String getNotificationQuery = '''
    ${GraphQLFragments.notificationFields}
    ${GraphQLFragments.errorFields}
    
    query GetNotification(\$id: ID!) {
      notification(id: \$id) {
        ... on Notification {
          ...NotificationFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> getNotification(String id) async {
    final QueryOptions options = QueryOptions(
      document: gql(getNotificationQuery),
      variables: {'id': id},
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['notification']['__typename'] == 'Error') {
      throw Exception(result.data?['notification']['message']);
    }

    return result.data?['notification'];
  }
}