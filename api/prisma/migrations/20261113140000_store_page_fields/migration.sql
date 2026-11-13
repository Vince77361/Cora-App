-- AlterEnum
ALTER TYPE "source_link_kind" ADD VALUE 'REVIEW_POST';

-- AlterTable
ALTER TABLE "stores" ADD COLUMN     "customer_phrases" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "recruit_line" TEXT,
ADD COLUMN     "slug" TEXT,
ADD COLUMN     "tags" TEXT[] DEFAULT ARRAY[]::TEXT[];

-- CreateIndex
CREATE UNIQUE INDEX "stores_slug_key" ON "stores"("slug");

