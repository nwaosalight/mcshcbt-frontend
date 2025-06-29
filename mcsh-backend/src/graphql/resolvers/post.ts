// import { PrismaClient } from '@prisma/client';
// import { Context, checkAuth } from '../../utils/auth';

// const prisma = new PrismaClient();

// interface CreatePostArgs {
//   title: string;
//   content?: string;
//   published?: boolean;
// }

// interface UpdatePostArgs {
//   id: number;
//   title?: string;
//   content?: string;
//   published?: boolean;
// }

// export const postResolvers = {
//   Post: {
//     author: (parent: any) => {
//       return prisma.user.findUnique({
//         where: { id: parent.authorId }
//       });
//     }
//   },
  
//   Query: {
//     posts: async () => {
//       return prisma.post.findMany({
//         where: { published: true }
//       });
//     },
//     post: async (_: any, args: { id: number }) => {
//       const post = await prisma.post.findUnique({
//         where: { id: args.id }
//       });
      
//       if (!post || !post.published) {
//         throw new Error(`Post with ID ${args.id} not found or not published`);
//       }
      
//       return post;
//     },
//     myPosts: async (_: any, __: any, context: Context) => {
//       // This endpoint requires authentication
//       checkAuth(context);
      
//       return prisma.post.findMany({
//         where: { authorId: context.user!.id }
//       });
//     }
//   },
  
//   Mutation: {
//     createPost: async (_: any, args: CreatePostArgs, context: Context) => {
//       // This endpoint requires authentication
//       checkAuth(context);
      
//       return prisma.post.create({
//         data: {
//           title: args.title,
//           content: args.content,
//           published: args.published ?? false,
//           authorId: context.user!.id
//         }
//       });
//     },
//     updatePost: async (_: any, args: UpdatePostArgs, context: Context) => {
//       // This endpoint requires authentication
//       checkAuth(context);
      
//       // Verify post exists and belongs to the user
//       const post = await prisma.post.findUnique({
//         where: { id: args.id }
//       });
      
//       if (!post) {
//         throw new Error(`Post with ID ${args.id} not found`);
//       }
      
//       if (post.authorId !== context.user!.id) {
//         throw new Error('You can only update your own posts');
//       }
      
//       return prisma.post.update({
//         where: { id: args.id },
//         data: {
//           ...(args.title && { title: args.title }),
//           ...(args.content !== undefined && { content: args.content }),
//           ...(args.published !== undefined && { published: args.published })
//         }
//       });
//     },
//     deletePost: async (_: any, args: { id: number }, context: Context) => {
//       // This endpoint requires authentication
//       checkAuth(context);
      
//       // Verify post exists and belongs to the user
//       const post = await prisma.post.findUnique({
//         where: { id: args.id }
//       });
      
//       if (!post) {
//         throw new Error(`Post with ID ${args.id} not found`);
//       }
      
//       if (post.authorId !== context.user!.id) {
//         throw new Error('You can only delete your own posts');
//       }
      
//       return prisma.post.delete({
//         where: { id: args.id }
//       });
//     }
//   }
// }; 