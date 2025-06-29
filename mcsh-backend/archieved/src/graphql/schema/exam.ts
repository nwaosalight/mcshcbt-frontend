import { gql } from 'apollo-server-express';

export const examTypeDefs = gql`
  enum ExamStatus {
    DRAFT
    PUBLISHED
    ARCHIVED
  }

  type Exam implements Node {
    id: ID!
    uuid: UUID!
    title: String!
    description: String
    subjectId: ID!
    gradeId: ID!
    createdById: ID!
    duration: Int!
    passmark: Float
    shuffleQuestions: Boolean!
    allowReview: Boolean!
    showResults: Boolean!
    startDate: DateTime
    endDate: DateTime
    status: ExamStatus!
    instructions: String
    createdAt: DateTime!
    updatedAt: DateTime!

    # Relationships
    subject: Subject!
    grade: Grade!
    createdBy: User!
    questions: [Question!]!
    studentExams: [StudentExam!]!

    # Computed fields
    questionCount: Int!
    totalPoints: Float!
    averageScore: Float
  }

  union ExamResult = Exam | Error
  union ExamConnectionResult = ExamConnection | Error

  input CreateExamInput {
    title: String!
    description: String
    subjectId: ID!
    gradeId: ID!
    duration: Int!
    passmark: Float
    shuffleQuestions: Boolean
    allowReview: Boolean
    showResults: Boolean
    startDate: DateTime
    endDate: DateTime
    instructions: String
  }

  input UpdateExamInput {
    title: String
    description: String
    subjectId: ID
    gradeId: ID
    duration: Int
    passmark: Float
    shuffleQuestions: Boolean
    allowReview: Boolean
    showResults: Boolean
    startDate: DateTime
    endDate: DateTime
    status: ExamStatus
    instructions: String
  }

  input ExamFilterInput {
    subjectId: ID
    gradeId: ID
    status: ExamStatus
    createdById: ID
    startDateFrom: DateTime
    startDateTo: DateTime
    search: String
  }

  input ExamSortInput {
    field: String!
    direction: SortDirection!
  }

  type ExamEdge {
    cursor: String!
    node: Exam!
  }

  type ExamConnection {
    edges: [ExamEdge!]!
    pageInfo: PageInfo!
    totalCount: Int!
  }

  extend type Query {
    exam(id: ID!): ExamResult!
    exams(
      filter: ExamFilterInput
      sort: ExamSortInput
      pagination: PaginationInput
    ): ExamConnectionResult!
  }

  extend type Mutation {
    createExam(input: CreateExamInput!): ExamResult!
    updateExam(id: ID!, input: UpdateExamInput!): ExamResult!
    deleteExam(id: ID!): Boolean!
    publishExam(id: ID!): ExamResult!
    archiveExam(id: ID!): ExamResult!
  }
`; 