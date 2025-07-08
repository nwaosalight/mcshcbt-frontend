import { PrismaClient, QuestionType, ExamAttemptStatus } from '@prisma/client';
import { Context } from '../../utils/auth';

const prisma = new PrismaClient();

interface SubmitAnswerInput {
  studentExamId: string;
  questionId: string;
  selectedAnswer?: string;
  isMarked?: boolean;
  timeTaken?: number;
}

interface SubmitExamInput {
  studentExamId: string;
  answers?: SubmitAnswerInput[];
}

export const studentResolvers = {
  Query: {
    studentExam: async (_: any, { id }: { id: string }, context: Context) => {
      try {
        
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to view a student exam',
          };
        }
        const studentExam = await prisma.studentExam.findUnique({
          where: { id: parseInt(id) },
          include: {
            exam: true,
            student: true,
            studentAnswers: true,
          },
        });
        if (!studentExam) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: 'Student exam not found',
          };
        }
        // Only allow the student or an admin/teacher to view
        if (
          context.user.role === 'STUDENT' &&
          studentExam.studentId !== context.user.id
        ) {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'You are not authorized to view this student exam',
          };
        }
        // Return as StudentExam type
        return {
          __typename: 'StudentExam',
          ...studentExam,
          id: studentExam.id.toString(),
          uuid: studentExam.uuid,
          student: studentExam.student,
          exam: studentExam.exam,
          answers: studentExam.studentAnswers, // Map to 'answers' for GraphQL type
        };
      } catch (error) {
        console.error('Error in studentExam query:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred while fetching the student exam',
        };
      }
    },
    studentExams: async (_: any, { filter, sort, pagination }: any, context: Context) => {
      try {
        console.log(context.user)
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to view student exams',
          };
        }
        // Build Prisma where clause from filter
        const where: any = {};
        if (filter) {
          if (filter.studentId) where.studentId = parseInt(filter.studentId);
          if (filter.examId) where.examId = parseInt(filter.examId);
          if (filter.status) where.status = filter.status;
          if (filter.isPassed !== undefined) where.isPassed = filter.isPassed;
        }
        // Students can only see their own exams
        if (context.user.role === 'STUDENT') {
          where.studentId = context.user.id;
        }
        // Sorting
        let orderBy: any = undefined;
        if (sort) {
          orderBy = { [sort.field.replace(/([A-Z])/g, '_$1').toLowerCase()]: sort.direction.toLowerCase() };
        }
        // Pagination
        const take = pagination?.first || 10;
        const skip = pagination?.after ? 1 : 0; // Simple cursor-based pagination
        // Fetch data
        const [totalCount, studentExams] = await Promise.all([
          prisma.studentExam.count({ where }),
          prisma.studentExam.findMany({
            where,
            orderBy,
            take,
            skip,
            include: {
              exam: true,
              student: true,
              studentAnswers: true,
            },
          }),
        ]);
        // Build edges
        const edges = studentExams.map((se) => ({
          cursor: Buffer.from(se.id.toString()).toString('base64'),
          node: {
            __typename: 'StudentExam',
            ...se,
            id: se.id.toString(),
            uuid: se.uuid,
            student: se.student,
            exam: se.exam,
            answers: se.studentAnswers, // Map to 'answers' for GraphQL type
          },
        }));
        // PageInfo (simple, not full cursor implementation)
        const pageInfo = {
          hasNextPage: studentExams.length === take,
          hasPreviousPage: !!pagination?.before,
          startCursor: edges[0]?.cursor || null,
          endCursor: edges[edges.length - 1]?.cursor || null,
        };
        return {
          __typename: 'StudentExamConnection',
          edges,
          pageInfo,
          totalCount,
        };
      } catch (error) {
        console.error('Error in studentExams query:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred while fetching student exams',
        };
      }
    },
  },
  
  Mutation: {
    submitAnswer: async (_: any, { input }: { input: SubmitAnswerInput }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to submit an answer'
          };
        }

        // Role check
        if (context.user.role !== 'STUDENT') {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'Only students can submit answers'
          };
        }

        const userId = context.user.id;
        const { studentExamId, questionId, selectedAnswer, isMarked, timeTaken } = input;

        // Validate the student exam exists and belongs to the user
        const studentExam = await prisma.studentExam.findUnique({
          where: { id: parseInt(studentExamId) },
          include: {
            exam: {
              include: {
                questions: true
              }
            }
          }
        });

        if (!studentExam) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: 'Student exam not found'
          };
        }

        if (studentExam.studentId !== userId) {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'You are not authorized to submit answers for this exam'
          };
        }

        if (studentExam.status !== ExamAttemptStatus.IN_PROGRESS) {
          return {
            __typename: 'Error',
            code: 'EXAM_ALREADY_COMPLETED',
            message: 'Cannot submit answers for an exam that is not in progress'
          };
        }

        // Validate the question belongs to the exam
        const question = await prisma.question.findUnique({
          where: { id: parseInt(questionId) }
        });

        if (!question) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: 'Question not found'
          };
        }

        if (question.examId !== studentExam.examId) {
          return {
            __typename: 'Error',
            code: 'QUESTION_NOT_IN_EXAM',
            message: 'This question does not belong to the exam'
          };
        }

        // Check if time has expired
        const now = new Date();
        const startTime = studentExam.startTime;
        const durationInMs = studentExam.exam.duration * 60 * 1000;
        
        if (startTime && (now.getTime() - startTime.getTime() > durationInMs)) {
          // Time expired - automatically submit the exam
          await studentResolvers.Mutation.submitExam(null, { input: { studentExamId } }, context);
          return {
            __typename: 'Error',
            code: 'TIME_EXPIRED',
            message: 'Time has expired for this exam'
          };
        }

        // Determine if the answer is correct (for auto-graded questions)
        let isCorrect = null;
        
        if (selectedAnswer !== undefined && selectedAnswer !== null) {
          // Only evaluate correctness for certain question types and if an answer is provided
          if (
            question.questionType === QuestionType.MULTIPLE_CHOICE ||
            question.questionType === QuestionType.TRUE_FALSE
          ) {
            isCorrect = selectedAnswer === question.correctAnswer;
          }
        }

        // Create or update the student answer
        const updatedAnswer = await prisma.studentAnswer.upsert({
          where: {
            studentExamId_questionId: {
              studentExamId: parseInt(studentExamId),
              questionId: parseInt(questionId)
            }
          },
          create: {
            studentId: userId,
            examId: studentExam.examId,
            questionId: parseInt(questionId),
            studentExamId: parseInt(studentExamId),
            selectedAnswer: selectedAnswer || null,
            isCorrect,
            isMarked: isMarked || false,
            timeTaken: timeTaken || null,
            answeredAt: new Date()
          },
          update: {
            selectedAnswer: selectedAnswer !== undefined ? selectedAnswer : undefined,
            isCorrect: isCorrect !== null ? isCorrect : undefined,
            isMarked: isMarked !== undefined ? isMarked : undefined,
            timeTaken: timeTaken !== undefined ? timeTaken : undefined,
            answeredAt: new Date()
          }
        });

        // Publish event if needed (can be implemented with a PubSub system)
        // pubsub.publish('ANSWER_SUBMITTED', { answerSubmitted: updatedAnswer });

        return {
          __typename: 'StudentAnswer',
          ...updatedAnswer,
          uuid: updatedAnswer.uuid,
          id: updatedAnswer.id.toString(),
          student: { id: userId.toString() },
          question: { id: question.id.toString() },
          studentExam: { id: studentExam.id.toString() }
        };
      } catch (error) {
        console.error('Error in submitAnswer mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred while submitting your answer'
        };
      }
    },
    submitExam: async (_: any, { input }: { input: SubmitExamInput }, context: Context) => {
      try {
        // Authentication check
        if (!context.user) {
          return {
            __typename: 'Error',
            code: 'UNAUTHORIZED',
            message: 'You must be logged in to submit an exam'
          };
        }

        // Role check
        // if (context.user.role !== 'STUDENT') {
        //   return {
        //     __typename: 'Error',
        //     code: 'FORBIDDEN',
        //     message: 'Only students can submit exams'
        //   };
        // }

        const userId = context.user.id;
        const { studentExamId, answers } = input;

        // Validate the student exam exists and belongs to the user
        const studentExam = await prisma.studentExam.findUnique({
          where: { id: parseInt(studentExamId) },
          include: {
            exam: {
              include: {
                questions: true
              }
            }
          }
        });

        if (!studentExam) {
          return {
            __typename: 'Error',
            code: 'NOT_FOUND',
            message: 'Student exam not found'
          };
        }

        if (studentExam.studentId !== userId) {
          return {
            __typename: 'Error',
            code: 'FORBIDDEN',
            message: 'You are not authorized to submit this exam'
          };
        }

        if (studentExam.status === ExamAttemptStatus.COMPLETED || 
            studentExam.status === ExamAttemptStatus.GRADED) {
          return {
            __typename: 'Error',
            code: 'EXAM_ALREADY_COMPLETED',
            message: 'This exam has already been submitted'
          };
        }

        // Check time expiration
        const now = new Date();
        const startTime = studentExam.startTime;
        const durationInMs = studentExam.exam.duration * 60 * 1000;
        
        if (startTime && (now.getTime() - startTime.getTime() > durationInMs)) {
          return {
            __typename: 'Error',
            code: 'TIME_EXPIRED',
            message: 'Time has expired for this exam'
          };
        }

        // Process bulk answers if provided
        if (answers && answers.length > 0) {
          // Validate all questions belong to the exam
          const invalidQuestion = answers.find(answer => 
            !studentExam.exam.questions.some(q => q.id === parseInt(answer.questionId))
          );

          if (invalidQuestion) {
            return {
              __typename: 'Error',
              code: 'QUESTION_NOT_IN_EXAM',
              message: 'One or more questions do not belong to this exam'
            };
          }

          // Bulk create/update student answers
          await Promise.all(answers.map(async (answer) => {
            // Find the corresponding question
            const question = studentExam.exam.questions.find(
              q => q.id === parseInt(answer.questionId)
            );

            // Determine if the answer is correct (for auto-graded questions)
            let isCorrect = null;
            if (answer.selectedAnswer !== undefined && answer.selectedAnswer !== null) {
              if (
                question?.questionType === QuestionType.MULTIPLE_CHOICE ||
                question?.questionType === QuestionType.TRUE_FALSE
              ) {
                isCorrect = answer.selectedAnswer === question.correctAnswer;
              }
            }

            // Upsert the student answer
            return prisma.studentAnswer.upsert({
              where: {
                studentExamId_questionId: {
                  studentExamId: parseInt(studentExamId),
                  questionId: parseInt(answer.questionId)
                }
              },
              create: {
                studentId: userId,
                examId: studentExam.examId,
                questionId: parseInt(answer.questionId),
                studentExamId: parseInt(studentExamId),
                selectedAnswer: answer.selectedAnswer || null,
                isCorrect,
                isMarked: answer.isMarked || false,
                timeTaken: answer.timeTaken || null,
                answeredAt: new Date()
              },
              update: {
                selectedAnswer: answer.selectedAnswer !== undefined ? answer.selectedAnswer : undefined,
                isCorrect: isCorrect !== null ? isCorrect : undefined,
                isMarked: answer.isMarked !== undefined ? answer.isMarked : undefined,
                timeTaken: answer.timeTaken !== undefined ? answer.timeTaken : undefined,
                answeredAt: new Date()
              }
            });
          }));
        }

        // Calculate the time spent
        const endTime = new Date();
        const timeSpent = startTime ? Math.floor((endTime.getTime() - startTime.getTime()) / 1000) : null;

        // Calculate the score for auto-graded questions
        let totalPoints = 0;
        let earnedPoints = 0;
        let answeredQuestions = 0;

        // Fetch all student answers to include the most recent updates
        const allStudentAnswers = await prisma.studentAnswer.findMany({
          where: { studentExamId: parseInt(studentExamId) },
          include: {
            question: true
          }
        });

        studentExam.exam.questions.forEach(question => {
          totalPoints += question.points;
          
          const answer = allStudentAnswers.find(a => a.questionId === question.id);
          if (answer) {
            answeredQuestions++;
            if (answer.isCorrect === true) {
              earnedPoints += question.points;
            }
          }
        });

        // Calculate score as a percentage
        const score = totalPoints > 0 ? (earnedPoints / totalPoints) * 100 : 0;
        
        // Determine if the student passed based on passmark
        const isPassed = studentExam.exam.passmark ? score >= studentExam.exam.passmark : null;

        // Update the student exam record
        const updatedStudentExam = await prisma.studentExam.update({
          where: { id: parseInt(studentExamId) },
          data: {
            endTime,
            timeSpent,
            score,
            isPassed,
            status: ExamAttemptStatus.COMPLETED
          }
        });

        // Create a notification for the student
        await prisma.notification.create({
          data: {
            userId,
            title: 'Exam Completed',
            message: `You have completed the exam: ${studentExam.exam.title} with a score of ${score.toFixed(2)}%`,
            type: 'INFO'
          }
        });

        // Create a notification for the teacher
        await prisma.notification.create({
          data: {
            userId: studentExam.exam.createdById,
            title: 'Exam Submission',
            message: `A student has submitted the exam: ${studentExam.exam.title}`,
            type: 'INFO'
          }
        });

        return {
          __typename: 'StudentExam',
          ...updatedStudentExam,
          uuid: updatedStudentExam.uuid,
          id: updatedStudentExam.id.toString(),
          student: { id: userId.toString() },
          exam: { id: studentExam.exam.id.toString() },
          progress: 100,
          remainingTime: 0,
          answeredCount: answeredQuestions,
          markedCount: allStudentAnswers.filter(a => a.isMarked).length
        };
      } catch (error) {
        console.error('Error in submitExam mutation:', error);
        return {
          __typename: 'Error',
          code: 'INTERNAL_ERROR',
          message: 'An internal error occurred while submitting your exam'
        };
      }
    }
  },

  // Union type resolvers
  StudentExamResult: {
    __resolveType(obj: any) {
      if (obj.__typename) return obj.__typename;
      return obj.status !== undefined ? 'StudentExam' : 'Error';
    }
  }
};