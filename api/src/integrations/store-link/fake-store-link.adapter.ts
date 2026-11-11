import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import type { SourceLinkKind } from '@prisma/client';
import {
  SourceLinkInput,
  StoreLinkAnalysisError,
  StoreLinkPort,
  StoreLinkResult,
} from './store-link.port';

const SUMMARIES: Record<SourceLinkKind, string> = {
  NAVER_MAP: '사진 12장, 메뉴 8개 찾음',
  CATCHTABLE: '영업시간 찾음',
  INSTAGRAM: '게시물 9개 찾음',
};

// 서버는 api/에서 실행하고 빌드 산출물(dist)은 구조가 달라 __dirname 기준 경로가 어긋나므로 cwd 기준으로 찾는다.
const COVER_PATH = join(process.cwd(), 'seed', 'store-sample-cover.jpg');

// 실제 링크 분석(9번 계획) 전까지 쓰는 가짜 구현. 어떤 링크가 와도 캔버스 A3의 견본 가게를 돌려준다.
export class FakeStoreLinkAdapter extends StoreLinkPort {
  private cover: Buffer | undefined;

  async analyze(links: SourceLinkInput[]): Promise<StoreLinkResult> {
    // 실패 경로를 손으로 확인할 수 있도록, 주소에 fail이 들어 있으면 분석 실패로 본다.
    if (links.some((link) => link.url.includes('fail'))) {
      throw new StoreLinkAnalysisError();
    }
    return {
      store: {
        name: '한그릇 라멘',
        category: '라멘집',
        neighborhood: '성수동',
        signatureMenu: '돈코츠 라멘 11,000원',
        hours: '11:30 – 21:00',
        seats: '18석, 바 좌석',
        bestShootingTime: '오후 3시 – 5시',
        intro:
          '진한 국물을 12시간 끓이는 작은 라멘집이에요. 김이 오르는 첫 숟가락 장면을 담아주세요.',
        industry: 'FOOD_CAFE',
        regionSido: '서울특별시',
        regionSigungu: '성동구',
      },
      coverPhoto: {
        bytes: await this.loadCover(),
        contentType: 'image/jpeg',
      },
      linkSummaries: links.map((link) => ({
        kind: link.kind,
        summary: SUMMARIES[link.kind],
      })),
    };
  }

  // 앱 시작 때가 아니라 처음 쓸 때 읽는다.
  private async loadCover(): Promise<Buffer> {
    this.cover ??= await readFile(COVER_PATH);
    return this.cover;
  }
}
