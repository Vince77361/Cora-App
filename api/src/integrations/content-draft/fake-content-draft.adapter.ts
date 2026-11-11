import type { ContentDraftKind } from '@prisma/client';
import { ContentDraftPort, DraftContent } from './content-draft.port';

// 캔버스 A4(NStoreAI)의 문안 그대로다. 줄바꿈과 공백까지 캔버스와 같게 둔다.
const SAMPLES: Record<ContentDraftKind, DraftContent> = {
  CARD_NEWS: {
    bodyLabel: '본문',
    body: '성수동 골목 안, 12시간 끓인 국물 한 그릇.\n오후 3시 이후엔 줄 없이 들어올 수 있어요.\n#성수라멘 #돈코츠',
    scenes: [
      { label: '1', text: '12시간 끓인\n국물 한 그릇', usesPhoto: true },
      {
        label: '2',
        text: '대표 메뉴\n돈코츠 라멘\n11,000원',
        usesPhoto: false,
      },
      { label: '3', text: '줄 없는 시간\n오후 3시 – 5시', usesPhoto: false },
    ],
  },
  REELS_SCRIPT: {
    bodyLabel: '촬영 순서',
    body: '0–3초  김이 오르는 그릇 클로즈업\n3–8초  면을 들어 올리는 손\n8–15초  가게 간판과 위치 자막',
    scenes: [
      { label: '장면 1', text: '김이 오르는\n첫 숟가락', usesPhoto: true },
      { label: '장면 2', text: '면을 들어\n올리는 손', usesPhoto: false },
      { label: '장면 3', text: '골목 간판과\n위치 자막', usesPhoto: false },
    ],
  },
  BLOG: {
    bodyLabel: '도입부',
    body: '성수역에서 걸어서 5분, 골목 끝에 바 좌석 18석짜리 라멘집이 있어요. 국물은 매일 아침 12시간을 끓여요.',
    scenes: [
      { label: '제목', text: '성수 골목\n라멘집 한 곳', usesPhoto: true },
      { label: '소제목 1', text: '12시간\n끓인 국물', usesPhoto: false },
      { label: '소제목 2', text: '줄 없이\n먹는 시간', usesPhoto: false },
    ],
  },
};

// 실제 AI 초안(9번 계획) 전까지 쓰는 가짜 구현. 입력과 무관하게 견본 문안을 돌려준다.
// version이 홀수면 장면 2와 3의 순서를 바꿔, "다시 만들기"가 다른 결과를 주는 것처럼 보이게 한다.
export class FakeContentDraftAdapter extends ContentDraftPort {
  generate(
    _input: Parameters<ContentDraftPort['generate']>[0],
    kind: ContentDraftKind,
    version: number,
  ): Promise<DraftContent> {
    const sample = SAMPLES[kind];
    const [first, second, third] = sample.scenes.map((scene) => ({ ...scene }));
    const scenes =
      version % 2 === 0 ? [first, second, third] : [first, third, second];
    return Promise.resolve({
      bodyLabel: sample.bodyLabel,
      body: sample.body,
      scenes,
    });
  }
}
