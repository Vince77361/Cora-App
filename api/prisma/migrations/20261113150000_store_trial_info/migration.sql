-- AlterTable
ALTER TABLE "stores" ADD COLUMN     "trial_ends_on" DATE,
ADD COLUMN     "trial_hint_seen_at" TIMESTAMPTZ(3),
ADD COLUMN     "trial_monthly_fee" INTEGER,
ADD COLUMN     "trial_post_count" INTEGER,
ADD COLUMN     "trial_snoozed_until" TIMESTAMPTZ(3);

