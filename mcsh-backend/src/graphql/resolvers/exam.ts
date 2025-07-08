import { ExamAttemptStatus, PrismaClient } from '@prisma/client';
import { Context } from '../../utils/auth';

const prisma = new PrismaClient();

// Input types
interface CreateExamInput {
  title: string;
  description?: string;
  subjectId: string;
  gradeId: string;
  duration: number;
  passmark?: number;
  shuffleQuestions?: boolean;
  allowReview?: boolean;
  showResults?: boolean;
  startDate?: Date;
  endDate?: Date;
  instructions?: string;
}

interface UpdateExamInput {
  title?: string;
  description?: string;
  subjectId?: string;
  gradeId?: string;
  duration?: number;
  passmark?: number;
  shuffleQuestions?: boolean;
  allowReview?: boolean;
  showResults?: boolean;
  startDate?: Date;
  endDate?: Date;
  status?: string; // ExamStatus as string
  instructions?: string;
}

interface ExamFilterInput {
  subjectId?: string;
  gradeId?: string;
  status?: string;
  createdById?: string;
  startDateFrom?: Date;
  startDateTo?: Date;
  search?: string;
}

interface ExamSortInput {
  field: string;
  direction: string;
}

interface PaginationInput {
  first?: number;
  after?: string;
  last?: number;
  before?: string;
}


interface StartExamInput {
  examId: string;
}

export const examResolvers = {
  // Type resolvers
  Exam: {
    subject: (parent: any) => {
      return prisma.subject.findUnique({
        where: { id: parent.subjectId }
      });
    },

    grade: (parent: any) => {
      return prisma.grade.findUnique({
        where: { id: parent.gradeId }
      });
    },

    createdBy: (parent: any) => {
      return prisma.user.findUnique({
        where: { id: parent.createdById }
      });
    },

    questions: (parent: any) => {
      return prisma.question.findMany({
        where: { examId: parent.id },
        orderBy: { questionNumber: 'asc' }
      });
    },

    studentExams: (parent: any) => {
      return prisma.studentExam.findMany({
        where: { examId: parent.id }
      });
    },

    // Computed fields
    questionCount: async (parent: any) => {
      return prisma.question.count({
        where: { examId: parent.id }
      });
    },

    totalPoints: async (parent: any) => {
      const questions = await prisma.question.findMany({
        where: { examId: parent.id },
        select: { points: true }
      });
      
      return questions.reduce((sum, q) => sum + (q.points || 0), 0);
    },

    averageScore: async (parent: any) => {
      const studentExams = await prisma.studentExam.findMany({
        where: { 
          examId: parent.id,
          status: 'COMPLETED'
        },
        select: { score: true }
      });
      
      if (studentExams.length === 0) return null;
      
      const total = studentExams.reduce((sum, se) => sum + (se.score || 0), 0);
      return total / studentExams.length;
    },

    passRate: async (parent: any) => {
      const studentExams = await prisma.studentExam.findMany({
        where: { 
          examId: parent.id,
          status: 'COMPLETED'
        },
        select: { isPassed: true }
      });
      
      if (studentExams.length === 0) return null;
      
      const passedCount = studentExams.filter(se => se.isPassed).length;
      return (passedCount / studentExams.length) * 100;
    }
  },

  // Query resolvers
  Query: {
    exam: async (_: any, { id }: { id: string }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        const exam = await prisma.exam.findUnique({
          where: { id: parseInt(id) }
        });
        
        if (!exam) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: `Exam with ID ${id} not found`
          };
        }
        
        // Authorization check based on role
        const userRole = context.user.role;
        
        // Students can only view published exams assigned to their grade
        if (userRole === 'STUDENT') {
          const studentGrades = await prisma.studentGrade.findMany({
            where: { studentId: context.user.id }
          });
          
          const gradeIds = studentGrades.map(sg => sg.gradeId);
          
          if (exam.status !== 'PUBLISHED' || !gradeIds.includes(exam.gradeId)) {
            return {
              __typename: 'Error',
              code: 'FORBIDDEN',
              message: 'You do not have access to this exam'
            };
          }
        }
        // Teachers can only view exams for subjects/grades they teach or ones they created
        else if (userRole === 'TEACHER') {
          const isCreator = exam.createdById === context.user.id;
          
          if (!isCreator) {
            const teacherSubjects = await prisma.teacherSubject.findMany({
              where: { teacherId: context.user.id }
            });
            
            const subjectIds = teacherSubjects.map(ts => ts.subjectId);
            
            const teacherGrades = await prisma.teacherGrade.findMany({
              where: { teacherId: context.user.id }
            });
            
            const gradeIds = teacherGrades.map(tg => tg.gradeId);
            
            if (!subjectIds.includes(exam.subjectId) && !gradeIds.includes(exam.gradeId)) {
              return {
                __typename: 'Error',
                code: 'FORBIDDEN',
                message: 'You do not have access to this exam'
              };
            }
          }
        }
        
        return {
          __typename: 'Exam',
          ...exam
        };
      } catch (error) {
        console.error('Error in exam query:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },
    
    exams: async (_: any, args: {
      filter?: ExamFilterInput;
      sort?: ExamSortInput;
      pagination?: PaginationInput;
    }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        // Build where clause based on user role and filter
        const where: any = {};
        const userRole = context.user.role;
        
        // Apply filters from input
        if (args.filter) {
          if (args.filter.subjectId) where.subjectId = parseInt(args.filter.subjectId);
          if (args.filter.gradeId) where.gradeId = parseInt(args.filter.gradeId);
          if (args.filter.status) where.status = args.filter.status;
          if (args.filter.createdById) where.createdById = parseInt(args.filter.createdById);
          
          if (args.filter.startDateFrom || args.filter.startDateTo) {
            where.startDate = {};
            if (args.filter.startDateFrom) where.startDate.gte = args.filter.startDateFrom;
            if (args.filter.startDateTo) where.startDate.lte = args.filter.startDateTo;
          }
          
          if (args.filter.search) {
            where.OR = [
              { title: { contains: args.filter.search, mode: 'insensitive' } },
              { description: { contains: args.filter.search, mode: 'insensitive' } }
            ];
          }
        }
        
        // Role-based access control
        if (userRole === 'STUDENT') {
          // Students can only see published exams for their grades
          where.status = 'PUBLISHED';
          // TODO: UNCOMMENT THE LINE BELOW
          // const studentGrades = await prisma.studentGrade.findMany({
          //   where: { studentId: context.user.id }
          // });
          
          // const gradeIds = studentGrades.map(sg => sg.gradeId);
          // where.gradeId = { in: gradeIds };
        } 
        else if (userRole === 'TEACHER') {
          // Teachers see exams they created or for subjects/grades they teach
          const teacherSubjects = await prisma.teacherSubject.findMany({
            where: { teacherId: context.user.id }
          });
          
          const subjectIds = teacherSubjects.map(ts => ts.subjectId);
          
          const teacherGrades = await prisma.teacherGrade.findMany({
            where: { teacherId: context.user.id }
          });
          
          const gradeIds = teacherGrades.map(tg => tg.gradeId);
          
          where.OR = [
            { createdById: context.user.id },
            { 
              AND: [
                { subjectId: { in: subjectIds.length > 0 ? subjectIds : [-1] } },
                { gradeId: { in: gradeIds.length > 0 ? gradeIds : [-1] } }
              ]
            }
          ];
        }
        
        // Build orderBy from sort
        let orderBy: any = { createdAt: 'asc' }; // Default sort
        if (args.sort) {
          switch (args.sort.field) {
            case 'TITLE':
              orderBy = { title: args.sort.direction.toLowerCase() };
              break;
            case 'CREATED_AT':
              orderBy = { createdAt: args.sort.direction.toLowerCase() };
              break;
            case 'START_DATE':
              orderBy = { startDate: args.sort.direction.toLowerCase() };
              break;
            case 'END_DATE':
              orderBy = { endDate: args.sort.direction.toLowerCase() };
              break;
            case 'STATUS':
              orderBy = { status: args.sort.direction.toLowerCase() };
              break;
          }
        }
        
        // Handle pagination
        const first = args.pagination?.first || 10;
        const skip = args.pagination?.after ? 1 : 0;
        
        // Get total count for pagination info
        const totalCount = await prisma.exam.count({ where });
        
        // Get exams
        const exams = await prisma.exam.findMany({
          where,
          orderBy,
          take: first,
          skip
        });
        // Create edges for connection pattern
        const edges = exams.map(exam => ({
          cursor: Buffer.from(`exam-${exam.id}`).toString('base64'),
          node: exam
        }));
        
        // Determine pagination info
        const hasNextPage = totalCount > skip + exams.length;
        const hasPreviousPage = skip > 0;
        
        return {
          __typename: 'ExamConnection',
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
        console.error('Error in exams query:', error);
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
    createExam: async (_: any, { input }: { input: CreateExamInput }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        // Only teachers and admins can create exams
        if (context.user.role !== 'TEACHER' && context.user.role !== 'ADMIN') {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'Only teachers and administrators can create exams'
          };
        }
        
        // For teachers, validate they teach the subject and grade
        if (context.user.role === 'TEACHER') {
          const teacherSubjects = await prisma.teacherSubject.findMany({
            where: { teacherId: context.user.id }
          });

          
          
          const subjectIds = teacherSubjects.map(ts => ts.subjectId);
           
          if (!subjectIds.includes(parseInt(input.subjectId))) {
            return {
              __typename: 'Error',
              code: 'FORBIDDEN',
              message: 'You can only create exams for subjects you teach'
            };
          }
          
          const teacherGrades = await prisma.teacherGrade.findMany({
            where: { teacherId: context.user.id }
          });
          
          const gradeIds = teacherGrades.map(tg => tg.gradeId);
          console.log(context.user.id)
          
          if (!gradeIds.includes(parseInt(input.gradeId))) {
            return {
              __typename: 'Error',
              code: 'FORBIDDEN',
              message: 'You can only create exams for grades you teach'
            };
          }
        }
        
        // Create exam
        const exam = await prisma.exam.create({
          data: {
            title: input.title,
            description: input.description,
            subjectId: parseInt(input.subjectId),
            gradeId: parseInt(input.gradeId),
            createdById: context.user.id,
            duration: input.duration,
            passmark: input.passmark,
            shuffleQuestions: input.shuffleQuestions || false,
            allowReview: input.allowReview || true,
            showResults: input.showResults || true,
            startDate: input.startDate,
            endDate: input.endDate,
            status: 'DRAFT',
            instructions: input.instructions
          }
        });
        
        return {
          __typename: 'Exam',
          ...exam
        };
      } catch (error) {
        console.error('Error in createExam mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },
    
    updateExam: async (_: any, { id, input }: { id: string; input: UpdateExamInput }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        // Find exam
        const exam = await prisma.exam.findUnique({
          where: { id: parseInt(id) }
        });
        
        if (!exam) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: `Exam with ID ${id} not found`
          };
        }
        
        // Check permissions: only creator, subject teacher, or admin can update
        if (context.user.role !== 'ADMIN') {
          const isCreator = exam.createdById === context.user.id;
          
          if (!isCreator && context.user.role !== 'TEACHER') {
            return {
              __typename: 'Error',
              code: 'FORBIDDEN',
              message: 'You do not have permission to update this exam'
            };
          }
          
          if (!isCreator && context.user.role === 'TEACHER') {
            // Check if teacher teaches the subject
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
                message: 'You can only update exams for subjects you teach'
              };
            }
          }
        }
        
        // Build update data
        const updateData: any = {};
        
        if (input.title !== undefined) updateData.title = input.title;
        if (input.description !== undefined) updateData.description = input.description;
        if (input.duration !== undefined) updateData.duration = input.duration;
        if (input.passmark !== undefined) updateData.passmark = input.passmark;
        if (input.shuffleQuestions !== undefined) updateData.shuffleQuestions = input.shuffleQuestions;
        if (input.allowReview !== undefined) updateData.allowReview = input.allowReview;
        if (input.showResults !== undefined) updateData.showResults = input.showResults;
        if (input.startDate !== undefined) updateData.startDate = input.startDate;
        if (input.endDate !== undefined) updateData.endDate = input.endDate;
        if (input.instructions !== undefined) updateData.instructions = input.instructions;
        if (input.status !== undefined) updateData.status = input.status;
        
        // Subject and grade can only be changed if no student has started the exam
        if (input.subjectId !== undefined || input.gradeId !== undefined) {
          const hasStudentExams = await prisma.studentExam.findFirst({
            where: { examId: parseInt(id) }
          });
          
          if (hasStudentExams) {
            return {
              __typename: 'Error',
              code: 'BUSINESS_RULE_VIOLATION',
              message: 'Cannot change subject or grade after students have started the exam'
            };
          }
          
          if (input.subjectId !== undefined) updateData.subjectId = parseInt(input.subjectId);
          if (input.gradeId !== undefined) updateData.gradeId = parseInt(input.gradeId);
        }
        
        // Update exam
        const updatedExam = await prisma.exam.update({
          where: { id: parseInt(id) },
          data: updateData
        });
        
        return {
          __typename: 'Exam',
          ...updatedExam
        };
      } catch (error) {
        console.error('Error in updateExam mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },
    
    deleteExam: async (_: any, { id }: { id: string }, context: Context) => {
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
        
        // Find exam
        const exam = await prisma.exam.findUnique({
          where: { id: parseInt(id) }
        });
        
        if (!exam) {
          return {
            success: false,
            error: {
              code: 'NOT_FOUND',
              message: `Exam with ID ${id} not found`
            }
          };
        }
        
        // Only creator or admin can delete
        if (exam.createdById !== context.user.id && context.user.role !== 'ADMIN') {
          return {
            success: false,
            error: {
              code: 'FORBIDDEN',
              message: 'You do not have permission to delete this exam'
            }
          };
        }
        
        // Check if any students have started the exam
        const studentExams = await prisma.studentExam.findFirst({
          where: { examId: parseInt(id) }
        });
        
        if (studentExams) {
          return {
            success: false,
            error: {
              code: 'BUSINESS_RULE_VIOLATION',
              message: 'Cannot delete an exam that students have already started'
            }
          };
        }
        
        // Delete questions first
        await prisma.question.deleteMany({
          where: { examId: parseInt(id) }
        });
        
        // Delete exam
        await prisma.exam.delete({
          where: { id: parseInt(id) }
        });
        
        return {
          success: true
        };
      } catch (error) {
        console.error('Error in deleteExam mutation:', error);
        return {
          success: false,
          error: {
            code: 'INTERNAL_ERROR',
            message: 'An internal error occurred'
          }
        };
      }
    },
    
    publishExam: async (_: any, { id }: { id: string }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        // Find exam
        const exam = await prisma.exam.findUnique({
          where: { id: parseInt(id) }
        });
        
        if (!exam) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: `Exam with ID ${id} not found`
          };
        }
        
        // Only creator, subject teacher, or admin can publish
        if (context.user.role !== 'ADMIN' && exam.createdById !== context.user.id) {
          if (context.user.role !== 'TEACHER') {
            return {
              __typename: 'Error',
              code: 'FORBIDDEN',
              message: 'You do not have permission to publish this exam'
            };
          }
          
          // Check if teacher teaches the subject
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
              message: 'You can only publish exams for subjects you teach'
            };
          }
        }
        
        // Check if exam has questions
        const questionCount = await prisma.question.count({
          where: { examId: parseInt(id) }
        });
        
        if (questionCount === 0) {
          return {
            __typename: 'Error',
            code: 'VALIDATION_ERROR',
            message: 'Cannot publish an exam with no questions'
          };
        }
        
        // Update exam status
        const updatedExam = await prisma.exam.update({
          where: { id: parseInt(id) },
          data: { status: 'PUBLISHED' }
        });
        
        return {
          __typename: 'Exam',
          ...updatedExam
        };
      } catch (error) {
        console.error('Error in publishExam mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },
    
    archiveExam: async (_: any, { id }: { id: string }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        // Find exam
        const exam = await prisma.exam.findUnique({
          where: { id: parseInt(id) }
        });
        
        if (!exam) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: `Exam with ID ${id} not found`
          };
        }
        
        // Only creator or admin can archive
        if (exam.createdById !== context.user.id && context.user.role !== 'ADMIN') {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'You do not have permission to archive this exam'
          };
        }
        
        // Update exam status
        const updatedExam = await prisma.exam.update({
          where: { id: parseInt(id) },
          data: { status: 'ARCHIVED' }
        });
        
        return {
          __typename: 'Exam',
          ...updatedExam
        };
      } catch (error) {
        console.error('Error in archiveExam mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    }, 
    startExam: async (_: any, { input }: { input: StartExamInput }, context: Context) => {
     console.log(input)
     
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }

        // Role check
        if (context.user.role !== 'STUDENT') {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'Only students can submit exams'
          };
        }

        const {examId} = input;
      
        const studentExam = await prisma.studentExam.create({
          data: {
            examId: parseInt(examId),
            studentId: context.user.id, 
            score: 0.0, 
            status: ExamAttemptStatus.IN_PROGRESS, 
          }
        })

        return {
          __typename: 'StudentExam',
          ...studentExam
        };
      } catch (error: any){
        console.log(error)
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred ' + error.message
        };
      }
    }
  },
  
  // Union resolvers
  ExamResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      return obj.title ? 'Exam' : 'Error';
    }
  },
  
  ExamConnectionResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      return obj.edges ? 'ExamConnection' : 'Error';
    }
  }
}; 