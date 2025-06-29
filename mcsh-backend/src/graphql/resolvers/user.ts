import { PrismaClient, UserRole } from '@prisma/client';
import bcrypt from 'bcryptjs';
import { Context } from '../../utils/auth';

const prisma = new PrismaClient();

// Input types
interface CreateUserInput {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  role: string; // UserRole enum as string
  profileImage?: string;
  phoneNumber?: string;
}

interface UpdateUserInput {
  firstName?: string;
  lastName?: string;
  email?: string;
  password?: string;
  role?: string; // UserRole enum as string
  status?: string; // UserStatus enum as string
  profileImage?: string;
  phoneNumber?: string;
}

interface UserFilterInput {
  role?: string;
  status?: string;
  search?: string;
}

interface UserSortInput {
  field: string;
  direction: string;
}

interface PaginationInput {
  first?: number;
  after?: string;
  last?: number;
  before?: string;
}

export const userResolvers = {
  // Type resolvers
  User: {
    fullName: (parent: any) => {
      return `${parent.firstName} ${parent.lastName}`;
    },
    
    teacherSubjects: async (parent: any) => {
      const teacherSubjects = await prisma.teacherSubject.findMany({
        where: { teacherId: parseInt(parent.id) },
        include: { subject: true }
      });
      
      return teacherSubjects.map(ts => ts.subject);
    },
    
    teacherGrades: async (parent: any) => {
      const teacherGrades = await prisma.teacherGrade.findMany({
        where: { teacherId: parseInt(parent.id) },
        include: { grade: true }
      });
      
      return teacherGrades.map(tg => tg.grade);
    },
    
    studentGrades: async (parent: any) => {
      const studentGrades = await prisma.studentGrade.findMany({
        where: { studentId: parseInt(parent.id) },
        include: { grade: true }
      });
      
      return studentGrades.map(sg => sg.grade);
    },
    
    
    createdExams: (parent: any) => {
      return prisma.exam.findMany({
        where: { createdById: parseInt(parent.id) }
      });
    },
        
    studentExams: (parent: any) => {
      return prisma.studentExam.findMany({
        where: { studentId: parseInt(parent.id) }
      });
    },
    
    notifications: (parent: any) => {
      return prisma.notification.findMany({
        where: { userId: parseInt(parent.id) }
      });
    }
  },
  
  // Query resolvers
  Query: {
    user: async (_: any, { id }: { id: string }, context: Context) => {  
      try {
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        const user = await prisma.user.findUnique({
          where: { id: parseInt(id) }
        });
        
        if (!user) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: `User with ID ${id} not found`
          };
        }
        
        return {
          __typename: 'User',
          ...user
        };
      } catch (error) {
        console.error('Error in user query:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },
    
    users: async (_: any, args: { 
      filter?: UserFilterInput; 
      sort?: UserSortInput;
      pagination?: PaginationInput;
    }, context: Context) => {
      try {
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        // Build where clause from filter
        const where: any = {};
        if (args.filter) {
          if (args.filter.role) {
            where.role = args.filter.role;
          }
          if (args.filter.status) {
            where.status = args.filter.status;
          }
          if (args.filter.search) {
            where.OR = [
              { firstName: { contains: args.filter.search, mode: 'insensitive' } },
              { lastName: { contains: args.filter.search, mode: 'insensitive' } },
              { email: { contains: args.filter.search, mode: 'insensitive' } }
            ];
          }
        }
        
        // Build orderBy from sort
        let orderBy: any = { lastName: 'asc' }; // Default sort
        if (args.sort) {
          switch (args.sort.field) {
            case 'FIRST_NAME':
              orderBy = { firstName: args.sort.direction.toLowerCase() };
              break;
            case 'LAST_NAME':
              orderBy = { lastName: args.sort.direction.toLowerCase() };
              break;
            case 'EMAIL':
              orderBy = { email: args.sort.direction.toLowerCase() };
              break;
            case 'CREATED_AT':
              orderBy = { createdAt: args.sort.direction.toLowerCase() };
              break;
            case 'ROLE':
              orderBy = { role: args.sort.direction.toLowerCase() };
              break;
            case 'STATUS':
              orderBy = { status: args.sort.direction.toLowerCase() };
              break;
          }
        }
        
        // Handle pagination (simplified for this example)
        const first = args.pagination?.first || 10;
        const skip = args.pagination?.after ? 1 : 0;
        
        // Get total count for pagination info
        const totalCount = await prisma.user.count({ where });
        
        // Get users
        const users = await prisma.user.findMany({
          where,
          orderBy,
          take: first,
          skip
        });
        
        // Create edges for connection pattern
        const edges = users.map(user => ({
          cursor: Buffer.from(`user-${user.id}`).toString('base64'),
          node: user
        }));
        
        // Determine pagination info
        const hasNextPage = totalCount > skip + users.length;
        const hasPreviousPage = skip > 0;
        
        return {
          __typename: 'UserConnection',
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
        console.error('Error in users query:', error);
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
    createUser: async (_: any, { input }: { input: CreateUserInput }, context: Context) => {
      try {
        // Only admins can create users
        if (!context.user || context.user.role !== 'ADMIN') {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'Only administrators can create users'
          };
        }
        
        // Check if email already exists
        const existingUser = await prisma.user.findUnique({
          where: { email: input.email }
        });
        
        if (existingUser) {
          return {
            __typename: 'Error',
            code: 'ALREADY_EXISTS',
            message: `User with email ${input.email} already exists`
          };
        }
        
        // Hash password
        const hashedPassword = await bcrypt.hash(input.password, 10);
        
        // Create user
        const user = await prisma.user.create({
          data: {
            firstName: input.firstName,
            lastName: input.lastName,
            email: input.email,
            password: hashedPassword,
            role: input.role as UserRole,
            status: 'PENDING', // Default status
            profileImage: input.profileImage,
            phoneNumber: input.phoneNumber
          }
        });
        
        return {
          __typename: 'User',
          ...user
        };
      } catch (error) {
        console.error('Error in createUser mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },
    
    updateUser: async (_: any, { id, input }: { id: string; input: UpdateUserInput }, context: Context) => {
      try {
        // Check authorization
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        // Find the user
        const user = await prisma.user.findUnique({
          where: { id: parseInt(id) }
        });
        
        if (!user) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: `User with ID ${id} not found`
          };
        }
        
        // Check permissions: Only self or admin can update
        if (context.user.id !== parseInt(id) && context.user.role !== 'ADMIN') {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'You can only update your own profile or must be an administrator'
          };
        }
        
        // Build update data
        const updateData: any = {};
        
        if (input.firstName) updateData.firstName = input.firstName;
        if (input.lastName) updateData.lastName = input.lastName;
        if (input.email) updateData.email = input.email;
        if (input.password) updateData.password = await bcrypt.hash(input.password, 10);
        if (input.profileImage !== undefined) updateData.profileImage = input.profileImage;
        if (input.phoneNumber !== undefined) updateData.phoneNumber = input.phoneNumber;
        
        // Only admins can update role and status
        if (context.user.role === 'ADMIN') {
          if (input.role) updateData.role = input.role;
          if (input.status) updateData.status = input.status;
        }
        
        // Update user
        const updatedUser = await prisma.user.update({
          where: { id: parseInt(id) },
          data: updateData
        });
        
        return {
          __typename: 'User',
          ...updatedUser
        };
      } catch (error) {
        console.error('Error in updateUser mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },
    
    deleteUser: async (_: any, { id }: { id: string }, context: Context) => {
      try {
        // Only admins can delete users
        if (!context.user || context.user.role !== 'ADMIN') {
          return {
            success: false,
            error: {
              code: 'FORBIDDEN',
              message: 'Only administrators can delete users'
            }
          };
        }
        
        // Find the user
        const user = await prisma.user.findUnique({
          where: { id: parseInt(id) }
        });
        
        if (!user) {
          return {
            success: false,
            error: {
              code: 'NOT_FOUND',
              message: `User with ID ${id} not found`
            }
          };
        }
        
        // Delete user
        await prisma.user.delete({
          where: { id: parseInt(id) }
        });
        
        return {
          success: true
        };
      } catch (error) {
        console.error('Error in deleteUser mutation:', error);
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
  
  // Union type resolvers
  UserResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      return obj.email ? 'User' : 'Error';
    }
  },
  
  UserConnectionResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      return obj.edges ? 'UserConnection' : 'Error';
    }
  }
}; 