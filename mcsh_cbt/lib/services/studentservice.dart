import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mcsh_cbt/services/framents.dart';

class StudentExamService {
  final GraphQLClient _client;

  StudentExamService(this._client);

  // Get StudentExam by ID
  static const String getStudentExamQuery = '''
    query GetStudentExam(\$id: ID!) {
      studentExam(id: \$id) {
        ... on StudentExam {
          id
          uuid
          startTime
          endTime
          timeSpent
          score
          isPassed
          status
          createdAt
          updatedAt
          progress
          remainingTime
          answeredCount
          markedCount
          student {
            id
            uuid
            firstName
            lastName
            email
            role
            status
            profileImage
            phoneNumber
            lastLogin
            createdAt
            updatedAt
            fullName
          }
          exam {
            id
            title
            description
            duration
            passmark
            shuffleQuestions
            allowReview
            showResults
            startDate
            endDate
            status
            instructions
            createdAt
            updatedAt
            questionCount
            totalPoints
          }
          answers {
            id
            uuid
            selectedAnswer
            isCorrect
            isMarked
            timeTaken
            answeredAt
            createdAt
            updatedAt
            question {
              id
              uuid
              questionNumber
              text
              questionType
              options
              correctAnswer
              points
              difficultyLevel
              tags
              feedback
              image
              createdAt
              updatedAt
            }
          }
        }
        ... on Error {
          message
          code
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> getStudentExam(String id) async {
    final QueryOptions options = QueryOptions(
      document: gql(getStudentExamQuery),
      variables: {'id': id},
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['studentExam']['__typename'] == 'Error') {
      throw Exception(result.data?['studentExam']['message']);
    }

    return result.data?['studentExam'];
  }

  static const String getStudentExamsQuery = '''
  ${GraphQLFragments.errorFields}
  ${GraphQLFragments.studentExamFields}
  ${GraphQLFragments.examFields}
  ${GraphQLFragments.pageInfoFields}
  
  query GetStudentExams(\$filter: StudentExamFilterInput, \$sort: StudentExamSortInput, \$pagination: PaginationInput) {
    studentExams(filter: \$filter, sort: \$sort, pagination: \$pagination) {
      ... on StudentExamConnection {
        edges {
          cursor
          node {
            ...StudentExamFields
            exam {
              ...ExamFields
            }
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

  Future<Map<String, dynamic>?> getStudentExams({
    Map<String, dynamic>? filter,
    Map<String, dynamic>? sort,
    Map<String, dynamic>? pagination,
  }) async {
    final QueryOptions options = QueryOptions(
      document: gql(getStudentExamsQuery),
      variables: {
        'filter': filter,
        'sort': sort,
        'pagination': pagination,
      }..removeWhere((key, value) => value == null),
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['studentExams']['__typename'] == 'Error') {
      throw Exception(result.data?['studentExams']['message']);
    }

    return result.data?['studentExams'];
  }

  // Existing mutations (unchanged)
  static const String startExamMutation = '''
    mutation StartExam(\$input: StartExamInput!) {
      startExam(input: \$input) {
        ... on StudentAnswer {
          id
          uuid
          selectedAnswer
          isCorrect
          isMarked
          timeTaken
          answeredAt
          createdAt
          updatedAt
          student {
            id
            uuid
            firstName
            lastName
            email
            role
            status
            profileImage
            phoneNumber
            lastLogin
            createdAt
            updatedAt
            fullName
          }
          question {
            id
            uuid
            questionNumber
            text
            questionType
            options
            correctAnswer
            points
            difficultyLevel
            tags
            feedback
            image
            createdAt
            updatedAt
          }
          studentExam {
            id
            uuid
            startTime
            endTime
            timeSpent
            score
            isPassed
            status
            createdAt
            updatedAt
            progress
            remainingTime
            answeredCount
            markedCount
          }
        }
        ... on Error {
          message
          code
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> startExam({
    required String examId,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(startExamMutation),
      variables: {
        'input': {
          'examId': examId,
        },
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['startExam']['__typename'] == 'Error') {
      throw Exception(result.data?['startExam']['message']);
    }

    return result.data?['startExam'];
  }

  static const String submitAnswerMutation = '''
    mutation SubmitAnswer(\$input: SubmitAnswerInput!) {
      submitAnswer(input: \$input) {
        ... on StudentAnswer {
          id
          uuid
          selectedAnswer
          isCorrect
          isMarked
          timeTaken
          answeredAt
          createdAt
          updatedAt
          student {
            id
            uuid
            firstName
            lastName
            email
            role
            status
            profileImage
            phoneNumber
            lastLogin
            createdAt
            updatedAt
            fullName
          }
          question {
            id
            uuid
            questionNumber
            text
            questionType
            options
            correctAnswer
            points
            difficultyLevel
            tags
            feedback
            image
            createdAt
            updatedAt
          }
          studentExam {
            id
            uuid
            startTime
            endTime
            timeSpent
            score
            isPassed
            status
            createdAt
            updatedAt
            progress
            remainingTime
            answeredCount
            markedCount
          }
        }
        ... on Error {
          message
          code
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> submitAnswer({
    required String studentExamId,
    required String questionId,
    String? selectedAnswer,
    bool? isMarked,
    int? timeTaken,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(submitAnswerMutation),
      variables: {
        'input': {
          'studentExamId': studentExamId,
          'questionId': questionId,
          if (selectedAnswer != null) 'selectedAnswer': selectedAnswer,
          if (isMarked != null) 'isMarked': isMarked,
          if (timeTaken != null) 'timeTaken': timeTaken,
        }..removeWhere((key, value) => value == null),
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['submitAnswer']['__typename'] == 'Error') {
      throw Exception(result.data?['submitAnswer']['message']);
    }

    return result.data?['submitAnswer'];
  }

  static const String submitExamMutation = '''
    mutation SubmitExam(\$input: SubmitExamInput!) {
      submitExam(input: \$input) {
        ... on StudentExam {
          id
          uuid
          startTime
          endTime
          timeSpent
          score
          isPassed
          status
          createdAt
          updatedAt
          progress
          remainingTime
          answeredCount
          markedCount
          student {
            id
            uuid
            firstName
            lastName
            email
            role
            status
            profileImage
            phoneNumber
            lastLogin
            createdAt
            updatedAt
            fullName
          }
          exam {
            id
            uuid
            title
            description
            duration
            passmark
            shuffleQuestions
            allowReview
            showResults
            startDate
            endDate
            status
            instructions
            createdAt
            updatedAt
            questionCount
            totalPoints
          }
        }
        ... on Error {
          message
          code
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> submitExam({
    required String studentExamId,
    List<Map<String, dynamic>>? answers,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(submitExamMutation),
      variables: {
        'input': {
          'studentExamId': studentExamId,
          if (answers != null) 'answers': answers,
        }..removeWhere((key, value) => value == null),
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['submitExam']['__typename'] == 'Error') {
      throw Exception(result.data?['submitExam']['message']);
    }

    return result.data?['submitExam'];
  }
}