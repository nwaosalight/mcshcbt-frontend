import { gql } from 'apollo-server-express';
import { createTestClient } from 'apollo-server-testing';
import { server } from '../graphql/server';
import { prisma } from '../lib/prisma';
import { generateToken } from '../utils/auth';

const { query, mutate } = createTestClient(server);

// Helper function to create authenticated test client
const createAuthenticatedClient = (role: 'ADMIN' | 'TEACHER' | 'STUDENT') => {
  const token = generateToken({ id: '1', role });
  const client = createTestClient(server);
  return {
    query: (params: any) => client.query({
      ...params,
      context: { req: { headers: { authorization: `Bearer ${token}` } } }
    }),
    mutate: (params: any) => client.mutate({
      ...params,
      context: { req: { headers: { authorization: `Bearer ${token}` } } }
    })
  };
};

describe('GraphQL API Tests', () => {
  // Clean up database before tests
  beforeAll(async () => {
    await prisma.$connect();
    await prisma.$transaction([
      prisma.studentAnswer.deleteMany(),
      prisma.studentExam.deleteMany(),
      prisma.question.deleteMany(),
      prisma.exam.deleteMany(),
      prisma.subject.deleteMany(),
      prisma.grade.deleteMany(),
      prisma.user.deleteMany(),
    ]);
  });

  // Clean up database after tests
  afterAll(async () => {
    await prisma.$disconnect();
  });

  describe('Authentication', () => {
    const LOGIN = gql`
      mutation Login($input: LoginInput!) {
        login(input: $input) {
          ... on AuthPayload {
            token
            user {
              id
              email
              role
            }
          }
          ... on Error {
            code
            message
          }
        }
      }
    `;

    it('should login successfully with valid credentials', async () => {
      const res = await mutate({
        mutation: LOGIN,
        variables: {
          input: {
            email: 'admin@example.com',
            password: 'password123',
          },
        },
      });

      expect(res.data?.login).toHaveProperty('token');
      expect(res.data?.login.user).toHaveProperty('email', 'admin@example.com');
    });

    it('should return error with invalid credentials', async () => {
      const res = await mutate({
        mutation: LOGIN,
        variables: {
          input: {
            email: 'wrong@example.com',
            password: 'wrongpass',
          },
        },
      });

      expect(res.data?.login).toHaveProperty('code', 'UNAUTHORIZED');
    });
  });

  describe('User Management', () => {
    const CREATE_USER = gql`
      mutation CreateUser($input: CreateUserInput!) {
        createUser(input: $input) {
          ... on User {
            id
            email
            role
          }
          ... on Error {
            code
            message
          }
        }
      }
    `;

    it('should create a new user', async () => {
      const { mutate } = createAuthenticatedClient('ADMIN');
      const res = await mutate({
        mutation: CREATE_USER,
        variables: {
          input: {
            firstName: 'John',
            lastName: 'Doe',
            email: 'john@example.com',
            password: 'password123',
            role: 'TEACHER',
          },
        },
      });

      expect(res.data?.createUser).toHaveProperty('email', 'john@example.com');
    });

    it('should not allow non-admin to create users', async () => {
      const { mutate } = createAuthenticatedClient('TEACHER');
      const res = await mutate({
        mutation: CREATE_USER,
        variables: {
          input: {
            firstName: 'Jane',
            lastName: 'Doe',
            email: 'jane@example.com',
            password: 'password123',
            role: 'STUDENT',
          },
        },
      });

      expect(res.data?.createUser).toHaveProperty('code', 'FORBIDDEN');
    });
  });

  describe('Exam Management', () => {
    const CREATE_EXAM = gql`
      mutation CreateExam($input: CreateExamInput!) {
        createExam(input: $input) {
          ... on Exam {
            id
            title
            status
          }
          ... on Error {
            code
            message
          }
        }
      }
    `;

    it('should create a new exam', async () => {
      const { mutate } = createAuthenticatedClient('TEACHER');
      const res = await mutate({
        mutation: CREATE_EXAM,
        variables: {
          input: {
            title: 'Math Test',
            description: 'Basic math test',
            subjectId: '1',
            gradeId: '1',
            duration: 60,
            passmark: 70,
            shuffleQuestions: true,
            allowReview: true,
            showResults: true,
          },
        },
      });

      expect(res.data?.createExam).toHaveProperty('title', 'Math Test');
      expect(res.data?.createExam).toHaveProperty('status', 'DRAFT');
    });

    it('should not allow students to create exams', async () => {
      const { mutate } = createAuthenticatedClient('STUDENT');
      const res = await mutate({
        mutation: CREATE_EXAM,
        variables: {
          input: {
            title: 'Math Test',
            description: 'Basic math test',
            subjectId: '1',
            gradeId: '1',
            duration: 60,
          },
        },
      });

      expect(res.data?.createExam).toHaveProperty('code', 'FORBIDDEN');
    });
  });

  describe('Question Management', () => {
    const CREATE_QUESTION = gql`
      mutation CreateQuestion($input: CreateQuestionInput!) {
        createQuestion(input: $input) {
          ... on Question {
            id
            text
            questionType
          }
          ... on Error {
            code
            message
          }
        }
      }
    `;

    it('should create a new question', async () => {
      const { mutate } = createAuthenticatedClient('TEACHER');
      const res = await mutate({
        mutation: CREATE_QUESTION,
        variables: {
          input: {
            examId: '1',
            questionNumber: 1,
            text: 'What is 2+2?',
            questionType: 'MULTIPLE_CHOICE',
            options: ['3', '4', '5', '6'],
            correctAnswer: '4',
            points: 1,
            difficultyLevel: 'EASY',
          },
        },
      });

      expect(res.data?.createQuestion).toHaveProperty('text', 'What is 2+2?');
      expect(res.data?.createQuestion).toHaveProperty('questionType', 'MULTIPLE_CHOICE');
    });

    it('should not allow creating questions for published exams', async () => {
      const { mutate } = createAuthenticatedClient('TEACHER');
      const res = await mutate({
        mutation: CREATE_QUESTION,
        variables: {
          input: {
            examId: '2', // Assuming this is a published exam
            questionNumber: 1,
            text: 'What is 2+2?',
            questionType: 'MULTIPLE_CHOICE',
            options: ['3', '4', '5', '6'],
            correctAnswer: '4',
            points: 1,
          },
        },
      });

      expect(res.data?.createQuestion).toHaveProperty('code', 'BUSINESS_RULE_VIOLATION');
    });
  });

  describe('Student Exam Taking', () => {
    const START_EXAM = gql`
      mutation StartExam($input: StartExamInput!) {
        startExam(input: $input) {
          ... on StudentExam {
            id
            status
            startTime
          }
          ... on Error {
            code
            message
          }
        }
      }
    `;

    it('should allow student to start an exam', async () => {
      const { mutate } = createAuthenticatedClient('STUDENT');
      const res = await mutate({
        mutation: START_EXAM,
        variables: {
          input: {
            examId: '1',
          },
        },
      });

      expect(res.data?.startExam).toHaveProperty('status', 'IN_PROGRESS');
      expect(res.data?.startExam).toHaveProperty('startTime');
    });

    it('should not allow starting an expired exam', async () => {
      const { mutate } = createAuthenticatedClient('STUDENT');
      const res = await mutate({
        mutation: START_EXAM,
        variables: {
          input: {
            examId: '3', // Assuming this is an expired exam
          },
        },
      });

      expect(res.data?.startExam).toHaveProperty('code', 'EXAM_NOT_AVAILABLE');
    });
  });

  describe('Query Tests', () => {
    const GET_EXAM = gql`
      query GetExam($id: ID!) {
        exam(id: $id) {
          ... on Exam {
            id
            title
            questions {
              id
              text
            }
          }
          ... on Error {
            code
            message
          }
        }
      }
    `;

    it('should fetch exam details', async () => {
      const { query } = createAuthenticatedClient('TEACHER');
      const res = await query({
        query: GET_EXAM,
        variables: {
          id: '1',
        },
      });

      expect(res.data?.exam).toHaveProperty('title');
      expect(res.data?.exam).toHaveProperty('questions');
    });

    it('should not allow unauthorized access to exam details', async () => {
      const { query } = createAuthenticatedClient('STUDENT');
      const res = await query({
        query: GET_EXAM,
        variables: {
          id: '1',
        },
      });

      expect(res.data?.exam).toHaveProperty('code', 'FORBIDDEN');
    });
  });

  describe('Pagination Tests', () => {
    const GET_EXAMS = gql`
      query GetExams($pagination: PaginationInput!) {
        exams(pagination: $pagination) {
          ... on ExamConnection {
            edges {
              node {
                id
                title
              }
              cursor
            }
            pageInfo {
              hasNextPage
              hasPreviousPage
            }
            totalCount
          }
          ... on Error {
            code
            message
          }
        }
      }
    `;

    it('should fetch paginated exams', async () => {
      const { query } = createAuthenticatedClient('TEACHER');
      const res = await query({
        query: GET_EXAMS,
        variables: {
          pagination: {
            first: 10,
          },
        },
      });

      expect(res.data?.exams).toHaveProperty('edges');
      expect(res.data?.exams).toHaveProperty('pageInfo');
      expect(res.data?.exams).toHaveProperty('totalCount');
    });
  });
}); 