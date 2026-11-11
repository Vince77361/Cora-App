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
}
