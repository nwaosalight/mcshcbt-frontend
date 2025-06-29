import { authResolvers } from './auth';
import { userResolvers } from './user';
import { examResolvers } from './exam';
import { questionResolvers } from './question';
import { gradeResolvers } from './grade';
import { subjectResolvers } from './subject';
import { studentResolvers } from './student';
// Import other resolvers as they're created

// Define scalar resolvers 
const scalarResolvers = {
  DateTime: {
    // Custom scalar for DateTime handling
    serialize(value: Date) {
      return value.toISOString();
    },
    parseValue(value: string) {
      return new Date(value);
    },
    parseLiteral(ast: any) {
      if (ast.kind === 'StringValue') {
        return new Date(ast.value);
      }
      return null;
    }
  },
  
  Json: {
    // Custom scalar for JSON handling
    serialize(value: any) {
      return value;
    },
    parseValue(value: any) {
      return value;
    },
    parseLiteral(ast: any) {
      switch (ast.kind) {
        case 'StringValue':
          return JSON.parse(ast.value);
        case 'ObjectValue':
          return ast.fields.reduce((result: any, field: any) => {
            result[field.name.value] = field.value;
            return result;
          }, {});
        default:
          return null;
      }
    }
  },
  
  UUID: {
    // Custom scalar for UUID handling
    serialize(value: string) {
      return value;
    },
    parseValue(value: string) {
      return value;
    },
    parseLiteral(ast: any) {
      if (ast.kind === 'StringValue') {
        return ast.value;
      }
      return null;
    }
  }
};

// Node interface resolver
const nodeInterfaceResolvers = {
  Node: {
    __resolveType(obj: any) {
      // Resolve the concrete type for the Node interface
      if (obj.email) return 'User';
      if (obj.title && obj.createdById) return 'Exam';
      if (obj.questionType) return 'Question';
      if (obj.code) return 'Subject';
      if (obj.academicYear) return 'Grade';
      if (obj.status && obj.studentId) return 'StudentExam';
      if (obj.isRead) return 'Notification';
      return null;
    }
  }
};

// Edge and Connection interface resolvers
const connectionInterfaceResolvers = {
  Edge: {
    __resolveType(obj: any) {
      if (obj.node.email) return 'UserEdge';
      if (obj.node.title && obj.node.createdById) return 'ExamEdge';
      if (obj.node.questionType) return 'QuestionEdge';
      if (obj.node.code) return 'SubjectEdge';
      if (obj.node.academicYear) return 'GradeEdge';
      if (obj.node.status && obj.node.studentId) return 'StudentExamEdge';
      if (obj.node.isRead) return 'NotificationEdge';
      return null;
    }
  },
  
  Connection: {
    __resolveType(obj: any) {
      if (obj.edges[0]?.node.email) return 'UserConnection';
      if (obj.edges[0]?.node.title && obj.edges[0]?.node.createdById) return 'ExamConnection';
      if (obj.edges[0]?.node.questionType) return 'QuestionConnection';
      if (obj.edges[0]?.node.code) return 'SubjectConnection';
      if (obj.edges[0]?.node.academicYear) return 'GradeConnection';
      if (obj.edges[0]?.node.status && obj.edges[0]?.node.studentId) return 'StudentExamConnection';
      if (obj.edges[0]?.node.isRead) return 'NotificationConnection';
      return null;
    }
  }
};

// Merge all resolver groups
export const resolvers = {
  // Scalar resolvers
  ...scalarResolvers,
  
  // Interface resolvers
  ...nodeInterfaceResolvers,
  ...connectionInterfaceResolvers,
  
  // Type resolvers
  ...authResolvers,
  ...userResolvers,
  ...examResolvers,
  ...questionResolvers,
  ...gradeResolvers,
  ...subjectResolvers,
  ...studentResolvers,
  
  // Union resolvers - these are defined in the individual resolver files
  
  // Query resolvers - merged from all files
  Query: {
    ...authResolvers.Query,
    ...userResolvers.Query,
    ...examResolvers.Query,
    ...questionResolvers.Query,
    ...gradeResolvers.Query,
    ...subjectResolvers.Query,
    // Add other Query resolvers
  },
  
  // Mutation resolvers - merged from all files
  Mutation: {
    ...authResolvers.Mutation,
    ...userResolvers.Mutation,
    ...examResolvers.Mutation,
    ...questionResolvers.Mutation,
    ...gradeResolvers.Mutation,
    ...subjectResolvers.Mutation,
    ...studentResolvers.Mutation,
    // Add other Mutation resolvers
  },
  
  // Subscription resolvers - would go here if implemented
  Subscription: {
    // Subscription resolvers would go here
  }
};