import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { PaymentCreatedModel } from './dto/payment-created.model';
import { PaymentQuoteModel } from './dto/payment-quote.model';
import { PaymentStatusModel } from './dto/payment-status.model';
import { PaymentsService } from './payments.service';

@ApiBearerAuth()
@Controller()
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}

  @Get('collaborations/:id/payment-quote')
  @ApiOperation({ operationId: 'getPaymentQuote' })
  @ApiOkResponse({ type: PaymentQuoteModel })
  getQuote(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<PaymentQuoteModel> {
    return this.payments.getQuote(user.userId, id);
  }

  @Post('collaborations/:id/payments')
  @ApiOperation({ operationId: 'createPayment' })
  @ApiCreatedResponse({ type: PaymentCreatedModel })
  create(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: CreatePaymentDto,
  ): Promise<PaymentCreatedModel> {
    return this.payments.create(user.userId, id, dto.method);
  }

  @Get('payments/:id')
  @ApiOperation({ operationId: 'getPayment' })
  @ApiOkResponse({ type: PaymentStatusModel })
  getStatus(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<PaymentStatusModel> {
    return this.payments.getStatus(user.userId, id);
  }
}
