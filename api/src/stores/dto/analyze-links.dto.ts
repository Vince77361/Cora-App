import { ApiProperty } from '@nestjs/swagger';
import { SourceLinkKind } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsEnum,
  IsString,
  MaxLength,
  ValidateBy,
  ValidateNested,
  ValidationArguments,
} from 'class-validator';
import {
  SOURCE_LINK_MESSAGES,
  isValidSourceLinkUrl,
} from '../source-link-rules';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

export class SourceLinkInputDto {
  @ApiProperty({ enum: SourceLinkKind, enumName: 'SourceLinkKind' })
  @IsEnum(SourceLinkKind)
  kind!: SourceLinkKind;

  @ApiProperty({
    maxLength: 500,
    description:
      '종류에 맞는 https 주소. 네이버 지도: naver.me, map.naver.com. 캐치테이블: app.catchtable.co.kr. 인스타그램: instagram.com, www.instagram.com.',
  })
  @Transform(trim)
  @IsString()
  @MaxLength(500)
  @ValidateBy({
    name: 'isSourceLinkUrl',
    validator: {
      // 종류가 틀렸으면 IsEnum이 이미 거절하므로 여기서는 종류에 맞는 주소인지만 본다.
      validate: (value: unknown, args?: ValidationArguments): boolean => {
        const kind = (args?.object as SourceLinkInputDto | undefined)?.kind;
        return (
          typeof value === 'string' &&
          kind !== undefined &&
          kind in SOURCE_LINK_MESSAGES &&
          isValidSourceLinkUrl(kind, value)
        );
      },
      defaultMessage: (args?: ValidationArguments): string => {
        const kind = (args?.object as SourceLinkInputDto | undefined)?.kind;
        return kind && kind in SOURCE_LINK_MESSAGES
          ? SOURCE_LINK_MESSAGES[kind]
          : '링크 주소가 올바르지 않아요.';
      },
    },
  })
  url!: string;
}

export class AnalyzeLinksDto {
  @ApiProperty({
    type: [SourceLinkInputDto],
    minItems: 1,
    maxItems: 3,
    description: '링크 1~3개. 같은 종류는 한 번만.',
  })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(3)
  @ArrayUnique((link: SourceLinkInputDto) => link.kind, {
    message: '같은 종류의 링크는 하나만 넣을 수 있어요.',
  })
  @ValidateNested({ each: true })
  @Type(() => SourceLinkInputDto)
  links!: SourceLinkInputDto[];
}
