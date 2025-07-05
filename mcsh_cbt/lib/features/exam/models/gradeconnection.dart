class GradeConnection {
  final int totalCount;
  final List<GradeEdge> edges;

  GradeConnection({
    required this.totalCount,
    required this.edges,
  });

  factory GradeConnection.fromJson(Map<String, dynamic> json) {
    return GradeConnection(
      totalCount: json['totalCount'],
      edges: (json['edges'] as List)
          .map((e) => GradeEdge.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCount': totalCount,
      'edges': edges.map((e) => e.toJson()).toList(),
    };
  }
}

class GradeEdge {
  final String cursor;
  final Grade node;

  GradeEdge({
    required this.cursor,
    required this.node,
  });

  factory GradeEdge.fromJson(Map<String, dynamic> json) {
    return GradeEdge(
      cursor: json['cursor'],
      node: Grade.fromJson(json['node']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cursor': cursor,
      'node': node.toJson(),
    };
  }
}

class Grade {
  final String id;
  final String uuid;
  final String name;
  final String description;
  final String academicYear;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  Grade({
    required this.id,
    required this.uuid,
    required this.name,
    required this.description,
    required this.academicYear,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'],
      uuid: json['uuid'],
      name: json['name'],
      description: json['description'] ?? '',
      academicYear: json['academicYear'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] ,
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'description': description,
      'academicYear': academicYear,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
