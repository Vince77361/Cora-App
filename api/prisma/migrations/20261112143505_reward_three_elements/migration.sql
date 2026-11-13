-- 보상을 세 요소(식사권, 고정 현금, 조회수 수당)로 옮긴다.
-- 순서: 새 열 추가 → 값 채우기 → 옛 열 삭제. 한 파일이 한 번에 적용되므로 중간 상태가 남지 않는다.

-- CreateEnum
CREATE TYPE "usage_rights" AS ENUM ('STORE_REPOST_3M', 'STORE_REPOST_6M', 'NONE');

-- AlterEnum
ALTER TYPE "settlement_method" ADD VALUE 'FIXED_AND_PER_VIEW';

-- AlterTable: offers에 새 열을 더한다.
ALTER TABLE "offers"
ADD COLUMN     "fixed_cash" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "usage_rights" "usage_rights" NOT NULL DEFAULT 'NONE',
ADD COLUMN     "view_rate_per_thousand" INTEGER,
ADD COLUMN     "voucher_people" INTEGER;

-- AlterTable: stores에 새 열을 더한다.
ALTER TABLE "stores"
ADD COLUMN     "default_fixed_cash" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "default_per_view_cap" INTEGER,
ADD COLUMN     "default_usage_rights" "usage_rights" NOT NULL DEFAULT 'STORE_REPOST_3M',
ADD COLUMN     "default_view_rate_per_thousand" INTEGER,
ADD COLUMN     "default_voucher_people" INTEGER;

-- 값 채우기: offers. 단가는 "건당 원"에서 "1,000회당 원"으로(×1000), 옛 기본 이름은 이름 + 인원으로 나눈다.
-- 옛 오퍼에는 사용권 합의가 없었으므로 usage_rights는 열의 기본값 NONE 그대로다.
UPDATE "offers"
SET "view_rate_per_thousand" = "per_view_amount" * 1000
WHERE "per_view_amount" IS NOT NULL;

UPDATE "offers"
SET "voucher_name" = '식사권', "voucher_people" = 2
WHERE "voucher_name" = '2인 식사권';

-- 값 채우기: stores. 옛 기본 보상에 조회수가 있었으면 새 기본값(2,000원, 상한 60,000원)을 준다.
-- 가게의 기본값은 앞으로 보낼 오퍼에만 쓰이고, 옛 단가 10,000원은 새 범위 밖이다.
UPDATE "stores"
SET "default_view_rate_per_thousand" = 2000, "default_per_view_cap" = 60000
WHERE "default_reward_type" IN ('PER_VIEW', 'BOTH');

-- 옛 기본 보상에 식사권이 없었으면 식사권 칸을 비운다.
UPDATE "stores"
SET "default_voucher_name" = NULL, "default_voucher_value" = NULL
WHERE "default_reward_type" = 'PER_VIEW';

UPDATE "stores"
SET "default_voucher_name" = '식사권', "default_voucher_people" = 2
WHERE "default_voucher_name" = '2인 식사권';

-- 옛 열과 enum을 지운다.
ALTER TABLE "offers" DROP COLUMN "per_view_amount",
DROP COLUMN "reward_type";

ALTER TABLE "stores" DROP COLUMN "default_reward_type";

DROP TYPE "reward_type";

-- BEGIN legacy-reward-backfill
-- 협업의 조건 사본(jsonb)을 새 모양으로 다시 쓴다. 옛 키(rewardType, perViewAmount)가 있는 행만 건드리고
-- 다시 쓰면 그 키가 사라지므로, 두 번 돌려도 단가가 두 번 곱해지지 않는다.
-- maxCashBurden과 settlementMethod는 사본에 넣지 않는다(읽을 때 계산한다).
-- 결제·정산·장부·지급·환급 행은 건드리지 않는다.
UPDATE "collaborations"
SET "terms" = ("terms" - 'rewardType' - 'perViewAmount') || jsonb_build_object(
  'viewRatePerThousand',
  CASE
    WHEN jsonb_typeof("terms" -> 'perViewAmount') = 'number'
      THEN to_jsonb(("terms" ->> 'perViewAmount')::bigint * 1000)
    ELSE 'null'::jsonb
  END,
  'fixedCash', 0,
  'voucherName',
  CASE
    WHEN "terms" ->> 'voucherName' = '2인 식사권' THEN to_jsonb('식사권'::text)
    ELSE COALESCE("terms" -> 'voucherName', 'null'::jsonb)
  END,
  'voucherPeople',
  CASE
    WHEN "terms" ->> 'voucherName' = '2인 식사권' THEN to_jsonb(2)
    ELSE 'null'::jsonb
  END,
  'usageRights', 'NONE',
  'pieces', 1
)
WHERE "terms" -> 'rewardType' IS NOT NULL OR "terms" -> 'perViewAmount' IS NOT NULL;
-- END legacy-reward-backfill
