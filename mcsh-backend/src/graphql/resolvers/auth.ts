import { PrismaClient, UserRole } from '@prisma/client';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { Context } from '../../utils/auth';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

interface SignupArgs {
  input: {
    email: string;
    role: string;
    password: string;
    firstName?: string;
    lastName?: string;
  }
}

interface LoginInput {
  email: string;
  password: string;
}

export const authResolvers = {
  Query: {
    me: async (_: any, __: any, context: Context) => {
      try {
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to perform this action'
          };
        }
        
        const user = await prisma.user.findUnique({
          where: { id: context.user.id }
        });
        
        if (!user) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: 'User not found'
          };
        }
        
        return {
          __typename: 'User',
          ...user,
          fullName: `${user.firstName} ${user.lastName}`
        };
      } catch (error) {
        console.error('Error in me query:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    }
  },
  
  Mutation: {
    signup: async (_: any, args: SignupArgs) => {
      const {email, role, password, firstName, lastName} = args.input;
      try {
        // Check if user with email already exists
        const existingUser = await prisma.user.findUnique({
          where: { email: email }
        });
        
        if (existingUser) {
          throw new Error(`User with email ${email} already exists`);
        }
        
        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);
        
        // Create new user
        const user = await prisma.user.create({
          data: {
            email: email,
            password: hashedPassword,
            firstName: firstName!, 
            lastName: lastName!,
            role: role as UserRole
          }
        });
        
        // Generate token
        const token = jwt.sign(
          { userId: user.id, role: user.role },
          JWT_SECRET,
          { expiresIn: '7d' }
        );
        
        return {
          token,
          user
        };
      } catch (error) {
        console.error('Error signing up:', error);
        throw error;
      }
    },
    
    login: async (_: any, { input }: { input: LoginInput }) => {
      try {
        const user = await prisma.user.findUnique({
          where: { email: input.email }
        });
        
        if (!user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'Invalid email or password'
          };
        }
        
        const passwordValid = await bcrypt.compare(input.password, user.password);
        
        if (!passwordValid) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'Invalid email or password'
          };
        }
        
        // Update lastLogin timestamp
        await prisma.user.update({
          where: { id: user.id },
          data: { lastLogin: new Date() }
        });
        
        const token = jwt.sign(
          { userId: user.id, role: user.role },
          JWT_SECRET,
          { expiresIn: '7d' }
        );
        
        return {
          __typename: 'AuthPayload',
          token,
          user: {
            ...user,
            fullName: `${user.firstName} ${user.lastName}`
          }
        };
      } catch (error) {
        console.error('Error in login mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred'
        };
      }
    },
    
    logout: async (_: any, __: any) => {
      try {
        // Since JWT is stateless, there's nothing to invalidate on the server
        // Client-side should remove the token
        return {
          success: true
        };
      } catch (error) {
        console.error('Error in logout mutation:', error);
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
  AuthResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      return obj.token ? 'AuthPayload' : 'Error';
    }
  },
  
  UserResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      return obj.email ? 'User' : 'Error';
    }
  }
}; 