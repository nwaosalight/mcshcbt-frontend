import { gql } from 'apollo-server-express';

export const gradeTypeDefs = gql`
  type Grade implements Node {
    id: ID!
    uuid: UUID!
    name: String!
    description: String
    academicYear: String!
    isActive: Boolean!
    createdAt: DateTime!
    updatedAt: DateTime!

    # Relationships
    subjects: [Subject!]!
    exams: [Exam!]!
    students: [User!]!
    teachers: [User!]!
  }

  union GradeResult = Grade | Error
  union GradeConnectionResult = GradeConnection | Error

  input CreateGradeInput {
    name: String!
    description: String
    academicYear: String!
    isActive: Boolean
  }

  input UpdateGradeInput {
    name: String
    description: String
    academicYear: String
    isActive: Boolean
  }

  input GradeFilterInput {
    isActive: Boolean
    academicYear: String
    search: String
  }

  input GradeSortInput {
    field: String!
    direction: SortDirection!
  }

  type GradeEdge {
    cursor: String!
    node: Grade!
  }

  type GradeConnection {
    edges: [GradeEdge!]!
    pageInfo: PageInfo!
    totalCount: Int!
  }

  extend type Query {
    grade(id: ID!): GradeResult!
    grades(
      filter: GradeFilterInput
      sort: GradeSortInput
      pagination: PaginationInput
    ): GradeConnectionResult!
  }

  extend type Mutation {
    createGrade(input: CreateGradeInput!): GradeResult!
    updateGrade(id: ID!, input: UpdateGradeInput!): GradeResult!
    deleteGrade(id: ID!): Boolean!
  }
`; 