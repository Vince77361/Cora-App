#!/usr/bin/env bash
# API 문서(api/openapi.json)에서 Dart 클라이언트(app/packages/cora_api)를 다시 만든다.
# Docker 대신 버전을 고정한 openapi-generator jar를 로컬 Java로 돌린다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="7.26.0"
JAR_DIR="$ROOT/.tools"
JAR="$JAR_DIR/openapi-generator-cli-$VERSION.jar"
URL="https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/$VERSION/openapi-generator-cli-$VERSION.jar"
# Maven Central이 같은 경로에 게시한 .sha1 값. 내려받은 jar가 바뀌었는지 검증한다.
EXPECTED_SHA1="b96b148fcf482808037f68fbad99cb4d7e65d40b"
OUT="$ROOT/app/packages/cora_api"

# 패키지를 지우기 전에 필요한 도구부터 확인한다. 없으면 기존 생성물을 건드리지 않고 멈춘다.
for tool in java yarn dart curl shasum; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "$tool 명령을 찾을 수 없어요. 설치한 뒤 다시 실행하세요. (기존 app/packages/cora_api는 그대로예요)" >&2
    exit 1
  fi
done

sha1_of() { shasum -a 1 "$1" | cut -d' ' -f1; }

# jar가 없을 때만 내려받는다. 체크섬이 다르면 지우고 멈춘다.
if [ ! -f "$JAR" ]; then
  mkdir -p "$JAR_DIR"
  curl -fsSL "$URL" -o "$JAR.part"
  if [ "$(sha1_of "$JAR.part")" != "$EXPECTED_SHA1" ]; then
    rm -f "$JAR.part"
    echo "openapi-generator jar의 체크섬이 달라요. 내려받은 파일을 지웠어요." >&2
    exit 1
  fi
  mv "$JAR.part" "$JAR"
fi
if [ "$(sha1_of "$JAR")" != "$EXPECTED_SHA1" ]; then
  echo "$JAR의 체크섬이 달라요. 파일을 지우고 다시 실행하세요." >&2
  exit 1
fi

yarn --cwd "$ROOT/api" openapi:export

# 지워진 API의 파일이 남지 않도록 매번 처음부터 만든다. 다만 생성이 끝난 뒤에만 기존
# 패키지를 바꿔치기해서, 중간에 실패해도 작동하던 생성물이 사라지지 않게 한다.
# .openapi-generator-ignore는 생성기가 읽으므로 scripts/의 원본을 먼저 넣어 둔다.
IGNORE_FILE="$ROOT/scripts/openapi-generator-ignore"
TMP="$(mktemp -d "$JAR_DIR/gen.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/cora_api"
cp "$IGNORE_FILE" "$TMP/cora_api/.openapi-generator-ignore"

java -jar "$JAR" generate \
  -g dart \
  -i "$ROOT/api/openapi.json" \
  -o "$TMP/cora_api" \
  --additional-properties=pubName=cora_api,pubLibrary=cora_api,hideGenerationTimestamp=true,pubAuthor=Cora \
  >/dev/null

# 생성기가 만든 코드 모양을 dart format으로 고정한다. 결과는 항상 같다(손으로 고치는 것이 아니다).
dart format "$TMP/cora_api" >/dev/null

rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
mv "$TMP/cora_api" "$OUT"
(cd "$OUT" && dart pub get >/dev/null)
