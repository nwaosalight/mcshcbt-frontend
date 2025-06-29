import { prisma } from '../lib/prisma';

// Set test environment variables
process.env.JWT_SECRET = 'test-secret-key';
process.env.NODE_ENV = 'test';

// Clean up database after all tests
afterAll(async () => {
  await prisma.$disconnect();
}); 