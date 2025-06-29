import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mcsh_cbt/services/storage_service.dart';
import 'package:get_it/get_it.dart';

class GraphQLConfig {
  static final GraphQLConfig _instance = GraphQLConfig._internal();
  static GraphQLConfig get instance => _instance;
  
  GraphQLConfig._internal();
  
  late StorageService storage;
  bool _isInitialized = false;
  
  ValueNotifier<GraphQLClient>? client;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Get the StorageService from GetIt
    storage = await GetIt.instance.getAsync<StorageService>();
    _isInitialized = true;
  }
  
  Future<ValueNotifier<GraphQLClient>> getClient() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (client != null) return client!;
    
    final token = storage.readString('auth_token');
    
    final HttpLink httpLink = HttpLink(
      'http://localhost:4000/graphql',
    );
    
    final AuthLink authLink = AuthLink(
      getToken: () async => token != null ? 'Bearer $token' : null,
    );
    
    final WebSocketLink webSocketLink = WebSocketLink(
      'ws://localhost:4000/graphql',
      config: SocketClientConfig(
        autoReconnect: true,
        inactivityTimeout: const Duration(seconds: 30),
        initialPayload: () async {
          final token = storage.readString('auth_token');
          return token != null ? {'Authorization': 'Bearer $token'} : {};
        },
      ),
    );
    
    final Link link = Link.split(
      (request) => request.isSubscription,
      webSocketLink,
      authLink.concat(httpLink),
    );
    
    client = ValueNotifier(
      GraphQLClient(
        link: link,
        cache: GraphQLCache(store: HiveStore()),
        defaultPolicies: DefaultPolicies(
          query: Policies(
            fetch: FetchPolicy.networkOnly,
            error: ErrorPolicy.all,
          ),
          mutate: Policies(
            fetch: FetchPolicy.networkOnly,
            error: ErrorPolicy.all,
          ),
          subscribe: Policies(
            fetch: FetchPolicy.networkOnly,
            error: ErrorPolicy.all,
          ),
        ),
      ),
    );
    
    return client!;
  }
  
  Future<void> setToken(String token) async {
    if (!_isInitialized) {
      await initialize();
    }
    await storage.saveString('auth_token', token);
    // Recreate client with new token
    client = null;
    await getClient();
  }
  
  Future<void> clearToken() async {
    if (!_isInitialized) {
      await initialize();
    }
    await storage.delete('auth_token');
    // Recreate client without token
    client = null;
    await getClient();
  }
}