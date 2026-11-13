import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { Store, StoreOnboardingStep } from '@prisma/client';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { SIDO_LIST } from '../common/regions';
import { CreatorsService } from '../creators/creators.service';
import { StoragePort } from '../integrations/storage/storage.port';
import {
  SourceLinkInput,
  StoreLinkAnalysisError,
  StoreLinkPort,
  StoreLinkResult,
} from '../integrations/store-link/store-link.port';
import { UploadsService } from '../uploads/uploads.service';
import { UsersService } from '../users/users.service';
import { AdvanceStep } from './dto/advance-onboarding.dto';
import {
  AnalyzeStoreLinksResultModel,
  MyStoreModel,
} from './dto/my-store.model';
import { OfferTermsModel } from './dto/offer-terms.model';
import { SetDefaultTermsDto } from './dto/set-default-terms.dto';
import { StoreDetailModel, StoreSummaryModel } from './dto/store-public.model';
import { UpdateStoreDto } from './dto/update-store.dto';
import { buildTerms, termsModelOf } from './reward-terms';
import {
  StoreFields,
  StoresRepository,
  StoreWithLinks,
} from './stores.repository';

// 등록 단계의 순서. 앞으로만 간다.
const STEP_ORDER: StoreOnboardingStep[] = ['PAGE', 'DRAFTS', 'TERMS', 'DONE'];

// 사진 형식에서 저장 확장자를 정한다. 사진 업로드 규칙(JPEG, PNG, HEIC)과 같은 목록이다.
const EXTENSION_BY_CONTENT_TYPE: Record<string, string | undefined> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/heic': 'heic',
};

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// 비어 있거나 공백뿐이면 null. DTO가 이미 다듬지만 서비스를 직접 부르는 곳에서도 같은 규칙이 지켜지게 한다.
function blankToNull(value: string | null | undefined): string | null {
  const text = value?.trim();
  return text ? text : null;
}

// 지역 정렬 묶음: 구·군이 같으면 0, 시·도만 같으면 1, 그 밖은 2.
function regionTier(
  store: Store,
  mine: { regionSido: string; regionSigungu: string | null } | null,
): number {
  if (!mine || store.regionSido !== mine.regionSido) return 2;
  return mine.regionSigungu !== null &&
    store.regionSigungu === mine.regionSigungu
    ? 0
    : 1;
}

@Injectable()
export class StoresService {
  constructor(
    private readonly stores: StoresRepository,
    private readonly users: UsersService,
    private readonly uploads: UploadsService,
    private readonly storage: StoragePort,
    private readonly storeLink: StoreLinkPort,
    private readonly creators: CreatorsService,
    private readonly clock: Clock,
  ) {}

  // 링크를 분석해 등록 중인 가게를 만들거나 덮어쓴다. 분석이 실패해도 링크만 저장한 빈 가게로 이어 간다.
  async analyze(
    userId: string,
    links: SourceLinkInput[],
  ): Promise<AnalyzeStoreLinksResultModel> {
    await this.assertStoreRole(userId);
    // 이미 공개된 가게면 비용이 드는 분석을 하기 전에 막는다. 저장 단계에서도 한 번 더 확인한다.
    if (
      (await this.stores.findActiveByOwnerId(userId))?.status === 'PUBLISHED'
    ) {
      throw this.alreadyPublished();
    }

    let result: StoreLinkResult | null = null;
    try {
      result = await this.storeLink.analyze(links);
    } catch (error) {
      // 읽지 못한 것은 사용자가 직접 채울 수 있다. 그 밖의 예외는 우리 쪽 문제라 그대로 올린다.
      if (!(error instanceof StoreLinkAnalysisError)) throw error;
    }

    const saved = await this.stores.replaceDraft(
      userId,
      await this.fieldsFrom(userId, result),
      links.map((link) => ({
        kind: link.kind,
        url: link.url,
        summary:
          result?.linkSummaries.find((s) => s.kind === link.kind)?.summary ??
          null,
      })),
      this.clock.now(),
    );
    if (!saved) throw this.alreadyPublished();
    return { store: this.toMyStore(saved), analysisFailed: result === null };
  }

  // 읽기는 주인 여부만 본다. 역할을 바꿔도 내 가게는 그대로 읽힌다.
  async getMine(userId: string): Promise<MyStoreModel> {
    return this.toMyStore(await this.requireMine(userId));
  }

  async update(userId: string, input: UpdateStoreDto): Promise<MyStoreModel> {
    await this.assertStoreRole(userId);
    const store = await this.requireMine(userId);
    const data: Partial<StoreFields> = {};
    if (input.name !== undefined) {
      const name = blankToNull(input.name);
      if (!name) {
        throw new AppError('VALIDATION_FAILED', '가게 이름을 넣어 주세요.');
      }
      data.name = name;
    }
    for (const key of [
      'category',
      'neighborhood',
      'regionSigungu',
      'signatureMenu',
      'hours',
      'seats',
      'bestShootingTime',
      'intro',
    ] as const) {
      if (input[key] !== undefined) data[key] = blankToNull(input[key]);
    }
    if (input.industry !== undefined) data.industry = input.industry;
    if (input.regionSido !== undefined) {
      if (!(SIDO_LIST as readonly string[]).includes(input.regionSido)) {
        throw new AppError('VALIDATION_FAILED', '시·도를 골라 주세요.');
      }
      data.regionSido = input.regionSido;
    }
    if (input.coverPhotoPath !== undefined) {
      const path = blankToNull(input.coverPhotoPath);
      // 남의 사진이나 임의 경로를 끼워 넣지 못하게 저장 전에 소유자를 확인한다.
      if (path) this.uploads.assertOwnedPath(userId, path, 'STORE_COVER');
      data.coverPhotoPath = path;
    }
    return this.toMyStore(await this.stores.update(store.id, data));
  }

  // 앞 단계로만 간다. 같거나 뒤 단계 요청은 바꾸지 않고 지금 상태를 돌려준다.
  async advanceOnboarding(
    userId: string,
    step: AdvanceStep,
  ): Promise<MyStoreModel> {
    await this.assertStoreRole(userId);
    const store = await this.requireMine(userId);
    if (STEP_ORDER.indexOf(step) <= STEP_ORDER.indexOf(store.onboardingStep)) {
      return this.toMyStore(store);
    }
    return this.toMyStore(await this.stores.setOnboardingStep(store.id, step));
  }

  // 등록 중이든 공개 뒤든 고칠 수 있다. 기본값과 조회 단가를 채운 값을 저장한다.
  async setDefaultTerms(
    userId: string,
    input: SetDefaultTermsDto,
  ): Promise<MyStoreModel> {
    await this.assertStoreRole(userId);
    const store = await this.requireMine(userId);
    const terms = buildTerms(input);
    return this.toMyStore(
      await this.stores.setDefaultTerms(store.id, {
        format: terms.format,
        voucherName: terms.voucherName,
        voucherValue: terms.voucherValue,
        voucherPeople: terms.voucherPeople,
        fixedCash: terms.fixedCash,
        viewRatePerThousand: terms.viewRatePerThousand,
        perViewCap: terms.perViewCap,
        usageRights: terms.usageRights,
      }),
    );
  }

  async publish(userId: string): Promise<MyStoreModel> {
    await this.assertStoreRole(userId);
    const store = await this.requireMine(userId);
    if (store.status === 'PUBLISHED') return this.toMyStore(store);
    if (!store.name) {
      throw new AppError('CONFLICT', '가게 이름을 넣어 주세요.');
    }
    if (!store.defaultFormat) {
      throw new AppError('CONFLICT', '기본 오퍼 조건을 정해 주세요.');
    }
    if (!store.regionSido) {
      throw new AppError('CONFLICT', '가게가 있는 시·도를 골라 주세요.');
    }
    return this.toMyStore(
      await this.stores.publish(store.id, this.clock.now()),
    );
  }

  // 공개된 가게 목록. 내 가게는 빠지고, 내 활동 지역과 가까운 가게가 먼저 나온다(같은 묶음에서는 최근 공개 순).
  async listPublished(userId: string): Promise<StoreSummaryModel[]> {
    const [rows, creator] = await Promise.all([
      this.stores.listPublished(userId),
      this.creators.getSummary(userId),
    ]);
    // 크리에이터 프로필이 없으면 지역을 모르므로 최근 공개 순만 쓴다.
    const mine = creator
      ? { regionSido: creator.regionSido, regionSigungu: creator.regionSigungu }
      : null;
    return rows
      .map((row, index) => ({ row, index, tier: regionTier(row, mine) }))
      .sort((a, b) => a.tier - b.tier || a.index - b.index)
      .map(({ row }) => this.toSummary(row));
  }

  // 내 가게여도 공개된 것만 보인다(미리 보기). 등록 중인 가게는 누구에게나 404다.
  async getPublished(
    userId: string,
    storeId: string,
  ): Promise<StoreDetailModel> {
    const store = UUID.test(storeId)
      ? await this.stores.findPublishedDetail(storeId, userId)
      : null;
    if (!store) throw new AppError('NOT_FOUND', '가게를 찾을 수 없어요.');
    const mine = store.applications[0]?.status;
    return {
      ...this.toSummary(store),
      signatureMenu: store.signatureMenu,
      hours: store.hours,
      seats: store.seats,
      bestShootingTime: store.bestShootingTime,
      intro: store.intro,
      myApplicationStatus:
        mine === 'APPLIED' || mine === 'OFFERED' ? mine : 'NONE',
    };
  }

  // 다른 모듈(지원, 오퍼, 초안)이 쓰는 조회. 내 가게가 없으면 404.
  async requireMyStore(userId: string): Promise<Store> {
    return this.requireMine(userId);
  }

  // uuid 모양이 아닌 값은 DB에 보내지 않고 없는 가게로 본다(500이 되지 않게).
  async requirePublished(storeId: string): Promise<Store> {
    const store = UUID.test(storeId)
      ? await this.stores.findPublishedById(storeId)
      : null;
    if (!store) throw new AppError('NOT_FOUND', '가게를 찾을 수 없어요.');
    return store;
  }

  // 오퍼 모듈이 받은 오퍼 카드와 알림 대상을 만들 때 쓴다. 공개된 가게가 아니면 null.
  async getOfferCard(storeId: string): Promise<{
    ownerId: string;
    // 알림이 가게 사진 경로를 사본으로 저장할 때 쓴다(응답에는 URL만 나간다).
    coverPhotoPath: string | null;
    summary: StoreSummaryModel;
    intro: string | null;
    bestShootingTime: string | null;
  } | null> {
    const store = UUID.test(storeId)
      ? await this.stores.findPublishedById(storeId)
      : null;
    if (!store) return null;
    return {
      ownerId: store.ownerId,
      coverPhotoPath: store.coverPhotoPath,
      summary: this.toSummary(store),
      intro: store.intro,
      bestShootingTime: store.bestShootingTime,
    };
  }

  private async requireMine(userId: string): Promise<StoreWithLinks> {
    const store = await this.stores.findActiveByOwnerId(userId);
    if (!store) throw new AppError('NOT_FOUND', '가게를 먼저 만들어 주세요.');
    return store;
  }

  private async assertStoreRole(userId: string): Promise<void> {
    if ((await this.users.getRole(userId)) !== 'STORE') {
      throw new AppError('FORBIDDEN', '가게 계정만 쓸 수 있어요.');
    }
  }

  private alreadyPublished(): AppError {
    return new AppError('CONFLICT', '이미 공개한 가게는 다시 만들 수 없어요.');
  }

  // 분석 결과(없으면 빈 가게)를 저장할 글자 항목으로 바꾸고, 대표 사진은 우리 Storage로 복사한다.
  private async fieldsFrom(
    userId: string,
    result: StoreLinkResult | null,
  ): Promise<StoreFields> {
    const found = result?.store;
    return {
      name: blankToNull(found?.name),
      category: blankToNull(found?.category),
      // 분석이 추측하지 못하면 기본값이다(공통 모델 3장).
      industry: found?.industry ?? 'FOOD_CAFE',
      neighborhood: blankToNull(found?.neighborhood),
      // 고정 목록에 없는 값은 쓰지 않는다. 지역 정렬과 공개 조건이 이 값을 믿는다.
      regionSido: (
        SIDO_LIST as readonly (string | null | undefined)[]
      ).includes(found?.regionSido)
        ? (found?.regionSido ?? null)
        : null,
      regionSigungu: blankToNull(found?.regionSigungu),
      coverPhotoPath: await this.copyCover(userId, result),
      signatureMenu: blankToNull(found?.signatureMenu),
      hours: blankToNull(found?.hours),
      seats: blankToNull(found?.seats),
      bestShootingTime: blankToNull(found?.bestShootingTime),
      intro: blankToNull(found?.intro),
    };
  }

  // 외부 주소를 그대로 쓰지 않고 우리 Storage에 복사한다. 형식을 모르면 사진 없이 둔다.
  private async copyCover(
    userId: string,
    result: StoreLinkResult | null,
  ): Promise<string | null> {
    const cover = result?.coverPhoto;
    const extension = cover && EXTENSION_BY_CONTENT_TYPE[cover.contentType];
    if (!cover || !extension) return null;
    const path = `stores/${userId}/${randomUUID()}.${extension}`;
    await this.storage.upload(path, cover.bytes, cover.contentType);
    return path;
  }

  private coverUrl(path: string | null): string | null {
    return path ? this.storage.publicUrl(path) : null;
  }

  // 저장된 기본 조건을 그대로 보여 준다(범위는 저장할 때 검사했다). 기본 형식이 비어 있으면 아직 정하지 않은 것이다.
  private termsOf(store: Store): OfferTermsModel | null {
    if (!store.defaultFormat) return null;
    return termsModelOf(
      store.defaultFormat,
      {
        voucherName: store.defaultVoucherName,
        voucherValue: store.defaultVoucherValue,
        voucherPeople: store.defaultVoucherPeople,
        fixedCash: store.defaultFixedCash,
        viewRatePerThousand: store.defaultViewRatePerThousand,
        perViewCap: store.defaultPerViewCap,
      },
      store.defaultUsageRights,
    );
  }

  private toMyStore(store: StoreWithLinks): MyStoreModel {
    return {
      id: store.id,
      status: store.status,
      onboardingStep: store.onboardingStep,
      name: store.name,
      category: store.category,
      industry: store.industry,
      neighborhood: store.neighborhood,
      regionSido: store.regionSido,
      regionSigungu: store.regionSigungu,
      coverPhotoUrl: this.coverUrl(store.coverPhotoPath),
      signatureMenu: store.signatureMenu,
      hours: store.hours,
      seats: store.seats,
      bestShootingTime: store.bestShootingTime,
      intro: store.intro,
      defaultTerms: this.termsOf(store),
      sourceLinks: store.sourceLinks.map((link) => ({
        kind: link.kind,
        url: link.url,
        summary: link.summary,
      })),
    };
  }

  // 공개 조건(이름, 기본 조건)은 조회 쿼리와 공개 규칙이 보장한다. 어긋나면 데이터 문제라 500이다.
  private toSummary(store: Store): StoreSummaryModel {
    const defaultTerms = this.termsOf(store);
    if (!store.name || !defaultTerms) {
      throw new AppError('INTERNAL', '공개된 가게의 정보가 비어 있어요.');
    }
    return {
      id: store.id,
      name: store.name,
      category: store.category,
      industry: store.industry,
      neighborhood: store.neighborhood,
      regionSido: store.regionSido,
      regionSigungu: store.regionSigungu,
      coverPhotoUrl: this.coverUrl(store.coverPhotoPath),
      defaultTerms,
    };
  }
}
