import { Body, Controller, Get, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { BankModel } from './dto/bank.model';
import { PayoutAccountModel } from './dto/payout-account.model';
import { UpsertPayoutAccountDto } from './dto/upsert-payout-account.dto';
import { PayoutAccountsService } from './payout-accounts.service';

@ApiBearerAuth()
@Controller('payout-account')
export class PayoutAccountsController {
  constructor(private readonly accounts: PayoutAccountsService) {}

  @Get('banks')
  @ApiOperation({ operationId: 'listBanks' })
  @ApiOkResponse({ type: BankModel, isArray: true })
  listBanks(): BankModel[] {
    return this.accounts.listBanks();
  }

  @Get()
  @ApiOperation({ operationId: 'getPayoutAccount' })
  @ApiOkResponse({ type: PayoutAccountModel })
  get(@CurrentUser() user: AuthUser): Promise<PayoutAccountModel> {
    return this.accounts.getMine(user.userId);
  }

  @Put()
  @ApiOperation({ operationId: 'upsertPayoutAccount' })
  @ApiOkResponse({ type: PayoutAccountModel })
  upsert(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpsertPayoutAccountDto,
  ): Promise<PayoutAccountModel> {
    return this.accounts.upsert(user.userId, dto);
  }
}
