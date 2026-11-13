# 목업 묶음

기획 artifact(Cora Match · 스와이프 UI, `https://claude.ai/artifact/VLvHYafMkwqziRViALPicw`)의 화면에 나오는 사람·가게·브랜드·콘텐츠의 이름, 핸들, 가격, 문구를 그대로 옮긴 데이터와 사진이에요. 지어낸 값은 없고, 화면에 보이는 것만 담았어요.

- `mock.json`: 종류별(`creators`, `stores`, `brands`, `contents`, `campaigns`, `offers`, `collaborations`, `bids`, `notifications`) 목록. 항목마다 `source`에 나온 화면 파일 이름이 있어요. `images`는 사진 7장의 원본 asset id와 어느 화면에서 쓰이는지를 적은 목록이에요.
- `images/`: 사진 파일. 이름은 `creator-<핸들>-<n>`, `brand-<이름>-<n>`, `store-<이름>-<n>`이에요. `unused-`로 시작하는 두 장은 받아 둔 artifact 화면 어디에서도 쓰이지 않은 사진이에요.
- `storeFlow`: 가게 흐름 개정 캔버스(가게 페이지, 지원자 추천, 제안함, 역제안, 7일 결과)에서 옮긴 값이에요. `sampleOnly`에 적힌 항목은 캔버스에 값이 없어 시드용으로 정한 예시예요.
- 개발 계정(`yarn seed:dev`)과 짝지은 인물은 `mock.json`의 `devAccounts`에 있어요.

## 쓰는 방법

`yarn seed:dev`가 이 묶음으로 개발 계정, 크리에이터 프로필, 0001의 가게와 지원·제안·정산이 끝난 협업, 서윤의 시리즈를 채워요(자세한 내용은 `../README.md`). 브랜드·릴스 같은 나머지 테이블은 각 기능 계획이 만들 때 시드를 이어 붙여요.

## 사진 저작권

기획 artifact에서 가져온 목업 사진이에요. 출시 전에 교체할지 확인해야 해요.

## artifact가 바뀌면

화면의 이름·문구·사진이 바뀌면 이 묶음도 다시 맞춰요. `mock.json`의 `meta.artifactVersion`에 기준으로 삼은 artifact 버전을 적어 두었어요.
