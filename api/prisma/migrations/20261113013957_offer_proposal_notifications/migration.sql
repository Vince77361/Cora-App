-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "notification_kind" ADD VALUE 'OFFER_COUNTERED';
ALTER TYPE "notification_kind" ADD VALUE 'OFFER_REVISED';
ALTER TYPE "notification_kind" ADD VALUE 'OFFER_ACCEPTED_BY_STORE';
ALTER TYPE "notification_kind" ADD VALUE 'OFFER_ENDED';
