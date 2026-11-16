import { BrandsService } from '../../src/brands/brands.service';
import { BrandProfileModel } from '../../src/brands/dto/brand-profile.model';

// DB 없이 브랜드 프로필을 흉내 낸다. 넣어 둔 프로필만 읽힌다.
export class FakeBrandsService extends BrandsService {
  profiles = new Map<string, BrandProfileModel>();

  constructor() {
    super(null as never, null as never, null as never, null as never);
  }

  findProfiles(userIds: string[]): Promise<Map<string, BrandProfileModel>> {
    return Promise.resolve(
      new Map(
        userIds.flatMap((id) => {
          const profile = this.profiles.get(id);
          return profile ? [[id, profile] as const] : [];
        }),
      ),
    );
  }

  getActor(userId: string): Promise<{
    userId: string;
    name: string;
    photoPath: string | null;
  } | null> {
    const profile = this.profiles.get(userId);
    return Promise.resolve(
      profile ? { userId, name: profile.name, photoPath: null } : null,
    );
  }
}
