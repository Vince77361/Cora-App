import { Body, Controller, Get, HttpCode, Patch } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { MeModel } from './dto/me.model';
import { UpdateRoleDto } from './dto/update-role.dto';
import { UsersService } from './users.service';

@ApiBearerAuth()
@Controller('me')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  // operationId는 생성되는 Dart 메서드 이름이 되므로 명시해 고정한다.
  @Get()
  @ApiOperation({ operationId: 'getMe' })
  @ApiOkResponse({ type: MeModel })
  getMe(@CurrentUser() user: AuthUser): Promise<MeModel> {
    return this.users.getMe(user.userId);
  }

  @Patch('role')
  @HttpCode(200)
  @ApiOperation({ operationId: 'updateMyRole' })
  @ApiOkResponse({ type: MeModel })
  setRole(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateRoleDto,
  ): Promise<MeModel> {
    return this.users.setRole(user.userId, dto.role);
  }
}
