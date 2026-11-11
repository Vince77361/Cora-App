import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsIn, IsString, Matches, MaxLength, MinLength } from 'class-validator';
import { BANK_CODES } from '../banks';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

// 하이픈만 떼고 저장한다. 공백이나 다른 문자는 그대로 두어 숫자 검사에서 걸러진다.
const stripHyphens = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim().replace(/-/g, '') : value;

export class UpsertPayoutAccountDto {
  @ApiProperty({
    description: '은행 코드. GET /payout-account/banks의 code 중 하나.',
    enum: BANK_CODES,
  })
  @IsString()
  @IsIn(BANK_CODES)
  bankCode!: string;

  @ApiProperty({
    description: '계좌번호. 하이픈은 떼고 저장한다. 숫자 10~14자리.',
    example: '110123456789',
  })
  @Transform(stripHyphens)
  @IsString()
  @Matches(/^\d{10,14}$/, {
    message: '계좌번호는 숫자 10~14자리로 입력해 주세요.',
  })
  accountNumber!: string;

  @ApiProperty({ description: '예금주 이름.', minLength: 1, maxLength: 20 })
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(20)
  holderName!: string;
}
