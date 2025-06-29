# MCSH Backend

A GraphQL Node.js TypeScript backend with Prisma ORM.

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- PostgreSQL (for database)

## Setup

1. Install dependencies:
```bash
npm install
```

2. Set up environment variables:
Create a `.env` file in the root directory with the following variables:
```
DATABASE_URL="postgresql://user:password@localhost:5432/dbname"
JWT_SECRET="your-jwt-secret"
```

3. Initialize the database:
```bash
npm run prisma:generate
npm run prisma:migrate
```

## Development

Start the development server:
```bash
npm run dev
```

## Testing

Run tests:
```bash
npm test
```

Run tests in watch mode:
```bash
npm run test:watch
```

Generate test coverage:
```bash
npm run test:coverage
```

## Building for Production

Build the project:
```bash
npm run build
```

Start the production server:
```bash
npm start
```

## Project Structure

```
src/
├── index.ts              # Application entry point
├── schema/              # GraphQL schema definitions
├── resolvers/           # GraphQL resolvers
├── models/              # Data models
├── services/            # Business logic
├── utils/              # Utility functions
└── tests/              # Test files
```

## License

ISC 