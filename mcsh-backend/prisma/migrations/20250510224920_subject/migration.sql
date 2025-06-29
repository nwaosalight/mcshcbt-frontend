-- DropIndex
DROP INDEX "subjects_name_key";

-- AlterTable
ALTER TABLE "subjects" ALTER COLUMN "name" SET DATA TYPE TEXT;
