import { ApiProperty } from '@nestjs/swagger';
import { IndustryCategory } from '@prisma/client';
import { OfferTermsModel } from './offer-terms.model';

export type MyApplicationStatus = 'NONE' | 'APPLIED' | 'OFFERED';
export const MY_APPLICATION_STATUSES = ['NONE', 'APPLIED', 'OFFERED'] as const;

// 공개된 가게의 목록 카드. 공개 조건이므로 이름과 기본 조건은 항상 있다.
export class StoreSummaryModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty({ type: String, nullable: true })
  category!: string | null;

  @ApiProperty({ enum: IndustryCategory, enumName: 'IndustryCategory' })
  industry!: IndustryCategory;

  @ApiProperty({ type: String, nullable: true })
  neighborhood!: string | null;

  @ApiProperty({ type: String, nullable: true })
  regionSido!: string | null;

  @ApiProperty({ type: String, nullable: true })
  regionSigungu!: string | null;

  @ApiProperty({ type: String, nullable: true })
  coverPhotoUrl!: string | null;

  @ApiProperty({ type: OfferTermsModel })
  defaultTerms!: OfferTermsModel;
}

// 내가 이 가게와 주고받는 열린 오퍼. "내 방식으로 제안"을 어느 오퍼에 붙일지 정하는 데 쓴다.
export class MyOpenOfferModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ type: 'integer', description: '가장 새 판본의 번호.' })
  latestVersion!: number;

  @ApiProperty({
    description: '내가 응답할 차례이면 true. 내 방식으로 새 판본을 낼 수 있다.',
  })
  myTurn!: boolean;
}

export class StoreDetailModel extends StoreSummaryModel {
  @ApiProperty({ type: String, nullable: true })
  signatureMenu!: string | null;

  @ApiProperty({ type: String, nullable: true })
  hours!: string | null;

  @ApiProperty({ type: String, nullable: true })
  seats!: string | null;

  @ApiProperty({ type: String, nullable: true })
  bestShootingTime!: string | null;

  @ApiProperty({ type: String, nullable: true })
  intro!: string | null;

  @ApiProperty({
    enum: MY_APPLICATION_STATUSES,
    enumName: 'MyApplicationStatus',
    description: '내가 이 가게에 낸 지금 살아 있는 지원의 상태. 없으면 NONE.',
  })
  myApplicationStatus!: MyApplicationStatus;

  @ApiProperty({
    type: MyOpenOfferModel,
    nullable: true,
    description:
      '내가 이 가게와 주고받는 열린 오퍼(방금 거절해 되돌릴 수 있는 것 포함, 이때 myTurn은 false). 없으면 null.',
  })
  myOpenOffer!: MyOpenOfferModel | null;
}
