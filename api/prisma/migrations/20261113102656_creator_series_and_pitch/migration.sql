-- AlterTable
ALTER TABLE "applications" ADD COLUMN     "pitch" TEXT,
ADD COLUMN     "skipped_from_picks_at" TIMESTAMPTZ(3);

-- CreateTable
CREATE TABLE "creator_series" (
    "id" UUID NOT NULL,
    "creator_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "format" "content_format" NOT NULL,
    "note" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "creator_series_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "creator_series_creator_id_idx" ON "creator_series"("creator_id");

-- AddForeignKey
ALTER TABLE "creator_series" ADD CONSTRAINT "creator_series_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- 앱은 이 테이블을 NestJS API로만 읽고 쓴다. RLS를 켜고 정책은 만들지 않는다.
ALTER TABLE "creator_series" ENABLE ROW LEVEL SECURITY;
