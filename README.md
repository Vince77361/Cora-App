# Cora

가게 사장님·브랜드와 크리에이터를 잇는 모바일 앱. Flutter 앱과 NestJS 서버를 이 레포 하나에서 만든다.

## 폴더 구조

- `app/` Flutter 앱
- `api/` NestJS 서버
- `docs/superpowers/specs/` 설계 문서. 시작은 `2026-11-11-tech-stack-design.md`
- `docs/superpowers/plans/` 실행 계획
- `docker-compose.yml` 로컬 Redis
- `CLAUDE.md` 작업 규칙

## 개발 환경 준비

이 프로젝트는 로컬에 Supabase를 띄우지 않는다. 원격의 개발용 Supabase 프로젝트를 쓰고, 로컬 Docker로 띄우는 것은 Redis뿐이다.
자동 테스트는 같은 DB의 `cora_test` 스키마에서 돌고, 앱 데이터는 `public` 스키마에 있다.

1. Supabase 대시보드에서 개발용 프로젝트를 만든다(지역: 서울).
2. Authentication → 이메일 로그인의 "Confirm email"을 끈다(개발 중 가짜 인증이 개발용 계정을 이메일로 만들어 로그인시키는데, 메일 인증을 요구하지 않게 하기 위해).
3. `api/.env.example`을 `api/.env`로 복사해 값을 채운다. `app/config/dev.example.json`을 `app/config/dev.json`으로 복사해 값을 채운다.
4. `docker compose up -d`

## 개발용 로그인

앱의 로그인 화면(E1)과 휴대폰 인증 화면(E2)은 정식 화면 그대로고, 개발 중에는 뒤에서 가짜 인증(`AUTH_ADAPTER=fake`, 개발 환경에서는 비워 두어도 기본값)이 개발용 계정으로 로그인시킨다.

- 휴대폰 번호: E1에서 `휴대폰 번호로 시작하기` → 아무 `010` 번호 11자리 → 인증번호 `000000`. 문자는 가지 않는다. 번호마다 고정된 개발용 계정이 생기고 다음부터는 같은 계정으로 들어간다.
- 카카오·네이버: E1의 버튼을 누르면 각각 고정된 개발용 계정(`kakao`, `naver`)으로 로그인한다.
- 개발용 계정은 `<이름>@example.com` 이메일에 코드에 적힌 개발 전용 비밀번호로 만들어진다(`app/lib/features/auth/data/fake_sign_in_adapter.dart`). **개발용 Supabase 프로젝트에서만 쓴다.** 비밀번호가 비밀이 아니므로 운영에서는 `AUTH_ADAPTER=fake`면 앱이 시작을 거부한다.
- 모션 갤러리는 개발 빌드에서 E1의 로고를 길게 누르면 열린다.
- 실제 로그인(Supabase 휴대폰 OTP·카카오·네이버)은 9번 계획이다.

## DB 규칙

테이블을 추가하는 마이그레이션에는 `ENABLE ROW LEVEL SECURITY`를 반드시 넣는다. 빠뜨리면 `yarn test:db`가 실패한다.

`yarn test:db`와 `yarn test:e2e`는 원격 개발 DB의 `cora_test` 스키마에서 돌기 때문에 인터넷 연결이 필요하다. 개발 DB(`public`)의 RLS 상태는 `yarn check:rls`로 확인한다.

## 인증

API는 `Authorization: Bearer <토큰>`의 Supabase 액세스 토큰을 검증한다. 검증은 프로젝트의 JWKS(`<SUPABASE_URL>/auth/v1/.well-known/jwks.json`, ES256 공개키)로 하므로 서버에 JWT 비밀값이 필요 없다(`SUPABASE_JWT_SECRET`은 쓰지 않는다).

실제 토큰으로 직접 확인하는 방법(`yarn start:dev`로 서버를 띄운 뒤):

1. 개발용 프로젝트에 가입한다: `POST <SUPABASE_URL>/auth/v1/signup`, 헤더 `apikey: <공개 키>`, JSON 본문 `{"email": "...", "password": "..."}`.
2. 응답의 `access_token`을 꺼낸다.
3. `curl -H "Authorization: Bearer <token>" http://127.0.0.1:3000/me`
4. 기대 결과: `{"id":"<uuid>","role":null}`

## API 클라이언트

API를 바꾸면 `./scripts/gen-api.sh`를 실행하고 생성물을 같은 커밋에 넣는다. `app/packages/cora_api`는 손으로 고치지 않는다.

생성기는 버전을 고정한 openapi-generator jar를 로컬 Java로 돌린다(Docker는 쓰지 않는다). jar는 처음 실행할 때 `.tools/`에 내려받고 체크섬을 검증한다.
