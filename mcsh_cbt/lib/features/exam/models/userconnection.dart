import 'package:mcsh_cbt/features/exam/models/gradeconnection.dart';

class UserConnection {
  final int totalCount;
  final List<UserEdge> edges;

  UserConnection({
    required this.totalCount,
    required this.edges,
  });

  factory UserConnection.fromJson(Map<String, dynamic> json) {
    return UserConnection(
      totalCount: json['totalCount'],
      edges: (json['edges'] as List)
          .map((e) => UserEdge.fromJson(e))
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

class UserEdge {
  final String cursor;
  final UserNode node;

  UserEdge({
    required this.cursor,
    required this.node,
  });

  factory UserEdge.fromJson(Map<String, dynamic> json) {
    return UserEdge(
      cursor: json['cursor'],
      node: UserNode.fromJson(json['node']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cursor': cursor,
      'node': node.toJson(),
    };
  }
}

class UserNode {
  final String id;
  final String uuid;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String status;
  final String? profileImage;
  final String? phoneNumber;
  final String? lastLogin;
  final String createdAt;
  final String updatedAt;
  final String fullName;
  final GradeUserNode? grade;

  UserNode({
    required this.id,
    required this.uuid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.status,
    this.profileImage,
    this.phoneNumber,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    required this.fullName,
    this.grade,
  });

  factory UserNode.fromJson(Map<String, dynamic> json) {
    print('json $json');
    return UserNode(
      id: json['id'],
      uuid: json['uuid'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
      profileImage: json['profileImage'],
      phoneNumber: json['phoneNumber'],
      lastLogin: json['lastLogin'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      fullName: json['fullName'],
      grade: (json['studentGrades'] != null && 
         json['studentGrades'].isNotEmpty) 
    ? GradeUserNode.fromJson(json['studentGrades'][0]) 
    : null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'status': status,
      'profileImage': profileImage,
      'phoneNumber': phoneNumber,
      'lastLogin': lastLogin,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'fullName': fullName,
    };
  }

   // Extracts the list of subjects from the `edges` data.
  static List<UserNode> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((edge) => UserNode.fromJson(edge['node'])).toList();
  }
}

class GradeUserNode{
  final String id;
  final String name;

  GradeUserNode({
    required this.id,
    required this.name,
  });

  factory GradeUserNode.fromJson(Map<String, dynamic> json){
    return GradeUserNode(id: json['id'], name: json['name']);
  }

}