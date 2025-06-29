import express from 'express';
import { ApolloServer } from 'apollo-server-express';
import { resolvers } from './graphql/resolvers';
import fs from 'fs';
import path from 'path';
import { makeExecutableSchema } from '@graphql-tools/schema';
import { getContext } from './utils/auth';

async function startServer() {
  const app = express();
  
  // Read schema file
  const typeDefs = fs.readFileSync(
    path.join(__dirname, 'graphql', 'schema.graphql'),
    'utf8'
  );
  
  const schema = makeExecutableSchema({
    typeDefs,
    resolvers,
  });
  
  // Create Apollo Server
  const server = new ApolloServer({
    schema,
    context: async ({ req }) => {
      return await getContext({ req: req as any });
    },
  });

  await server.start()
  
  // Apply middleware (no need to await start() in v2.x)
  server.applyMiddleware({ app: app as any });
  
  // Start server
  const PORT = process.env.PORT || 4000;
  app.listen(PORT, () => {
    console.log(`Server is running at http://localhost:${PORT}${server.graphqlPath}`);
  });
}

startServer().catch((error) => {
  console.error('Error starting server:', error);
}); 