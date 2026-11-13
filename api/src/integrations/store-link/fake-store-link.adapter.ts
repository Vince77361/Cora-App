import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import type { SourceLinkKind } from '@prisma/client';
import {
  SourceLinkInput,
  StoreBranch,
  StoreLinkAnalysisError,
  StoreLinkPort,
  StoreLinkResult,
} from './store-link.port';

const SUMMARIES: Record<SourceLinkKind, string> = {
  NAVER_MAP: '메뉴 12개, 사진 34장, 후기 58개 찾음',
  CATCHTABLE: '영업시간 찾음',
  INSTAGRAM: '게시물 9개 찾음',
  // 캔버스에 없는 문구다(소유자 확인 목록).
  REVIEW_POST: '후기 글 찾음',
};

// 캔버스 F7의 "같은 이름의 가게가 2곳 있어요" 견본.
const SAMPLE_BRANCHES: Record<string, StoreBranch[]> = {
  '한그릇 라멘': [
    {
      label: '성수점',
      address: '서울 성동구 성수이로 100',
      neighborhood: '성수동2가',
      regionSido: '서울특별시',
      regionSigungu: '성동구',
    },
    {
      label: '합정점',
      address: '서울 마포구 양화로 45',
      neighborhood: '합정동',
      regionSido: '서울특별시',
      regionSigungu: '마포구',
    },
  ],
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
        reviewCount: 58,
        tags: ['진한국물', '바좌석', '조용한오후'],
        customerPhrases: ['국물이 진해요', '혼밥하기 좋아요'],
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

  findBranches(name: string): Promise<StoreBranch[]> {
    return Promise.resolve(SAMPLE_BRANCHES[name.trim()] ?? []);
  }

  // 앱 시작 때가 아니라 처음 쓸 때 읽는다.
  private async loadCover(): Promise<Buffer> {
    this.cover ??= await readFile(COVER_PATH);
    return this.cover;
  }
}
