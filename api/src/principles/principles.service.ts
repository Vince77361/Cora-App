import { Injectable } from '@nestjs/common';
import { CreatorPrinciples, FeeBand } from '@prisma/client';
import { AppError } from '../common/errors/app-error';
import { UsersService } from '../users/users.service';
import { PrinciplesModel } from './dto/principles.model';
import { UpsertPrinciplesDto } from './dto/upsert-principles.dto';
import { PrinciplesRepository } from './principles.repository';

function toModel(row: CreatorPrinciples): PrinciplesModel {
  return {
    fields: row.fields,
    blockedIndustries: row.blockedIndustries,
    faceOk: row.faceOk,
    scriptOk: row.scriptOk,
    honestReview: row.honestReview,
    feeBand: row.feeBand,
    trialDays: row.trialDays,
  };
}

@Injectable()
export class PrinciplesService {
  constructor(
    private readonly principles: PrinciplesRepository,
    private readonly users: UsersService,
  ) {}

  async getMine(userId: string): Promise<PrinciplesModel> {
    await this.assertCreator(userId);
    const row = await this.principles.findByCreatorId(userId);
    if (!row) throw this.notFound();
    return toModel(row);
  }

  async upsertMine(
    userId: string,
    input: UpsertPrinciplesDto,
  ): Promise<PrinciplesModel> {
    await this.assertCreator(userId);
    return toModel(await this.principles.upsert(userId, input));
  }

  // 프로필 수정(E6)이 희망 보상대만 바꿀 때 쓴다. 원칙이 아직 없으면 404.
  // 역할을 확인하지 않는다: 호출하는 쪽(다른 모듈의 서비스)이 크리에이터인지 먼저 확인해야 한다.
  async updateFeeBand(
    creatorId: string,
    band: FeeBand,
  ): Promise<PrinciplesModel> {
    const row = await this.principles.updateFeeBand(creatorId, band);
    if (!row) throw this.notFound();
    return toModel(row);
  }

  // 다른 모듈(공통 필터, 카드)이 쓰는 조회. 원칙이 없으면 null이고 역할은 확인하지 않는다.
  async find(creatorId: string): Promise<PrinciplesModel | null> {
    const row = await this.principles.findByCreatorId(creatorId);
    return row ? toModel(row) : null;
  }

  // 여러 크리에이터의 원칙을 한 번에 읽는다. 원칙이 없는 크리에이터는 맵에 없다.
  async findMany(creatorIds: string[]): Promise<Map<string, PrinciplesModel>> {
    const rows = await this.principles.findByCreatorIds(creatorIds);
    return new Map(rows.map((row) => [row.creatorId, toModel(row)]));
  }

  private async assertCreator(userId: string): Promise<void> {
    if ((await this.users.getRole(userId)) !== 'CREATOR') {
      throw new AppError('FORBIDDEN', '크리에이터 계정만 쓸 수 있어요.');
    }
  }

  private notFound(): AppError {
    return new AppError('NOT_FOUND', '협업 원칙을 아직 정하지 않았어요.');
  }
}
