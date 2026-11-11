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
2. Authentication → 이메일 로그인의 "Confirm email"을 끈다(개발용 로그인에 메일 인증을 요구하지 않기 위해).
3. `api/.env.example`을 `api/.env`로 복사해 값을 채운다. `app/config/dev.example.json`을 `app/config/dev.json`으로 복사해 값을 채운다.
4. `docker compose up -d`
