import { ApiProperty } from '@nestjs/swagger';
import { UsageRights } from '@prisma/client';

// 고를 수 있는 값의 범위. 앱은 숫자를 따로 적지 않고 이 값으로 입력 칸을 만든다.
export class RewardRangeModel {
  @ApiProperty({ type: 'integer' })
  min!: number;

  @ApiProperty({ type: 'integer' })
  max!: number;

  @ApiProperty({ type: 'integer' })
  step!: number;

  @ApiProperty({ type: 'integer' })
  default!: number;
}

export class FixedCashMaxModel {
  @ApiProperty({ type: 'integer', description: '가게가 맡길 때의 최대(원).' })
  store!: number;

  @ApiProperty({ type: 'integer', description: '브랜드가 맡길 때의 최대(원).' })
  brand!: number;
}

export class FixedCashRangeModel {
  @ApiProperty({ type: FixedCashMaxModel })
  maxByCommissioner!: FixedCashMaxModel;

  @ApiProperty({ type: 'integer' })
  step!: number;

  @ApiProperty({ type: 'integer', isArray: true })
  presets!: number[];
}

export class VoucherDefaultsModel {
  @ApiProperty()
  defaultName!: string;

  @ApiProperty({ type: 'integer' })
  defaultValue!: number;

  @ApiProperty({ type: 'integer' })
  defaultPeople!: number;

  @ApiProperty({ type: 'integer' })
  maxPeople!: number;

  @ApiProperty({ type: 'integer', description: '식사권 금액의 최솟값(원).' })
  minValue!: number;

  @ApiProperty({ type: 'integer', description: '식사권 금액의 최댓값(원).' })
  maxValue!: number;
}

export class RewardConfigModel {
  @ApiProperty({ type: RewardRangeModel, description: '1,000회당 원.' })
  viewRate!: RewardRangeModel;

  @ApiProperty({ type: RewardRangeModel, description: '조회수 수당 상한(원).' })
  perViewCap!: RewardRangeModel;

  @ApiProperty({ type: FixedCashRangeModel })
  fixedCash!: FixedCashRangeModel;

  @ApiProperty({ type: VoucherDefaultsModel })
  voucher!: VoucherDefaultsModel;

  @ApiProperty({ enum: UsageRights, enumName: 'UsageRights' })
  usageRightsDefault!: UsageRights;

  @ApiProperty({
    type: 'integer',
    description: '게시 뒤 조회수를 재는 기간(일).',
  })
  countingDays!: number;
}

export class FeeRatesModel {
  @ApiProperty({ type: 'integer', description: '가게 오퍼 수수료율(%).' })
  storeOffer!: number;

  @ApiProperty({ type: 'integer', description: '입찰 수수료율(%).' })
  bid!: number;

  @ApiProperty({ type: 'integer', description: '브랜드 계약 수수료율(%).' })
  brandContract!: number;
}

export class AppConfigModel {
  @ApiProperty({ type: RewardConfigModel })
  reward!: RewardConfigModel;

  @ApiProperty({ type: FeeRatesModel })
  feeRates!: FeeRatesModel;
}
