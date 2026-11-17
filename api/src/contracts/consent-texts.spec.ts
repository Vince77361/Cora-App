import { consentTexts } from './consent-texts';

describe('consentTexts', () => {
  it('builds three consent lines that follow the role and usage rights', () => {
    expect(consentTexts('CREATOR', 1, 'REPOST_ONLY')).toEqual([
      '합의한 조건 버전 1을 확인했어요',
      '광고 표시 의무를 지킬게요',
      '콘텐츠는 브랜드 계정 재게시에만 쓰여요',
    ]);
    expect(consentTexts('BRAND', 3, 'ADS_TOO')).toEqual([
      '합의한 조건 버전 3을 확인했어요',
      '광고 표시를 요청할게요',
      '콘텐츠는 브랜드 계정 재게시와 광고 소재로 쓰여요',
    ]);
    expect(consentTexts('CREATOR', 5, 'NONE')[2]).toBe(
      '콘텐츠는 브랜드가 따로 활용하지 않아요',
    );
  });

  it('puts the right particle after the version number', () => {
    expect(consentTexts('CREATOR', 2, 'NONE')[0]).toBe(
      '합의한 조건 버전 2를 확인했어요',
    );
    expect(consentTexts('CREATOR', 10, 'NONE')[0]).toBe(
      '합의한 조건 버전 10을 확인했어요',
    );
  });
});
