class Student {
  final String id;
  final String name;
  final String grade;
  final List<ExamResult> examResults;

  Student({
    required this.id,
    required this.name,
    required this.grade,
    this.examResults = const [],
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      grade: json['grade'] as String,
      examResults: (json['examResults'] as List?)
          ?.map((e) => ExamResult.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'examResults': examResults.map((e) => e.toJson()).toList(),
    };
  }
}

class ExamResult {
  final String examId;
  final String subject;
  final int score;
  final int totalQuestions;
  final DateTime dateTaken;

  ExamResult({
    required this.examId,
    required this.subject,
    required this.score,
    required this.totalQuestions,
    required this.dateTaken,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      examId: json['examId'] as String,
      subject: json['subject'] as String,
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      dateTaken: DateTime.parse(json['dateTaken'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'examId': examId,
      'subject': subject,
      'score': score,
      'totalQuestions': totalQuestions,
      'dateTaken': dateTaken.toIso8601String(),
    };
  }
} 