enum ExamStatus { draft, published, closed }

enum ExamAttemptStatus { notStarted, inProgress, completed }

class Examination {
  final String id;
  final String uuid;
  final String title;
  final String? description;
  final int duration; 
  final double? passmark;
  final bool shuffleQuestions;
  final bool allowReview;
  final bool showResults;
  final DateTime? startDate;
  final DateTime? endDate;
  final ExamStatus status;
  final String? instructions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ExamAttemptStatus attemptStatus;
  final int questionCount; 
  final int totalPoints;

  Examination( {
    required this.id,
    required this.uuid,
    required this.title,
    this.description,
    // required this.subjectId,
    // required this.gradeId,
    // required this.createdById,
    required this.duration,
    this.passmark,
    this.shuffleQuestions = false,
    this.allowReview = false,
    this.showResults = false,
    this.startDate,
    this.endDate,
    this.status = ExamStatus.draft,
    this.instructions,
    required this.createdAt,
    required this.updatedAt,
    this.attemptStatus = ExamAttemptStatus.notStarted,
    required this.questionCount, 
    required this.totalPoints,
  });

factory Examination.fromJson(Map<String, dynamic> json) {
  return Examination(
    id: json['id'].toString(), // Convert to String in case it's an int
    uuid: json['uuid'] ?? '', // Handle null case
    title: json['title'] ?? '', // Handle null case
    description: json['description'], // This is already nullable
    duration: json['duration'] ?? 0, // Handle null case
    passmark: (json['passmark'] as num?)?.toDouble(),
    shuffleQuestions: json['shuffleQuestions'] ?? false,
    allowReview: json['allowReview'] ?? false,
    showResults: json['showResults'] ?? false,
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    status: _parseExamStatus(json['status'] ?? 'DRAFT'),
    instructions: json['instructions'], // This is already nullable
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    attemptStatus: _parseExamAttemptStatus(json['attemptStatus'] ?? 'NOT_STARTED'), 
    questionCount: json["questionCount"],
    totalPoints: json["totalPoints"]
  );
}


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'title': title,
      'description': description,
      // 'subjectId': subjectId,
      // 'gradeId': gradeId,
      // 'createdById': createdById,
      'duration': duration,
      'passmark': passmark,
      'shuffleQuestions': shuffleQuestions,
      'allowReview': allowReview,
      'showResults': showResults,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.name.toUpperCase(),
      // 'instructions': instructions ?? "",
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attemptStatus': attemptStatus.name.toUpperCase(),
      'questionCount': questionCount, 
      'totalPoints': totalPoints
    };
  }

  static ExamStatus _parseExamStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        return ExamStatus.published;
      case 'CLOSED':
        return ExamStatus.closed;
      default:
        return ExamStatus.draft;
    }
  }

  static ExamAttemptStatus _parseExamAttemptStatus(String status) {
    switch (status.toUpperCase()) {
      case 'IN_PROGRESS':
        return ExamAttemptStatus.inProgress;
      case 'COMPLETED':
        return ExamAttemptStatus.completed;
      default:
        return ExamAttemptStatus.notStarted;
    }
  }

  static List<Examination> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((edge) => Examination.fromJson(edge['node'])).toList();
  }
}
