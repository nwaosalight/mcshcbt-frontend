class ExamQuestions {
  final int totalCount;
  final List<QuestionEdge> edges;
  final PageInfo pageInfo;

  ExamQuestions({
    required this.totalCount,
    required this.edges,
    required this.pageInfo,
  });

  factory ExamQuestions.fromJson(Map<String, dynamic> json) {
    return ExamQuestions(
      totalCount: json['totalCount'],
      edges: (json['edges'] as List<dynamic>)
          .map((e) => QuestionEdge.fromJson(e))
          .toList(),
      pageInfo: PageInfo.fromJson(json['pageInfo']),
    );
  }
}

class QuestionEdge {
  final String cursor;
  final ExamQuestion node;

  QuestionEdge({
    required this.cursor,
    required this.node,
  });

  factory QuestionEdge.fromJson(Map<String, dynamic> json) {
    return QuestionEdge(
      cursor: json['cursor'],
      node: ExamQuestion.fromJson(json['node']),
    );
  }
}

class ExamQuestion {
  final String id;
  final String uuid;
  final int questionNumber;
  final String text;
  final String questionType;
  final List<Map<String, String>> options;
  final String correctAnswer;
  final int points;
  final String? difficultyLevel;
  final List<dynamic> tags;
  final String? feedback;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamQuestion({
    required this.id,
    required this.uuid,
    required this.questionNumber,
    required this.text,
    required this.questionType,
    required this.options,
    required this.correctAnswer,
    required this.points,
    this.difficultyLevel,
    required this.tags,
    this.feedback,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id'],
      uuid: json['uuid'],
      questionNumber: json['questionNumber'],
      text: json['text'],
      questionType: json['questionType'],
      options: (json['options'] as List<dynamic>)
          .map((opt) => Map<String, String>.from(opt))
          .toList(),
      correctAnswer: json['correctAnswer'],
      points: json['points'],
      difficultyLevel: json['difficultyLevel'],
      tags: json['tags'] ?? [],
      feedback: json['feedback'],
      image: json['image'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Extracts the list of subjects from the `edges` data.
  static List<ExamQuestion> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((edge) => ExamQuestion.fromJson(edge['node'])).toList();
  }
}

class PageInfo {
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String startCursor;
  final String endCursor;

  PageInfo({
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.startCursor,
    required this.endCursor,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) {
    return PageInfo(
      hasNextPage: json['hasNextPage'],
      hasPreviousPage: json['hasPreviousPage'],
      startCursor: json['startCursor'],
      endCursor: json['endCursor'],
    );
  }
}
