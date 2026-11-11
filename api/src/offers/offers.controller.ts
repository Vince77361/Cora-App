import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { ReceivedOffersQueryDto } from './dto/received-offers-query.dto';
import { ReceivedOfferModel } from './dto/received-offer.model';
import { SendOfferDto } from './dto/send-offer.dto';
import { SentOfferModel } from './dto/sent-offer.model';
import { StoreHomeSummaryModel } from './dto/store-home-summary.model';
import { OffersService } from './offers.service';

// 사장님 홈 숫자는 경로가 /stores 아래지만 오퍼 모듈이 만든다. "stores/me/summary"는 한 칸 더 깊어
// "stores/:id"(한 칸)에 읽히지 않는다.
@ApiBearerAuth()
@Controller()
export class OffersController {
  constructor(private readonly offers: OffersService) {}

  @Post('offers')
  @ApiOperation({ operationId: 'sendOffer' })
  @ApiCreatedResponse({ type: SentOfferModel })
  send(
    @CurrentUser() user: AuthUser,
    @Body() dto: SendOfferDto,
  ): Promise<SentOfferModel> {
    return this.offers.send(user.userId, dto);
  }

  @Get('offers/sent')
  @ApiOperation({ operationId: 'listSentOffers' })
  @ApiOkResponse({ type: [SentOfferModel] })
  listSent(@CurrentUser() user: AuthUser): Promise<SentOfferModel[]> {
    return this.offers.listSent(user.userId);
  }

  @Get('offers/received')
  @ApiOperation({ operationId: 'listReceivedOffers' })
  @ApiOkResponse({ type: [ReceivedOfferModel] })
  listReceived(
    @CurrentUser() user: AuthUser,
    @Query() query: ReceivedOffersQueryDto,
  ): Promise<ReceivedOfferModel[]> {
    return this.offers.listReceived(user.userId, query.tab);
  }

  @Post('offers/:id/cancel')
  @HttpCode(200)
  @ApiOperation({ operationId: 'cancelOffer' })
  @ApiOkResponse({ type: SentOfferModel })
  cancel(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<SentOfferModel> {
    return this.offers.cancel(user.userId, id);
  }

  @Post('offers/:id/accept')
  @HttpCode(200)
  @ApiOperation({ operationId: 'acceptOffer' })
  @ApiOkResponse({ type: ReceivedOfferModel })
  accept(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ReceivedOfferModel> {
    return this.offers.accept(user.userId, id);
  }

  @Post('offers/:id/decline')
  @HttpCode(200)
  @ApiOperation({ operationId: 'declineOffer' })
  @ApiOkResponse({ type: ReceivedOfferModel })
  decline(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ReceivedOfferModel> {
    return this.offers.decline(user.userId, id);
  }

  @Post('offers/:id/undo-decline')
  @HttpCode(200)
  @ApiOperation({ operationId: 'undoDeclineOffer' })
  @ApiOkResponse({ type: ReceivedOfferModel })
  undoDecline(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ReceivedOfferModel> {
    return this.offers.undoDecline(user.userId, id);
  }

  @Get('stores/me/summary')
  @ApiOperation({ operationId: 'getMyStoreSummary' })
  @ApiOkResponse({ type: StoreHomeSummaryModel })
  getMyStoreSummary(
    @CurrentUser() user: AuthUser,
  ): Promise<StoreHomeSummaryModel> {
    return this.offers.getHomeSummary(user.userId);
  }
}
