import { PrismaClient, UserRole } from '@prisma/client';
import { Context } from 'src/utils/auth';

const prisma = new PrismaClient();

interface AssignTeacherInput {
  teacherId: string;
  subjectIds: string[];
  gradeIds: string[];
}

interface EnrollStudentInput {
  studentId: string;
  gradeId: string;
}

interface BooleanResult {
  success: boolean;
  error?: {
    code: string;
    message: string;
    path?: string[];
    details?: any;
  };
}

export const subjectResolvers = {
  SubjectResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      if (obj && typeof obj === 'object') {
        if ('code' in obj && 'name' in obj) return 'Subject';
        if ('code' in obj && 'message' in obj) return 'Error';
      }
      return null;
    }
  },

  SubjectConnectionResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      if (obj && typeof obj === 'object') {
        if ('edges' in obj) return 'SubjectConnection';
        if ('code' in obj && 'message' in obj) return 'Error';
      }
      return null;
    }
  },

  Subject: {
    // Resolver for gradeName field
    gradeName: async (parent: any) => {
      try {
        const grade = await prisma.grade.findUnique({
          where: { id: parent.gradeId },
          select: { name: true }
        });
        return grade?.name || '';
      } catch (error) {
        console.error('Error resolving gradeName:', error);
        return '';
      }
    },

    // Resolver for grade relationship
    grade: async (parent: any) => {
      try {
        return await prisma.grade.findUnique({
          where: { id: parent.gradeId }
        });
      } catch (error) {
        console.error('Error resolving grade:', error);
        return null;
      }
    },

    // Resolver for teachers relationship
    teachers: async (parent: any) => {
      try {
        const teacherSubjects = await prisma.teacherSubject.findMany({
          where: { 
            subjectId: parent.id,
            isActive: true 
          },
          include: {
            teacher: true
          }
        });
        return teacherSubjects.map(ts => ts.teacher);
      } catch (error) {
        console.error('Error resolving teachers:', error);
        return [];
      }
    },

    // Resolver for exams relationship
    exams: async (parent: any) => {
      try {
        return await prisma.exam.findMany({
          where: { subjectId: parent.id }
        });
      } catch (error) {
        console.error('Error resolving exams:', error);
        return [];
      }
    }
  },

  Query: {
    subjects: async (_: any, { 
      filter, 
      sort, 
      pagination 
    }: { 
      filter?: { 
        isActive?: boolean; 
        search?: string;
        gradeId?: string;
      }; 
      sort?: { 
        field: string; 
        direction: 'ASC' | 'DESC';
      }; 
      pagination?: { 
        first?: number; 
        after?: string; 
        last?: number; 
        before?: string;
      }; 
    }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to view subjects'
          };
        }

        // Build filter criteria
        const where: any = {};
        
        if (filter) {
          if (filter.isActive !== undefined) {
            where.isActive = filter.isActive;
          }

          if (filter.gradeId) {
            where.gradeId = parseInt(filter.gradeId);
          }
          
          if (filter.search) {
            where.OR = [
              { code: { contains: filter.search, mode: 'insensitive' } },
              { name: { contains: filter.search, mode: 'insensitive' } },
              { description: { contains: filter.search, mode: 'insensitive' } },
              { 
                grade: { 
                  name: { contains: filter.search, mode: 'insensitive' } 
                } 
              }
            ];
          }
        }

        // Build sorting criteria
        const orderBy: any = {};
        
        if (sort) {
          const field = sort.field.toLowerCase();
          const direction = sort.direction.toLowerCase();
          
          switch (field) {
            case 'code':
              orderBy.code = direction;
              break;
            case 'name':
              orderBy.name = direction;
              break;
            case 'grade':
            case 'gradename':
              orderBy.grade = { name: direction };
              break;
            case 'created_at':
              orderBy.createdAt = direction;
              break;
            default:
              orderBy.createdAt = 'desc';
          }
        } else {
          orderBy.createdAt = 'desc';
        }

        // Handle pagination
        let skip: number | undefined;
        let take: number | undefined;
        let cursor: any | undefined;
        
        if (pagination) {
          if (pagination.first) {
            take = pagination.first;
            
            if (pagination.after) {
              const decodedCursor = Buffer.from(pagination.after, 'base64').toString('utf-8');
              const cursorId = parseInt(decodedCursor);
              
              if (isNaN(cursorId)) {
                return {
                  __typename: 'Error',
                  code: 'INVALID_INPUT',
                  message: 'Invalid cursor provided'
                };
              }
              
              cursor = { id: cursorId };
              skip = 1; // Skip the cursor itself
            }
          } else if (pagination.last) {
            take = -pagination.last; // Negative for reverse pagination
            
            if (pagination.before) {
              const decodedCursor = Buffer.from(pagination.before, 'base64').toString('utf-8');
              const cursorId = parseInt(decodedCursor);
              
              if (isNaN(cursorId)) {
                return {
                  __typename: 'Error',
                  code: 'INVALID_INPUT',
                  message: 'Invalid cursor provided'
                };
              }
              
              cursor = { id: cursorId };
              skip = 1; // Skip the cursor itself
            }
          }
        }

        // Get total count
        const totalCount = await prisma.subject.count({ where });

        // Query for actual data with grade relationship
        const subjects = await prisma.subject.findMany({
          where,
          orderBy,
          skip,
          take,
          cursor,
          include: {
            grade: {
              select: {
                id: true,
                name: true
              }
            }
          }
        });

        // Create edges and page info
        const edges = subjects.map(subject => ({
          cursor: Buffer.from(subject.id.toString()).toString('base64'),
          node: {
            ...subject,
            id: subject.id.toString(),
            uuid: subject.uuid,
            gradeId: subject.gradeId,
            gradeName: subject.grade.name,
            __typename: 'Subject'
          }
        }));

        // Determine if there's a next page or previous page
        let hasNextPage = false;
        let hasPreviousPage = false;

        if (take && take > 0 && edges.length === take) {
          // Check if there's one more result after the last item
          const nextItem = await prisma.subject.findFirst({
            where,
            orderBy,
            skip: take,
            take: 1,
            cursor: cursor ? { ...cursor, skip } : undefined
          });
          
          hasNextPage = !!nextItem;
        } else if (take && take < 0 && edges.length === -take) {
          // Check if there's one more result before the first item
          const prevItem = await prisma.subject.findFirst({
            where,
            orderBy: Object.fromEntries(
              Object.entries(orderBy).map(([key, value]) => [key, value === 'ASC' ? 'DESC' : 'ASC'])
            ),
            skip: -take,
            take: 1,
            cursor: cursor ? { ...cursor, skip } : undefined
          });
          
          hasPreviousPage = !!prevItem;
        }

        return {
          __typename: 'SubjectConnection',
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
        console.error('Error in subjects query:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred while fetching subjects'
        };
      }
    },

    subject: async (_: any, { id }: { id: string }) => {
      try {
        const subject = await prisma.subject.findUnique({
          where: { id: parseInt(id) },
          include: {
            grade: {
              select: {
                id: true,
                name: true
              }
            }
          }
        });
        
        if (!subject) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: 'Subject not found',
            path: ['subject']
          };
        }
        
        return {
          __typename: 'Subject',
          ...subject,
          gradeId: subject.gradeId,
          gradeName: subject.grade.name
        };
      } catch (error) {
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'Failed to fetch subject',
          path: ['subject']
        };
      }
    },

    subjectByCode: async (_: any, { code }: { code: string }) => {
      try {
        const subject = await prisma.subject.findUnique({
          where: { code },
          include: {
            grade: {
              select: {
                id: true,
                name: true
              }
            }
          }
        });
        
        if (!subject) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: 'Subject not found',
            path: ['subjectByCode']
          };
        }
        
        return {
          __typename: 'Subject',
          ...subject,
          gradeId: subject.gradeId,
          gradeName: subject.grade.name
        };
      } catch (error) {
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'Failed to fetch subject',
          path: ['subjectByCode']
        };
      }
    }
  },

  Mutation: {
    createSubject: async (_: any, { input }: { 
      input: { 
        name: string; 
        code: string; 
        description?: string;
        gradeId?: string;
      } 
    }) => {
      console.log('Creating subject:', input);
      
      try {
        // Check if subject with same code already exists
        const existingSubject = await prisma.subject.findUnique({
          where: { code: input.code }
        });

        if (existingSubject) {
          return {
            __typename: 'Error',
            code: 'ALREADY_EXISTS',
            message: 'Subject with this code already exists',
            path: ['createSubject']
          };
        }

        // Validate grade if provided
        if (input.gradeId) {
          const grade = await prisma.grade.findUnique({
            where: { id: parseInt(input.gradeId) }
          });

          if (!grade) {
            return {
              __typename: 'Error',
              code: 'NOT_FOUND',
              message: 'Grade not found',
              path: ['createSubject', 'gradeId']
            };
          }
        }

        const subject = await prisma.subject.create({
          data: {
            name: input.name,
            code: input.code,
            description: input.description,
            gradeId: input.gradeId ? parseInt(input.gradeId) : 1 // Default to grade 1
          },
          include: {
            grade: {
              select: {
                id: true,
                name: true
              }
            }
          }
        });

        return {
          __typename: 'Subject',
          ...subject,
          gradeId: subject.gradeId,
          gradeName: subject.grade.name
        };
      } catch (error) {
        console.error('Error creating subject:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'Failed to create subject',
          path: ['createSubject']
        };
      }
    },

    updateSubject: async (_: any, { id, input }: { 
      id: string; 
      input: { 
        name?: string; 
        code?: string; 
        description?: string;
        gradeId?: string;
      } 
    }) => {
      try {
        // Check if subject exists
        const existingSubject = await prisma.subject.findUnique({
          where: { id: parseInt(id) }
        });

        if (!existingSubject) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: 'Subject not found',
            path: ['updateSubject']
          };
        }

        // If code is being updated, check if new code is already taken
        if (input.code && input.code !== existingSubject.code) {
          const codeExists = await prisma.subject.findUnique({
            where: { code: input.code }
          });

          if (codeExists) {
            return {
              __typename: 'Error',
              code: 'ALREADY_EXISTS',
              message: 'Subject with this code already exists',
              path: ['updateSubject']
            };
          }
        }

        // Validate grade if provided
        if (input.gradeId) {
          const grade = await prisma.grade.findUnique({
            where: { id: parseInt(input.gradeId) }
          });

          if (!grade) {
            return {
              __typename: 'Error',
              code: 'NOT_FOUND',
              message: 'Grade not found',
              path: ['updateSubject', 'gradeId']
            };
          }
        }

        const updateData: any = {};
        if (input.name !== undefined) updateData.name = input.name;
        if (input.code !== undefined) updateData.code = input.code;
        if (input.description !== undefined) updateData.description = input.description;
        if (input.gradeId !== undefined) updateData.gradeId = parseInt(input.gradeId);

        const subject = await prisma.subject.update({
          where: { id: parseInt(id) },
          data: updateData,
          include: {
            grade: {
              select: {
                id: true,
                name: true
              }
            }
          }
        });

        return {
          __typename: 'Subject',
          ...subject,
          gradeId: subject.gradeId,
          gradeName: subject.grade.name
        };
      } catch (error) {
        console.error('Error updating subject:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'Failed to update subject',
          path: ['updateSubject']
        };
      }
    },    

    deleteSubject: async (_: any, { id }: { id: string }) => {
      try {
        // Check if subject exists
        const existingSubject = await prisma.subject.findUnique({
          where: { id: parseInt(id) },
          include: {
            grade: {
              select: {
                id: true,
                name: true
              }
            }
          }
        });

        if (!existingSubject) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: 'Subject not found',
            path: ['deleteSubject']
          };
        }

        await prisma.subject.delete({
          where: { id: parseInt(id) }
        });

        return { 
          __typename: 'Subject',
          ...existingSubject,
          gradeId: existingSubject.gradeId,
          gradeName: existingSubject.grade.name
        };
      } catch (error) {
        console.error('Error deleting subject:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'Failed to delete subject',
          path: ['deleteSubject']
        };
      }
    }, 

    assignTeacher: async (_: any, { input }: { input: AssignTeacherInput }, context: Context) => {
      try {
        // Validate that the user exists and is a teacher
        const teacher = await prisma.user.findUnique({
          where: { id: parseInt(input.teacherId) },
        });

        if (!teacher) {
          return {
            __typename: "Error",
            success: false,
            error: {
              code: 'NOT_FOUND',
              message: `Teacher with ID ${input.teacherId} not found`,
              path: ['teacherId'],
            },
          };
        }

        if (teacher.role !== UserRole.TEACHER) {
          return {
            __typename: "BooleanResult",
            success: false,
            error: {
              code: 'INVALID_OPERATION',
              message: `User ${input.teacherId} is not a teacher`,
              path: ['teacherId'],
            },
          };
        }

        // Validate that all subjects exist
        if (input.subjectIds.length > 0) {
          const subjects = await prisma.subject.findMany({
            where: { id: { in: input.subjectIds.map(id => parseInt(id)) } },
          });

          if (subjects.length !== input.subjectIds.length) {
            const foundIds = subjects.map(s => s.id);
            const missingIds = input.subjectIds.filter(id => !foundIds.includes(parseInt(id)));
            return {
              __typename: "BooleanResult",
              success: false,
              error: {
                code: 'NOT_FOUND',
                message: `Subjects not found: ${missingIds.join(', ')}`,
                path: ['subjectIds'],
              },
            };
          }
        }

        // Validate that all grades exist
        if (input.gradeIds.length > 0) {
          const grades = await prisma.grade.findMany({
            where: { id: { in: input.gradeIds.map(str => parseInt(str)) } },
          });

          if (grades.length !== input.gradeIds.length) {
            const foundIds = grades.map(g => g.id);
            const missingIds = input.gradeIds.filter(id => !foundIds.includes(parseInt(id)));
            return {
              __typename: "BooleanResult",
              success: false,
              error: {
                code: 'NOT_FOUND',
                message: `Grades not found: ${missingIds.join(', ')}`,
                path: ['gradeIds'],
              },
            };
          }
        }

        await prisma.$transaction(async (tx) => {
          // Remove existing assignments for this teacher
          await tx.teacherSubject.deleteMany({
            where: { teacherId: parseInt(input.teacherId) },
          });

          await tx.teacherGrade.deleteMany({
            where: { teacherId: parseInt(input.teacherId) },
          });

          // Create new subject assignments
          if (input.subjectIds.length > 0) {
            await tx.teacherSubject.createMany({
              data: input.subjectIds.map(subjectId => ({
                teacherId: parseInt(input.teacherId),
                subjectId: parseInt(subjectId),
                assignedAt: new Date(),
                isActive: true,
              })),
            });
          }

          // Create new grade assignments
          if (input.gradeIds.length > 0) {
            await tx.teacherGrade.createMany({
              data: input.gradeIds.map(gradeId => ({
                teacherId: parseInt(input.teacherId),
                gradeId: parseInt(gradeId),
                assignedAt: new Date(),
                isActive: true,
              })),
            });
          }
        });

        return {
          __typename: "BooleanResult",
          success: true 
        };
      } catch (error) {
        console.error('Error assigning teacher:', error);
        return {
          success: false,
          error: {
            code: 'INTERNAL_ERROR',
            message: 'An error occurred while assigning the teacher',
            details: error,
          },
        };
      }
    },

    enrollStudent: async (_: any, { input }: { input: EnrollStudentInput }, context: Context) => {
      // Check authentication
      if (!context.user) {
        return {
          success: false,
          error: {
            code: 'UNAUTHORIZED',
            message: 'Authentication required',
          },
        };
      }

      // Check authorization - admins and teachers can enroll students
      if (!["ADMIN", "TEACHER"].includes(context.user.role)) {
        return {
          success: false,
          error: {
            code: 'FORBIDDEN',
            message: 'Only administrators and teachers can enroll students',
          },
        };
      }

      // Additional check: teachers can only enroll students in grades they teach
      if (context.user.role as UserRole === UserRole.TEACHER) {
        const teacherGrade = await prisma.teacherGrade.findFirst({
          where: {
            teacherId: context.user.id,
            gradeId: parseInt(input.gradeId),
            isActive: true,
          },
        });

        if (!teacherGrade) {
          return {
            success: false,
            error: {
              code: 'FORBIDDEN',
              message: 'Teachers can only enroll students in grades they teach',
            },
          };
        }
      }

      try {
        // Validate student exists and is a student
        const student = await prisma.user.findUnique({
          where: { id: parseInt(input.studentId) }
        });

        if (!student) {
          return {
            success: false,
            error: {
              code: 'NOT_FOUND',
              message: 'Student not found',
            },
          };
        }

        if (student.role !== UserRole.STUDENT) {
          return {
            success: false,
            error: {
              code: 'INVALID_OPERATION',
              message: 'User is not a student',
            },
          };
        }

        // Validate grade exists
        const grade = await prisma.grade.findUnique({
          where: { id: parseInt(input.gradeId) }
        });

        if (!grade) {
          return {
            success: false,
            error: {
              code: 'NOT_FOUND',
              message: 'Grade not found',
            },
          };
        }

        // Create enrollment
        await prisma.studentGrade.create({
          data: {
            studentId: parseInt(input.studentId),
            gradeId: parseInt(input.gradeId),
            enrolledAt: new Date(),
            isActive: true
          }
        });

        return {
          success: true
        };
      } catch (error) {
        console.error('Error enrolling student:', error);
        return {
          success: false,
          error: {
            code: 'INTERNAL_ERROR',
            message: 'An error occurred while enrolling the student',
          },
        };
      }
    },
  },
};