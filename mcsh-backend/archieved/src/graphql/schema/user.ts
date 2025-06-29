import { gql } from 'apollo-server-express';

export const userTypeDefs = gql`
  enum UserRole {
    ADMIN
    TEACHER
    STUDENT
  }

  enum UserStatus {
    ACTIVE
    INACTIVE
    SUSPENDED
  }

  type User {
    id: ID!
    uuid: UUID!
    firstName: String!
    lastName: String!
    email: String!
    role: UserRole!
    status: UserStatus!
    profileImage: String
    phoneNumber: String
    lastLogin: DateTime
    createdAt: DateTime!
    updatedAt: DateTime!

    # Computed fields
    fullName: String!

    # Relationships
    teacherSubjects: [Subject!]!
    teacherGrades: [Grade!]!
    studentGrades: [Grade!]!
    createdExams: [Exam!]!
    studentExams: [StudentExam!]!
    notifications: [Notification!]!
  }

  union UserResult = User | Error
  union UserConnectionResult = UserConnection | Error

  input CreateUserInput {
    firstName: String!
    lastName: String!
    email: String!
    password: String!
    role: UserRole!
    status: UserStatus
    profileImage: String
    phoneNumber: String
  }

  input UpdateUserInput {
    firstName: String
    lastName: String
    email: String
    password: String
    role: UserRole
    status: UserStatus
    profileImage: String
    phoneNumber: String
  }

  input UserFilterInput {
    role: UserRole
    status: UserStatus
    search: String
  }

  input UserSortInput {
    field: String!
    direction: SortDirection!
  }

  type UserEdge {
    cursor: String!
    node: User!
  }

  type UserConnection {
    edges: [UserEdge!]!
    pageInfo: PageInfo!
    totalCount: Int!
  }

  extend type Query {
    user(id: ID!): UserResult!
    users(
      filter: UserFilterInput
      sort: UserSortInput
      pagination: PaginationInput
    ): UserConnectionResult!
  }

  extend type Mutation {
    createUser(input: CreateUserInput!): UserResult!
    updateUser(id: ID!, input: UpdateUserInput!): UserResult!
    deleteUser(id: ID!): Boolean!
  }
`; 