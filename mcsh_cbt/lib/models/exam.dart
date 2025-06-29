import 'question.dart';

class Exam {
  final String subject;
  final int questionLen;
  final List<Question> questions;

  Exam({
    required this.subject,
    required this.questionLen,
    required this.questions,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      subject: json['subject'] as String,
      questionLen: json['questionLen'] as int,
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'questionLen': questionLen,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
  
  Exam copyWith({
    String? subject,
    int? questionLen,
    List<Question>? questions,
  }) {
    return Exam(
      subject: subject ?? this.subject,
      questionLen: questionLen ?? this.questionLen,
      questions: questions ?? this.questions,
    );
  }
} 