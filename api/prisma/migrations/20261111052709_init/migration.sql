-- CreateEnum
CREATE TYPE "user_role" AS ENUM ('STORE', 'BRAND', 'CREATOR');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "role" "user_role",
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- 앱은 데이터를 NestJS API로만 읽고 쓰므로 RLS를 켜고 정책은 만들지 않는다.
ALTER TABLE "users" ENABLE ROW LEVEL SECURITY;
-- prisma migrate dev의 shadow DB에는 _prisma_migrations가 아직 없으므로, 있을 때만 켠다.
DO $$
BEGIN
  IF to_regclass('"_prisma_migrations"') IS NOT NULL THEN
    ALTER TABLE "_prisma_migrations" ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;
