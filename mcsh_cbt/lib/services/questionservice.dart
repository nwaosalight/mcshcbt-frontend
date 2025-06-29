import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mcsh_cbt/services/framents.dart';

class QuestionService {
  final GraphQLClient _client;

  QuestionService(this._client);

  // Get Question by ID
  static const String getQuestionQuery = '''
    ${GraphQLFragments.questionFields}
    ${GraphQLFragments.errorFields}
    
    query GetQuestion(\$id: ID!) {
      question(id: \$id) {
        ... on Question {
          ...QuestionFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> getQuestion(String id) async {
    final QueryOptions options = QueryOptions(
      document: gql(getQuestionQuery),
      variables: {'id': id},
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['question']['__typename'] == 'Error') {
      throw Exception(result.data?['question']['message']);
    }

    return result.data?['question'];
  }

  // Get Exam Questions
  static const String getExamQuestionsQuery = '''
    ${GraphQLFragments.questionFields}
    ${GraphQLFragments.pageInfoFields}
    ${GraphQLFragments.errorFields}
    
    query GetExamQuestions(\$examId: ID!, \$pagination: PaginationInput) {
      examQuestions(examId: \$examId, pagination: \$pagination) {
        ... on QuestionConnection {
          edges {
            cursor
            node {
              ...QuestionFields
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

  Future<Map<String, dynamic>?> getExamQuestions({
    required String examId,
    Map<String, dynamic>? pagination,
  }) async {
    final QueryOptions options = QueryOptions(
      document: gql(getExamQuestionsQuery),
      variables: {
        'examId': examId,
        'pagination': pagination,
      },
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['examQuestions']['__typename'] == 'Error') {
      throw Exception(result.data?['examQuestions']['message']);
    }

    return result.data?['examQuestions'];
  }

  // Create Question
  static const String createQuestionMutation = '''
    ${GraphQLFragments.questionFields}
    ${GraphQLFragments.errorFields}
    
    mutation CreateQuestion(\$input: CreateQuestionInput!) {
      createQuestion(input: \$input) {
        ... on Question {
          ...QuestionFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> createQuestion({
    required String examId,
    required int questionNumber,
    required String text,
    required String questionType,
    required List<Map<String, dynamic>>? opts,
    required String correctAnswer,
    double? points,
    String? difficultyLevel,
    List<String>? tags,
    String? feedback,
    String? image,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(createQuestionMutation),
      variables: {
        'input': {
          'examId': examId,
          'questionNumber': questionNumber,
          'text': text,
          'questionType': questionType,
          if (opts != null) 'options': opts,
          'correctAnswer': correctAnswer,
          if (points != null) 'points': points,
          if (difficultyLevel != null) 'difficultyLevel': difficultyLevel,
          if (tags != null) 'tags': tags,
          if (feedback != null) 'feedback': feedback,
          if (image != null) 'image': image,
        },
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['createQuestion']['__typename'] == 'Error') {
      throw Exception(result.data?['createQuestion']['message']);
    }

    return result.data?['createQuestion'];
  }

  // Update Question
  static const String updateQuestionMutation = '''
    ${GraphQLFragments.questionFields}
    ${GraphQLFragments.errorFields}
    
    mutation UpdateQuestion(\$id: ID!, \$input: UpdateQuestionInput!) {
      updateQuestion(id: \$id, input: \$input) {
        ... on Question {
          ...QuestionFields
        }
        ... on Error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> updateQuestion({
    required String id,
    int? questionNumber,
    String? text,
    String? questionType,
    List<Map<String, dynamic>>? opts,
    String? correctAnswer,
    double? points,
    String? difficultyLevel,
    List<String>? tags,
    String? feedback,
    String? image,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(updateQuestionMutation),
      variables: {
        'id': id,
        'input': {
          if (questionNumber != null) 'questionNumber': questionNumber,
          if (text != null) 'text': text,
          if (questionType != null) 'questionType': questionType,
          if (opts != null) 'options': opts,
          if (correctAnswer != null) 'correctAnswer': correctAnswer,
          if (points != null) 'points': points,
          if (difficultyLevel != null) 'difficultyLevel': difficultyLevel,
          if (tags != null) 'tags': tags,
          if (feedback != null) 'feedback': feedback,
          if (image != null) 'image': image,
        },
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['updateQuestion']['__typename'] == 'Error') {
      throw Exception(result.data?['updateQuestion']['message']);
    }

    return result.data?['updateQuestion'];
  }

  // Delete Question
  static const String deleteQuestionMutation = '''
    ${GraphQLFragments.errorFields}
    
    mutation DeleteQuestion(\$id: ID!) {
      deleteQuestion(id: \$id) {
        success
        error {
          ...ErrorFields
        }
      }
    }
  ''';

  Future<bool> deleteQuestion(String id) async {
    final MutationOptions options = MutationOptions(
      document: gql(deleteQuestionMutation),
      variables: {'id': id},
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['deleteQuestion']['error'] != null) {
      throw Exception(result.data?['deleteQuestion']['error']['message']);
    }

    return result.data?['deleteQuestion']['success'] ?? false;
  }
}
