import { authResolvers } from './auth';
import { userResolvers } from './user';
import { examResolvers } from './exam';
import { questionResolvers } from './question';
import { subjectResolvers } from '../../../../src/graphql/resolvers/subject';
import { gradeResolvers } from '../../../../src/graphql/resolvers/grade';
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
      if (obj.subjectCode) return 'Subject';
      if (obj.academicYear) return 'Grade';
      if (obj.status && obj.studentId) return 'StudentExam';
      if (obj.isRead) return 'Notification';
      return null;
    }
  }
};

// Union type resolvers
const unionResolvers = {
  SubjectResult: {
    __resolveType(obj: any) {
      if (obj && typeof obj === 'object') {
        if ('subjectCode' in obj) return 'Subject';
        if ('code' in obj && 'message' in obj) return 'Error';
      }
      return null;
    }
  },
  UserResult: {
    __resolveType(obj: any) {
      if (obj && typeof obj === 'object') {
        if ('email' in obj) return 'User';
        if ('code' in obj && 'message' in obj) return 'Error';
      }
      return null;
    }
  },
  GradeResult: {
    __resolveType(obj: any) {
      if (obj && typeof obj === 'object') {
        if ('academicYear' in obj) return 'Grade';
        if ('code' in obj && 'message' in obj) return 'Error';
      }
      return null;
    }
  },
  ExamResult: {
    __resolveType(obj: any) {
      if (obj && typeof obj === 'object') {
        if ('title' in obj) return 'Exam';
        if ('code' in obj && 'message' in obj) return 'Error';
      }
      return null;
    }
  },
  QuestionResult: {
    __resolveType(obj: any) {
      if (obj && typeof obj === 'object') {
        if ('questionType' in obj) return 'Question';
        if ('code' in obj && 'message' in obj) return 'Error';
      }
      return null;
    }
  },
  StudentExamResult: {
    __resolveType(obj: any) {
      if (obj && typeof obj === 'object') {
        if ('status' in obj) return 'StudentExam';
        if ('code' in obj && 'message' in obj) return 'Error';
      }
      return null;
    }
  },
  NotificationResult: {
    __resolveType(obj: any) {
      if (obj && typeof obj === 'object') {
        if ('isRead' in obj) return 'Notification';
        if ('code' in obj && 'message' in obj) return 'Error';
      }
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
      if (obj.node.subjectCode) return 'SubjectEdge';
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
      if (obj.edges[0]?.node.subjectCode) return 'SubjectConnection';
      if (obj.edges[0]?.node.academicYear) return 'GradeConnection';
      if (obj.edges[0]?.node.status && obj.edges[0]?.node.studentId) return 'StudentExamConnection';
      if (obj.edges[0]?.node.isRead) return 'NotificationConnection';
      return null;
    }
  }
};

// Export all resolvers
export const resolvers = {
  ...scalarResolvers,
  ...nodeInterfaceResolvers,
  ...unionResolvers,
  ...connectionInterfaceResolvers,
  ...authResolvers,
  ...userResolvers,
  ...examResolvers,
  ...questionResolvers,
  ...subjectResolvers,
  ...gradeResolvers
  // Add other resolvers as they're created
};