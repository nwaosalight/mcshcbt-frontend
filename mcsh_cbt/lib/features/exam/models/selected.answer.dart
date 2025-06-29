class SubmitAnswerInput {
  final String studentExamId;
  final String questionId;
  final String? selectedAnswer;
  final bool? isMarked;
  final int? timeTaken;

  SubmitAnswerInput({
    required this.studentExamId,
    required this.questionId,
    this.selectedAnswer,
    this.isMarked,
    this.timeTaken,
  });

  factory SubmitAnswerInput.fromJson(Map<String, dynamic> json) {
    return SubmitAnswerInput(
      studentExamId: json['studentExamId'] as String,
      questionId: json['questionId'] as String,
      selectedAnswer: json['selectedAnswer'] as String?,
      isMarked: json['isMarked'] as bool?,
      timeTaken: json['timeTaken'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentExamId': studentExamId,
      'questionId': questionId,
      if (selectedAnswer != null) 'selectedAnswer': selectedAnswer,
      if (isMarked != null) 'isMarked': isMarked,
      if (timeTaken != null) 'timeTaken': timeTaken,
    };
  }
}
