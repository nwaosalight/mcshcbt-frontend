import { gql } from 'apollo-server-express';

export const errorTypeDefs = gql`
  enum ErrorCode {
    UNAUTHORIZED
    FORBIDDEN
    NOT_FOUND
    ALREADY_EXISTS
    VALIDATION_ERROR
    INTERNAL_ERROR
    BUSINESS_RULE_VIOLATION
  }

  type Error {
    code: ErrorCode!
    message: String!
    path: [String!]
    details: Json
  }
`; 