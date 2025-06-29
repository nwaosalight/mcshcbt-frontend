import { ApolloServer } from 'apollo-server-express';
import { readFileSync } from 'fs';
import { join } from 'path';
import { resolvers } from './resolvers';
import { context } from './context';

const typeDefs = readFileSync(join(__dirname, 'schema.graphql'), 'utf-8');

export const server = new ApolloServer({
  typeDefs,
  resolvers,
  context,
  formatError: (error) => {
    // Add custom error formatting here
    return error;
  },
}); 