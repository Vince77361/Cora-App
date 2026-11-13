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

- 휴대폰 번호: E1에서 `휴대폰 번호로 시작하기` → **`010-0000-XXXX` 대역의 번호만**(예: `010-0000-0004`) → 인증번호 `000000`. 다른 번호는 실제 사람의 번호로 개발 계정이 만들어지지 않도록 거절한다. 문자는 가지 않는다. 번호마다 고정된 개발용 계정이 생기고 다음부터는 같은 계정으로 들어간다.
- 역할별 개발 계정: `cd api && yarn seed:dev`를 한 번 실행한 뒤 E1에서 `010-0000-0001`(가게)·`010-0000-0002`(브랜드)·`010-0000-0003`(크리에이터) + `000000`으로 들어가면 가게·브랜드·크리에이터 홈에 바로 들어간다. 여러 번 실행해도 계정이 늘지 않는다. `NODE_ENV=development`이고 `SUPABASE_URL`이 `api/seed/dev-project.json`의 개발 프로젝트일 때만 실행되고, 그 밖에는 거부한다. 화면에 쓸 목업 데이터와 사진은 `api/seed/mock/`에 있다.
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

## 운영 명령

**운영자는 DB를 직접 고치지 않는다.** 돈과 협업 단계를 바로잡는 일은 아래 명령으로만 한다. 모든 명령은 협업 행을 잠근 트랜잭션 안에서 단계를 조건부로 바꾸고, 장부 줄과 감사 기록(`ops_audit_logs`: 누가, 언제, 왜)을 함께 남긴 뒤 그 협업의 장부를 검산한다. 검산이 어긋나면 전부 되돌아간다. 같은 명령을 다시 실행해도 장부 줄과 지급·환급 행은 하나뿐이다(중복 방지 키).

`show`를 뺀 모든 명령은 `--operator <이름> --reason <사유>`가 필수다. 서버를 한 번 빌드한 뒤 `api/`에서 실행한다(`yarn build`).

```bash
cd api && yarn build
yarn ops show --collaboration <협업 id>
yarn ops halt --collaboration <협업 id> --operator 김운영 --reason "신고 확인 중"
```

| 명령 | 하는 일 |
|---|---|
| `halt --collaboration <id>` | 돈을 보관 중인 단계를 `HALTED`로 멈추고(멈추기 전 단계를 저장) 등록된 정산·집계·제출 기한 작업을 취소한다. 조회 자료 확인이 끝나지 않은 계산(`UNCONFIRMED`·`DISPUTED`)이 있는 협업은 멈추지 않는다(갇히지 않게. 돈은 확인 전에는 나가지 않는다) |
| `resume --collaboration <id>` | `HALTED`를 멈추기 전 단계로 되돌린다(신고로 멈춘 협업 포함). `COUNTING`이면 일찍 정산하지 않고 남은 날을 이어서 센다(기록되지 않은 날의 조회수 작업을 원래 시각으로 다시 올리고, 정산은 원래 정산 시각에 — 이미 지났으면 바로 — 올린다. 바로 정산하려면 `resume-settlement` 또는 `force-payout`), `FUNDED`면 미제출 환급·기한 알림을 다시 올린다(기한이 지났으면 미제출 환급이 바로 돈다) |
| `resume-settlement --collaboration <id> --views <n>` | 조회수를 읽지 못해 멈춘 협업을 주어진 조회수로 정산한다 |
| `force-refund --collaboration <id>` | 보관 중인 전액과 수수료를 사장님에게 환급하고 `REFUNDED`로 끝낸다 |
| `force-payout --collaboration <id> --amount <n>` | 보관액 안에서 `n`원을 지급하고 남은 금액을 환급한 뒤 `SETTLED`로 끝낸다(보관액보다 크면 거절) |
| `retry-payout --payout <id>` | `FAILED`·지급일이 지난 `PENDING` 지급을 같은 중복 방지 키로 다시 보낸다 |
| `retry-refund --refund <id>` | `PENDING`·`FAILED` 환급을 같은 중복 방지 키로 다시 PG에 보낸다 |
| `refund-payment --payment <id>` | 협업에 반영되지 못한 승인 결제(끝난 뒤 늦게 승인됐거나 두 번째 결제)를 전액 환불한다. 장부에 결제 승인 묶음과 전액 환급 묶음을 남긴다 |
| `confirm-evidence --collaboration <id>` | 크리에이터가 낸 조회수 캡처로 만든 계산(캡처 출처의 `UNCONFIRMED` 정산)을 운영자가 확인 완료로 확정하고, 캡처 행에 확인 표시를 한다. 장부·지급·환급은 사장님 확인과 같은 길이다. 캡처 자료는 사장님의 "자료 확인했어요"나 48시간으로는 확정되지 않고 이 명령만 확정한다 |
| `resolve-dispute --collaboration <id> [--views <n>]` | 조회 자료에 이의가 걸려 멈춘 협업(`DISPUTED` 정산, `HALTED`)을 처리한다. `--views`가 있으면 그 조회수로 다시 계산해, 없으면 계산 그대로 확정하고 협업을 `SETTLED`로 끝낸다. 이의 행에 결과(`VIEWS_CORRECTED`·`UPHELD_AS_IS`)를 남긴다 |
| `show --collaboration <id>` | 단계, 장부 계정별 잔액, 결제·지급·환급 상태, 정산 상태·자료 출처·캡처·이의 사유를 보여 준다(읽기 전용, 감사 기록 없음, 계좌번호는 출력하지 않음) |

- 커밋된 뒤의 단계(작업 취소·등록, PG 호출)가 실패하면 "경고"로 알리고 종료 코드 1을 돌려준다. 돈의 상태는 이미 커밋됐으니 `show`로 확인하고 `retry-*` 명령으로 이어 간다.
- `yarn ops`는 작업을 올리기만 하고 실행하지 않는다(작업 큐의 작업자는 서버 프로세스에서만 돈다). 서버와 같은 환경변수 검증을 거치고, 운영에서 가짜 연동이 켜져 있으면 실행을 거부한다.
- 모든 협업의 장부를 한꺼번에 검산하려면 `yarn check:ledger`(읽기 전용)를 쓴다. 개발 DB(`NODE_ENV=development`, `seed/dev-project.json`의 프로젝트)나 테스트 실행기를 거친 테스트 스키마(`node scripts/with-test-db.js yarn check:ledger`)에서만 실행되고, 그 밖에는 거부한다.

