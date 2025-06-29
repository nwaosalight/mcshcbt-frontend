import { DifficultyLevel, PrismaClient, QuestionType } from '@prisma/client';
import { Context } from '../../utils/auth';

const prisma = new PrismaClient();

// Input types
interface CreateQuestionInput {
  examId: string;
  questionNumber: number;
  text: string;
  questionType: string; // QuestionType enum as string
  options?: any; // Json
  correctAnswer: string;
  points?: number;
  difficultyLevel?: string; // DifficultyLevel enum as string
  tags?: string[];
  feedback?: string;
  image?: string;
}

interface UpdateQuestionInput {
  questionNumber?: number;
  text?: string;
  questionType?: string; // QuestionType enum as string
  options?: any; // Json
  correctAnswer?: string;
  points?: number;
  difficultyLevel?: string; // DifficultyLevel enum as string
  tags?: string[];
  feedback?: string;
  image?: string;
}

interface PaginationInput {
  first?: number;
  after?: string;
  last?: number;
  before?: string;
}

export const questionResolvers = {
  // Type resolvers
  Question: {
    exam: (parent: any) => {
      return prisma.exam.findUnique({
        where: { id: parent.examId }
      });
    }
  },
  
  // Query resolvers
  Query: {
    question: async (_: any, { id }: { id: string }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        const question = await prisma.question.findUnique({
          where: { id: parseInt(id) },
          include: { exam: true }
        });
        
        if (!question) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: `Question with ID ${id} not found`
          };
        }
        
        // Authorization check based on role
        const userRole = context.user.role;
        
        // Admins have full access
        if (userRole === 'ADMIN') {
          return {
            __typename: 'Question',
            ...question
          };
        }
        
        // Check if this user has access to the exam
        if (userRole === 'TEACHER') {
          // Teachers can access if they created the exam or teach the subject
          const isCreator = question.exam.createdById === context.user.id;
          
          if (!isCreator) {
            const teacherSubject = await prisma.teacherSubject.findFirst({
              where: { 
                teacherId: context.user.id,
                subjectId: question.exam.subjectId
              }
            });
            
            if (!teacherSubject) {
              return {
                __typename: 'Error',
                code: 'FORBIDDEN',
                message: 'You do not have access to this question'
              };
            }
          }
        } else if (userRole === 'STUDENT') {
          // Students can only access questions from published exams they're taking
          const isPublished = question.exam.status === 'PUBLISHED';
          
          if (!isPublished) {
            return {
              __typename: 'Error',
              code: 'FORBIDDEN',
              message: 'You do not have access to this question'
            };
          }
          
          // Check if student is in the grade for this exam
          const studentGrade = await prisma.studentGrade.findFirst({
            where: {
              studentId: context.user.id,
              gradeId: question.exam.gradeId
            }
          });
          
          if (!studentGrade) {
            return {
              __typename: 'Error',
              code: 'FORBIDDEN',
              message: 'You do not have access to this question'
            };
          }
          
          // Check if student has an active exam session
          const studentExam = await prisma.studentExam.findFirst({
            where: {
              studentId: context.user.id,
              examId: question.examId,
              status: { in: ['IN_PROGRESS', 'COMPLETED'] }
            }
          });
          
          if (!studentExam) {
            return {
              __typename: 'Error',
              code: 'FORBIDDEN',
              message: 'You must start the exam to view questions'
            };
          }
        }
        
        return {
          __typename: 'Question',
          ...question
        };
      } catch (error) {
        console.error('Error in question query:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },
    
    examQuestions: async (_: any, 
      { examId, pagination }: { examId: string; pagination?: PaginationInput }, 
      context: Context
    ) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        // Find the exam
        const exam = await prisma.exam.findUnique({
          where: { id: parseInt(examId) }
        });
        
        if (!exam) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: `Exam with ID ${examId} not found`
          };
        }
        
        // Authorization check based on role
        const userRole = context.user.role;
        
        // Admins have full access
        if (userRole !== 'ADMIN') {
          // Check if this user has access to the exam
          if (userRole === 'TEACHER') {
            // Teachers can access if they created the exam or teach the subject
            const isCreator = exam.createdById === context.user.id;
            
            if (!isCreator) {
              const teacherSubject = await prisma.teacherSubject.findFirst({
                where: { 
                  teacherId: context.user.id,
                  subjectId: exam.subjectId
                }
              });
              
              if (!teacherSubject) {
                return {
                  __typename: 'Error',
                  code: 'FORBIDDEN',
                  message: 'You do not have access to questions for this exam'
                };
              }
            }
          } else if (userRole === 'STUDENT') {
            // Students can only access questions from published exams they're taking
            const isPublished = exam.status === 'PUBLISHED';
            
            if (!isPublished) {
              return {
                __typename: 'Error',
                code: 'FORBIDDEN',
                message: 'You do not have access to questions for this exam'
              };
            }
            
            // Check if student is in the grade for this exam
            const studentGrade = await prisma.studentGrade.findFirst({
              where: {
                studentId: context.user.id,
                gradeId: exam.gradeId
              }
            });
            
            if (!studentGrade) {
              return {
                __typename: 'Error',
                code: 'FORBIDDEN',
                message: 'You do not have access to questions for this exam'
              };
            }
            
            // Check if student has an active exam session
            const studentExam = await prisma.studentExam.findFirst({
              where: {
                studentId: context.user.id,
                examId: parseInt(examId),
                status: { in: ['IN_PROGRESS', 'COMPLETED'] }
              }
            });
            
            if (!studentExam) {
              return {
                __typename: 'Error',
                code: 'FORBIDDEN',
                message: 'You must start the exam to view questions'
              };
            }
          }
        }
        
        // Handle pagination
        const first = pagination?.first || 50; // Default to 50 questions
        const skip = pagination?.after ? 1 : 0;
        
        // Get total count
        const totalCount = await prisma.question.count({
          where: { examId: parseInt(examId) }
        });
        
        // Get questions
        const questions = await prisma.question.findMany({
          where: { examId: parseInt(examId) },
          orderBy: { questionNumber: 'asc' },
          take: first,
          skip
        });
        
        // For students, maybe shuffle questions if exam requires it
        if (userRole === 'STUDENT' && exam.shuffleQuestions) {
          // Simple shuffle algorithm
          for (let i = questions.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [questions[i], questions[j]] = [questions[j], questions[i]];
          }
        }
        
        // Create edges for connection pattern
        const edges = questions.map(question => ({
          cursor: Buffer.from(`question-${question.id}`).toString('base64'),
          node: question
        }));
        
        // Determine pagination info
        const hasNextPage = totalCount > skip + questions.length;
        const hasPreviousPage = skip > 0;
        
        return {
          __typename: 'QuestionConnection',
          edges,
          pageInfo: {
            hasNextPage,
            hasPreviousPage,
            startCursor: edges.length > 0 ? edges[0].cursor : null,
            endCursor: edges.length > 0 ? edges[edges.length - 1].cursor : null
          },
          totalCount
        };
      } catch (error) {
        console.error('Error in examQuestions query:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    }
  },
  
  // Mutation resolvers
  Mutation: {
    createQuestion: async (_: any, { input }: { input: CreateQuestionInput }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        // Only teachers and admins can create questions
        if (context.user.role !== 'TEACHER' && context.user.role !== 'ADMIN') {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'Only teachers and administrators can create questions'
          };
        }
        
        // Find the exam
        const exam = await prisma.exam.findUnique({
          where: { id: parseInt(input.examId) }
        });
        
        if (!exam) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: `Exam with ID ${input.examId} not found`
          };
        }
        
        // Check if user can modify this exam
        if (context.user.role !== 'ADMIN' && exam.createdById !== context.user.id) {
          const teacherSubject = await prisma.teacherSubject.findFirst({
            where: {
              teacherId: context.user.id,
              subjectId: exam.subjectId
            }
          });
          
          if (!teacherSubject) {
            return {
              __typename: 'Error',
              code: 'FORBIDDEN',
              message: 'You can only create questions for exams of subjects you teach'
            };
          }
        }
        
        // Check if exam is in draft status
        if (exam.status !== 'DRAFT') {
          return {
            __typename: 'Error',
            code: 'BUSINESS_RULE_VIOLATION',
            message: 'Questions can only be added to exams in draft status'
          };
        }
        
        // Validate question number uniqueness
        const existingQuestion = await prisma.question.findFirst({
          where: {
            examId: parseInt(input.examId),
            questionNumber: input.questionNumber
          }
        });
        
        if (existingQuestion) {
          return {
            __typename: 'Error',
            code: 'ALREADY_EXISTS',
            message: `Question number ${input.questionNumber} already exists for this exam`
          };
        }
        
        // Validate question data based on question type
        if (input.questionType === 'MULTIPLE_CHOICE' && (!input.options || !Array.isArray(input.options))) {
          return {
            __typename: 'Error',
            code: 'VALIDATION_ERROR',
            message: 'Multiple choice questions require options array'
          };
        }
        
        // Create the question
        const question = await prisma.question.create({
          data: {
            examId: parseInt(input.examId),
            questionNumber: input.questionNumber,
            text: input.text,
            questionType: input.questionType as QuestionType,
            options: input.options,
            correctAnswer: input.correctAnswer,
            points: input.points || 1,
            difficultyLevel: input.difficultyLevel as DifficultyLevel,
            tags: input.tags || [],
            feedback: input.feedback,
            image: input.image
          }
        });
        
        return {
          __typename: 'Question',
          ...question
        };
      } catch (error) {
        console.error('Error in createQuestion mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },
    
    updateQuestion: async (_: any, 
      { id, input }: { id: string; input: UpdateQuestionInput }, 
      context: Context
    ) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        // Find the question
        const question = await prisma.question.findUnique({
          where: { id: parseInt(id) },
          include: { exam: true }
        });
        
        if (!question) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: `Question with ID ${id} not found`
          };
        }
        
        // Only teachers who created the exam or teach the subject, and admins can update
        if (context.user.role !== 'ADMIN' && context.user.role !== 'TEACHER') {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'Only teachers and administrators can update questions'
          };
        }
        
        // Check if teacher can modify this exam
        if (context.user.role === 'TEACHER') {
          const isCreator = question.exam.createdById === context.user.id;
          
          if (!isCreator) {
            const teacherSubject = await prisma.teacherSubject.findFirst({
              where: {
                teacherId: context.user.id,
                subjectId: question.exam.subjectId
              }
            });
            
            if (!teacherSubject) {
              return {
                __typename: 'Error',
                code: 'FORBIDDEN',
                message: 'You can only update questions for exams of subjects you teach'
              };
            }
          }
        }
        
        // Check if exam is in draft status
        if (question.exam.status !== 'DRAFT') {
          return {
            __typename: 'Error',
            code: 'BUSINESS_RULE_VIOLATION',
            message: 'Questions can only be updated for exams in draft status'
          };
        }
        
        // Validate question number uniqueness if changed
        if (input.questionNumber !== undefined && input.questionNumber !== question.questionNumber) {
          const existingQuestion = await prisma.question.findFirst({
            where: {
              examId: question.examId,
              questionNumber: input.questionNumber,
              id: { not: parseInt(id) }
            }
          });
          
          if (existingQuestion) {
            return {
              __typename: 'Error',
              code: 'ALREADY_EXISTS',
              message: `Question number ${input.questionNumber} already exists for this exam`
            };
          }
        }
        
        // Build update data
        const updateData: any = {};
        
        if (input.questionNumber !== undefined) updateData.questionNumber = input.questionNumber;
        if (input.text !== undefined) updateData.text = input.text;
        if (input.questionType !== undefined) updateData.questionType = input.questionType;
        if (input.options !== undefined) updateData.options = input.options;
        if (input.correctAnswer !== undefined) updateData.correctAnswer = input.correctAnswer;
        if (input.points !== undefined) updateData.points = input.points;
        if (input.difficultyLevel !== undefined) updateData.difficultyLevel = input.difficultyLevel;
        if (input.tags !== undefined) updateData.tags = input.tags;
        if (input.feedback !== undefined) updateData.feedback = input.feedback;
        if (input.image !== undefined) updateData.image = input.image;
        
        // Update the question
        const updatedQuestion = await prisma.question.update({
          where: { id: parseInt(id) },
          data: updateData
        });
        
        return {
          __typename: 'Question',
          ...updatedQuestion
        };
      } catch (error) {
        console.error('Error in updateQuestion mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },
    
    deleteQuestion: async (_: any, { id }: { id: string }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            success: false,
            error: {
              code: 'UNAUTHORIZED',
              message: 'You must be logged in to perform this action'
            }
          };
        }
        
        // Find the question
        const question = await prisma.question.findUnique({
          where: { id: parseInt(id) },
          include: { exam: true }
        });
        
        if (!question) {
          return {
            success: false,
            error: {
              code: 'NOT_FOUND',
              message: `Question with ID ${id} not found`
            }
          };
        }
        
        // Only teachers who created the exam or teach the subject, and admins can delete
        if (context.user.role !== 'ADMIN' && context.user.role !== 'TEACHER') {
          return {
            success: false,
            error: {
              code: 'FORBIDDEN',
              message: 'Only teachers and administrators can delete questions'
            }
          };
        }
        
        // Check if teacher can modify this exam
        if (context.user.role === 'TEACHER') {
          const isCreator = question.exam.createdById === context.user.id;
          
          if (!isCreator) {
            const teacherSubject = await prisma.teacherSubject.findFirst({
              where: {
                teacherId: context.user.id,
                subjectId: question.exam.subjectId
              }
            });
            
            if (!teacherSubject) {
              return {
                success: false,
                error: {
                  code: 'FORBIDDEN',
                  message: 'You can only delete questions for exams of subjects you teach'
                }
              };
            }
          }
        }
        
        // Check if exam is in draft status
        if (question.exam.status !== 'DRAFT') {
          return {
            success: false,
            error: {
              code: 'BUSINESS_RULE_VIOLATION',
              message: 'Questions can only be deleted for exams in draft status'
            }
          };
        }
        
        // Delete the question
        await prisma.question.delete({
          where: { id: parseInt(id) }
        });
        
        return {
          success: true
        };
      } catch (error) {
        console.error('Error in deleteQuestion mutation:', error);
        return {
          success: false,
          error: {
            code: 'INTERNAL_ERROR',
            message: 'An internal error occurred'
          }
        };
      }
    }
  },
  
  // Union resolvers
  QuestionResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      return obj.text ? 'Question' : 'Error';
    }
  },
  
  QuestionConnectionResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      return obj.edges ? 'QuestionConnection' : 'Error';
    }
  }
}; 