class Question {
  final String label;
  final List<String> options;
  final List<String> images;
  String? selectedAnswer;
  bool markedForReview;

  Question({
    required this.label,
    required this.options,
    required this.images,
    this.selectedAnswer,
    this.markedForReview = false,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      label: json['label'] as String,
      options: List<String>.from(json['options'] as List),
      images: List<String>.from(json['images'] as List),
      markedForReview: json['markedForReview'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'options': options,
      'images': images,
      'selectedAnswer': selectedAnswer,
      'markedForReview': markedForReview,
    };
  }
} 