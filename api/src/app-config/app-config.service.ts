import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { REWARD_POLICY } from '../common/collaboration-policy';
import { AppConfigModel } from './dto/app-config.model';

// 앱이 입력 범위와 수수료율을 읽어 가는 값. 범위는 collaboration-policy.ts 한 곳, 수수료율은 환경 값에서 온다.
@Injectable()
export class AppConfigService {
  constructor(private readonly config: ConfigService) {}

  get(): AppConfigModel {
    const { fixedCash, voucher } = REWARD_POLICY;
    return {
      reward: {
        viewRate: { ...REWARD_POLICY.viewRate },
        perViewCap: { ...REWARD_POLICY.perViewCap },
        fixedCash: {
          maxByCommissioner: {
            store: fixedCash.maxByCommissioner.STORE,
            brand: fixedCash.maxByCommissioner.BRAND,
          },
          step: fixedCash.step,
          presets: [...fixedCash.presets],
        },
        voucher: {
          defaultName: voucher.defaultName,
          defaultValue: voucher.defaultValue,
          defaultPeople: voucher.defaultPeople,
          maxPeople: voucher.maxPeople,
        },
        usageRightsDefault: REWARD_POLICY.usageRightsDefault,
        countingDays: REWARD_POLICY.countingDays,
      },
      feeRates: {
        storeOffer: this.feeRate('FEE_RATE_STORE_OFFER'),
        bid: this.feeRate('FEE_RATE_BID'),
        brandContract: this.feeRate('FEE_RATE_BRAND_CONTRACT'),
      },
    };
  }

  // 환경 검증(loadEnv)이 이미 0~100 정수를 보장한다. 그래도 값이 어긋났다면 앱에 거짓 수수료를 보여 주지 않고 던진다.
  private feeRate(
    key: 'FEE_RATE_STORE_OFFER' | 'FEE_RATE_BID' | 'FEE_RATE_BRAND_CONTRACT',
  ): number {
    const rate = Number(this.config.getOrThrow(key));
    if (!Number.isInteger(rate) || rate < 0 || rate > 100) {
      throw new Error(`수수료율이 올바르지 않아요: ${key}=${rate}`);
    }
    return rate;
  }
}
