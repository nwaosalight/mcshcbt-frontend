import { PrismaClient } from '@prisma/client';
import { Context } from '../../../archieved/src/utils/auth';

const prisma = new PrismaClient();

export const gradeResolvers = {
  // Query resolvers
  Query: {
    grade: async (_: any, { id }: { id: string }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }

        const grade = await prisma.grade.findUnique({
          where: { id: parseInt(id) }
        });

        if (!grade) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: `Grade with ID ${id} not found`
          };
        }

        return {
          __typename: 'Grade',
          ...grade
        };
      } catch (error) {
        console.error('Error in grade query:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },

    grades: async (_: any, args: {
      filter?: { isActive?: boolean; search?: string };
      sort?: { field: string; direction: 'ASC' | 'DESC' };
      pagination?: { first?: number; after?: string; last?: number; before?: string };
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

        // Build where clause
        const where: any = {};
        if (args.filter) {
          if (args.filter.isActive !== undefined) {
            where.isActive = args.filter.isActive;
          }
          if (args.filter.search) {
            where.OR = [
              { name: { contains: args.filter.search, mode: 'insensitive' } },
              { description: { contains: args.filter.search, mode: 'insensitive' } }
            ];
          }
        }

        // Get total count
        const totalCount = await prisma.grade.count({ where });

        // Build orderBy
        const orderBy: any = args.sort
          ? { [args.sort.field]: args.sort.direction.toLowerCase() }
          : { createdAt: 'desc' };

        // Get grades with pagination
        const grades = await prisma.grade.findMany({
          where,
          orderBy,
          take: args.pagination?.first || 10,
          skip: args.pagination?.after ? 1 : 0,
          cursor: args.pagination?.after
            ? { id: parseInt(args.pagination.after) }
            : undefined,
        });

        // Build edges
        const edges = grades.map(grade => ({
          cursor: grade.id.toString(),
          node: grade,
        }));

        // Build page info
        const pageInfo = {
          hasNextPage: edges.length === (args.pagination?.first || 10),
          hasPreviousPage: !!args.pagination?.after,
          startCursor: edges[0]?.cursor || null,
          endCursor: edges[edges.length - 1]?.cursor || null,
        };

        return {
          __typename: 'GradeConnection',
          edges,
          pageInfo,
          totalCount,
        };
      } catch (error) {
        console.error('Error in grades query:', error);
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
    createGrade: async (_: any, { input }: { input: { name: string; description?: string; isActive?: boolean, academicYear: string } }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }

        // Authorization check - only admin can create grades
        if (context.user.role !== 'ADMIN') {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'Only administrators can create grades'
          };
        }

        // Check if grade with same name exists
        const existingGrade = await prisma.grade.findFirst({
          where: { name: input.name }
        });

        if (existingGrade) {
          return {
            __typename: 'Error',
            code: 'ALREADY_EXISTS',
            message: 'Grade with this name already exists'
          };
        }

        // Create grade
        const grade = await prisma.grade.create({
          data: {
            name: input.name,
            description: input.description,
            isActive: input.isActive ?? true,
            academicYear : input.academicYear
          }
        });

        return {
          __typename: 'Grade',
          ...grade
        };
      } catch (error) {
        console.error('Error in createGrade mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },

    updateGrade: async (_: any, { id, input }: { id: string; input: { name?: string; description?: string; isActive?: boolean } }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }

        // Authorization check - only admin can update grades
        if (context.user.role !== 'ADMIN') {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'Only administrators can update grades'
          };
        }

        // Check if grade exists
        const existingGrade = await prisma.grade.findUnique({
          where: { id: parseInt(id) }
        });

        if (!existingGrade) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: `Grade with ID ${id} not found`
          };
        }

        // If name is being updated, check if new name is already taken
        if (input.name && input.name !== existingGrade.name) {
          const nameExists = await prisma.grade.findFirst({
            where: { name: input.name }
          });

          if (nameExists) {
            return {
              __typename: 'Error',
              code: 'ALREADY_EXISTS',
              message: 'Grade with this name already exists'
            };
          }
        }

        // Update grade
        const grade = await prisma.grade.update({
          where: { id: parseInt(id) },
          data: {
            name: input.name,
            description: input.description,
            isActive: input.isActive
          }
        });

        return {
          __typename: 'Grade',
          ...grade
        };
      } catch (error) {
        console.error('Error in updateGrade mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },

    deleteGrade: async (_: any, { id }: { id: string }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return false;
        }

        // Authorization check - only admin can delete grades
        if (context.user.role !== 'ADMIN') {
          return false;
        }

        // Check if grade exists
        const existingGrade = await prisma.grade.findUnique({
          where: { id: parseInt(id) }
        });

        if (!existingGrade) {
          return false;
        }

        // Check if grade has any associated data
        const hasStudents = await prisma.studentGrade.findFirst({
          where: { gradeId: parseInt(id) }
        });

        const hasTeachers = await prisma.teacherGrade.findFirst({
          where: { gradeId: parseInt(id) }
        });

        const hasExams = await prisma.exam.findFirst({
          where: { gradeId: parseInt(id) }
        });

        if (hasStudents || hasTeachers || hasExams) {
          return false;
        }

        // Delete grade
        await prisma.grade.delete({
          where: { id: parseInt(id) }
        });

        return true;
      } catch (error) {
        console.error('Error in deleteGrade mutation:', error);
        return false;
      }
    }
  },

  // Union resolvers
  GradeResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      return obj.name ? 'Grade' : 'Error';
    }
  },

  GradeConnectionResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      return obj.edges ? 'GradeConnection' : 'Error';
    }
  }
}; 