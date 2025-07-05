class Subject {
  final String id;
  final String uuid;
  final String subjectCode;
  final String name;
  final int gradeId; 
  final String gradeName;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subject({
    required this.id,
    required this.uuid,
    required this.subjectCode,
    required this.name,
    required this.gradeId, 
    required this.gradeName, 
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      uuid: json['uuid'],
      subjectCode: json['subjectCode'] ?? '',
      name: json['name'],
      gradeId: json['gradeId'],
      gradeName: json['gradeName'],
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'subjectCode': subjectCode,
      'name': name,
      'gradeId': gradeId, 
      'gradeName': gradeName, 
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Extracts the list of subjects from the `edges` data.
  static List<Subject> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((edge) => Subject.fromJson(edge['node'])).toList();
  }
}
