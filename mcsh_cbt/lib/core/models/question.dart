class Question {
  final String id;
  final String question;
  final List<String> options;
  final int correctOption;
  final String subject;
  final String difficulty;
  final List<String> imageUrls;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOption,
    required this.subject,
    required this.difficulty,
    this.imageUrls = const [],
  });

  Question copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctOption,
    String? subject,
    String? difficulty,
    List<String>? imageUrls,
  }) {
    return Question(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctOption: correctOption ?? this.correctOption,
      subject: subject ?? this.subject,
      difficulty: difficulty ?? this.difficulty,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctOption': correctOption,
      'subject': subject,
      'difficulty': difficulty,
      'imageUrls': imageUrls,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List).map((e) => e as String).toList(),
      correctOption: json['correctOption'] as int,
      subject: json['subject'] as String,
      difficulty: json['difficulty'] as String,
      imageUrls:
          json['imageUrls'] != null
              ? (json['imageUrls'] as List).map((e) => e as String).toList()
              : [],
    );
  }
}
