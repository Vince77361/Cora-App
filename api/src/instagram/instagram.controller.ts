import { Body, Controller, Delete, Get, HttpCode, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { CompleteInstagramConnectDto } from './dto/complete-instagram-connect.dto';
import {
  InstagramConnectionModel,
  InstagramConnectUrlModel,
} from './dto/instagram-connection.model';
import { InstagramService } from './instagram.service';

@ApiBearerAuth()
@Controller('instagram')
export class InstagramController {
  constructor(private readonly instagram: InstagramService) {}

  @Post('connect')
  @HttpCode(200)
  @ApiOperation({ operationId: 'beginInstagramConnect' })
  @ApiOkResponse({ type: InstagramConnectUrlModel })
  begin(@CurrentUser() user: AuthUser): Promise<InstagramConnectUrlModel> {
    return this.instagram.begin(user.userId);
  }

  @Post('connect/complete')
  @HttpCode(200)
  @ApiOperation({ operationId: 'completeInstagramConnect' })
  @ApiOkResponse({ type: InstagramConnectionModel })
  complete(
    @CurrentUser() user: AuthUser,
    @Body() dto: CompleteInstagramConnectDto,
  ): Promise<InstagramConnectionModel> {
    return this.instagram.complete(user.userId, dto.code);
  }

  @Get('connection')
  @ApiOperation({ operationId: 'getInstagramConnection' })
  @ApiOkResponse({ type: InstagramConnectionModel })
  get(@CurrentUser() user: AuthUser): Promise<InstagramConnectionModel> {
    return this.instagram.getMine(user.userId);
  }

  @Delete('connection')
  @HttpCode(204)
  @ApiOperation({ operationId: 'disconnectInstagram' })
  @ApiNoContentResponse()
  disconnect(@CurrentUser() user: AuthUser): Promise<void> {
    return this.instagram.disconnect(user.userId);
  }
}
