-- AlterTable
ALTER TABLE "settlements" ADD COLUMN     "multiplier_tenths" INTEGER,
ADD COLUMN     "usual_read_at" TIMESTAMPTZ(3),
ADD COLUMN     "usual_views" INTEGER;
