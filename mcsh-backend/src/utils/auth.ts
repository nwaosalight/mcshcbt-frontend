import jwt from 'jsonwebtoken';
import { Request } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

export interface AuthUser {
  id: number;
  email: string;
  name?: string;
  role: string; 
}

export interface Context {
  user?: AuthUser;
  prisma: PrismaClient;
  req: Request;
}

export interface TokenPayload {
  id: string;
  role: 'ADMIN' | 'TEACHER' | 'STUDENT';
}

export const getUserFromToken = async (token: string): Promise<AuthUser | null> => {
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as { userId: number };
    
    if (!decoded.userId) {
      return null;
    }
    
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,  
        role: true, 
      }
    });
    
    return user as AuthUser | null;
  } catch (error) {
    return null;
  }
};

export const getContext = async ({ req }: { req: Request }): Promise<Context> => {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '');
  
  let contextUser: AuthUser | undefined = undefined;
  if (token) {
    const user = await getUserFromToken(token);
    if (user) {
      contextUser = user;
    }
  }
  
  return {
    user: contextUser,
    prisma,
    req
  };
};

export const generateToken = (payload: TokenPayload): string => {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '24h' });
};

export const verifyToken = (token: string): TokenPayload => {
  return jwt.verify(token, JWT_SECRET) as TokenPayload;
};

export const checkAuth = (context: Context): void => {
  if (!context.user) {
    throw new Error('Authentication required. Please sign in.');
  }
};

export const isCurrentUser = (context: Context, userId: number): void => {
  checkAuth(context);
  
  if (context.user!.id !== userId) {
    throw new Error('You can only perform this action for your own account.');
  }
}; 