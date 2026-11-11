# 개발 시드

`yarn seed:dev`가 쓰는 파일들이에요. 개발 전용이라 서버 빌드(`yarn build`)에는 들어가지 않아요.

- `lib/`: 시드 로직과 그 단위 테스트.
- `mock/`: 화면용 목업 묶음(자세한 설명은 `mock/README.md`).
- `dev-project.json`: 개발용 Supabase 프로젝트의 ref. `seed:dev`는 `NODE_ENV=development`이고 `SUPABASE_URL`의 프로젝트 ref가 이 값과 같을 때만 실행돼요. 프로젝트 ref는 `https://<ref>.supabase.co` 주소에 드러나는 공개 값이라 비밀이 아니에요. 개발 프로젝트를 새로 만들면 이 파일의 값을 바꿔 주세요.
