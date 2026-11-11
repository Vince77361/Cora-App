import { Body, Controller, Get, HttpCode, Patch } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { MeModel } from './dto/me.model';
import { UpdateRoleDto } from './dto/update-role.dto';
import { UsersService } from './users.service';

@ApiBearerAuth()
@Controller('me')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get()
  @ApiOkResponse({ type: MeModel })
  getMe(@CurrentUser() user: AuthUser): Promise<MeModel> {
    return this.users.getMe(user.userId);
  }

  @Patch('role')
  @HttpCode(200)
  @ApiOkResponse({ type: MeModel })
  setRole(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateRoleDto,
  ): Promise<MeModel> {
    return this.users.setRole(user.userId, dto.role);
  }
}
