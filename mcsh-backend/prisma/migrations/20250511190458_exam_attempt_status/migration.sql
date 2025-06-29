/*
  Warnings:

  - You are about to drop the column `attemptStatu` on the `exams` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "exams" DROP COLUMN "attemptStatu",
ADD COLUMN     "attemptStatus" "ExamAttemptStatus" NOT NULL DEFAULT 'NOT_STARTED';
