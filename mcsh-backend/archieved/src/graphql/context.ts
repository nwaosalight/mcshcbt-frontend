import { Request } from 'express';
import { prisma } from '../lib/prisma';
import { verifyToken } from '../utils/auth';

interface Context {
  prisma: typeof prisma;
  user?: {
    id: string;
    role: 'ADMIN' | 'TEACHER' | 'STUDENT';
  };
}

export const context = async ({ req }: { req: Request }): Promise<Context> => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return { prisma };
  }

  try {
    const user = verifyToken(token);
    return { prisma, user };
  } catch (error) {
    return { prisma };
  }
}; 