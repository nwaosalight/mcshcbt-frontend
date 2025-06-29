-- AlterTable
ALTER TABLE "subjects" ADD COLUMN     "gradeId" INTEGER NOT NULL DEFAULT 1;

-- CreateIndex
CREATE INDEX "subjects_gradeId_idx" ON "subjects"("gradeId");

-- AddForeignKey
ALTER TABLE "subjects" ADD CONSTRAINT "subjects_gradeId_fkey" FOREIGN KEY ("gradeId") REFERENCES "grades"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
