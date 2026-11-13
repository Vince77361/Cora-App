import { ApiProperty } from '@nestjs/swagger';
import {
  IndustryCategory,
  SourceLinkKind,
  StoreOnboardingStep,
  StoreStatus,
} from '@prisma/client';
import { OfferTermsModel } from './offer-terms.model';

export class StoreSourceLinkModel {
  @ApiProperty({ enum: SourceLinkKind, enumName: 'SourceLinkKind' })
  kind!: SourceLinkKind;

  @ApiProperty()
  url!: string;

  @ApiProperty({ type: String, nullable: true })
  summary!: string | null;
}

// 주인에게만 보이는 가게. 링크 주소와 등록 단계가 들어 있다.
export class MyStoreModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: StoreStatus, enumName: 'StoreStatus' })
  status!: StoreStatus;

  @ApiProperty({ enum: StoreOnboardingStep, enumName: 'StoreOnboardingStep' })
  onboardingStep!: StoreOnboardingStep;

  @ApiProperty({ type: String, nullable: true })
  name!: string | null;

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
    type: String,
    nullable: true,
    description: '공개 주소 이름. 이름이 처음 생길 때 만들고 바꾸지 않는다.',
  })
  slug!: string | null;

  @ApiProperty({
    type: String,
    nullable: true,
    description: '공개 주소(cora.page/l/{slug}). 주소 이름이 없으면 null.',
  })
  publicUrl!: string | null;

  @ApiProperty({ type: [String], description: '꼬리표(# 없이).' })
  tags!: string[];

  @ApiProperty({ type: [String], description: '손님들이 자주 한 말.' })
  customerPhrases!: string[];

  @ApiProperty({ type: String, nullable: true })
  recruitLine!: string | null;

  @ApiProperty({ type: OfferTermsModel, nullable: true })
  defaultTerms!: OfferTermsModel | null;

  @ApiProperty({ type: [StoreSourceLinkModel] })
  sourceLinks!: StoreSourceLinkModel[];
}

export class AnalyzeStoreLinksResultModel {
  @ApiProperty({ type: MyStoreModel })
  store!: MyStoreModel;

  // true면 링크에서 정보를 읽지 못해 빈 가게로 만들었다. 앱이 "직접 입력할 수 있어요" 안내를 보여 준다.
  @ApiProperty()
  analysisFailed!: boolean;
}
