import { gql } from 'apollo-server-express';
import { errorTypeDefs } from './error';
import { subjectTypeDefs } from './subject';
import { userTypeDefs } from './user';
import { examTypeDefs } from './exam';
import { questionTypeDefs } from './question';
import { gradeTypeDefs } from './grade';
import { studentExamTypeDefs } from './student-exam';
import { notificationTypeDefs } from './notification';
import { authTypeDefs } from './auth';

// Base schema with common types and directives
const baseTypeDefs = gql`
  directive @auth(requires: Role = ADMIN) on OBJECT | FIELD_DEFINITION

  enum Role {
    ADMIN
    TEACHER
    STUDENT
  }

  enum SortDirection {
    ASC
    DESC
  }

  interface Node {
    id: ID!
  }

  interface Edge {
    cursor: String!
    node: Node!
  }

  interface Connection {
    edges: [Edge!]!
    pageInfo: PageInfo!
    totalCount: Int!
  }

  type PageInfo {
    hasNextPage: Boolean!
    hasPreviousPage: Boolean!
    startCursor: String
    endCursor: String
  }

  scalar DateTime
  scalar Json
  scalar UUID

  input PaginationInput {
    first: Int
    after: String
    last: Int
    before: String
  }

  type Query {
    _empty: String
  }

  type Mutation {
    _empty: String
  }
`;

// Export all type definitions
export const typeDefs = [
  baseTypeDefs,
  errorTypeDefs,
  subjectTypeDefs,
  userTypeDefs,
  examTypeDefs,
  questionTypeDefs,
  gradeTypeDefs,
  studentExamTypeDefs,
  notificationTypeDefs,
  authTypeDefs
]; 