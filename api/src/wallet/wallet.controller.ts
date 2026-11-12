import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { WalletModel } from './dto/wallet.model';
import { WalletService } from './wallet.service';

// 크리에이터의 정산 화면(E7). 크리에이터 역할의 본인 것만 보인다.
@ApiBearerAuth()
@Controller('wallet')
export class WalletController {
  constructor(private readonly wallet: WalletService) {}

  @Get()
  @ApiOperation({ operationId: 'getWallet' })
  @ApiOkResponse({ type: WalletModel })
  get(@CurrentUser() user: AuthUser): Promise<WalletModel> {
    return this.wallet.get(user.userId);
  }
}
