import { gql } from 'apollo-server-express';

export const subjectTypeDefs = gql`
  type Subject {
    id: ID!
    uuid: UUID!
    name: String!
    code: String!
    description: String
    isActive: Boolean!
    createdAt: DateTime!
    updatedAt: DateTime!

    # Relationships
    exams: [Exam!]!
    grades: [Grade!]!
    teachers: [User!]!
  }

  union SubjectResult = Subject | Error
  union SubjectConnectionResult = SubjectConnection | Error

  input CreateSubjectInput {
    name: String!
    code: String!
    description: String
    isActive: Boolean
  }

  input UpdateSubjectInput {
    name: String
    code: String
    description: String
    isActive: Boolean
  }

  input SubjectFilterInput {
    isActive: Boolean
    search: String
  }

  input SubjectSortInput {
    field: String!
    direction: SortDirection!
  }

  type SubjectEdge {
    cursor: String!
    node: Subject!
  }

  type SubjectConnection {
    edges: [SubjectEdge!]!
    pageInfo: PageInfo!
    totalCount: Int!
  }

  extend type Query {
    subject(id: ID!): SubjectResult!
    subjectByCode(code: String!): SubjectResult!
    subjects(
      filter: SubjectFilterInput
      sort: SubjectSortInput
      pagination: PaginationInput
    ): SubjectConnectionResult!
  }

  extend type Mutation {
    createSubject(input: CreateSubjectInput!): SubjectResult!
    updateSubject(id: ID!, input: UpdateSubjectInput!): SubjectResult!
    deleteSubject(id: ID!): Boolean!
  }
`; 