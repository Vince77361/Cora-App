#!/usr/bin/env bash
# 운영 빌드 바이너리에 개발용 가짜 구현이 남아 있지 않은지 확인한다.
# 쓰는 법: scripts/check-release-binary.sh <바이너리 경로>
#   예) app/build/ios/iphoneos/Runner.app/Frameworks/App.framework/App
# 난독화하지 않은 운영 빌드에만 쓴다(난독화하면 클래스 이름이 바뀌어 검사가 의미 없다).
# 하나라도 찾으면 종료 코드 1, 인자 오류나 strings 실행 실패는 종료 코드 2.
set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  echo "사용법: $0 <바이너리 경로>" >&2
  exit 2
fi

binary="$1"
# 이름은 가짜 구현의 클래스·화면 이름과 개발 전용 문자열이다.
needles=(FakeSignInAdapter FakeCheckoutPage FakeInstagramConnectPage MotionGalleryPage cora-dev-only 'cora-dev://')

# strings 결과를 한 번만 만든다(바이너리가 커서 needle마다 돌리면 느리다).
dump="$(mktemp)"
trap 'rm -f "$dump"' EXIT
# strings가 실패한 것(종료 코드 2)을 "찾음"(종료 코드 1)과 구분한다.
strings -a "$binary" > "$dump" || { echo "strings 실행 실패" >&2; exit 2; }

found=0
for needle in "${needles[@]}"; do
  if grep -qF -- "$needle" "$dump"; then
    echo "발견: $needle" >&2
    found=1
  fi
done

if [ "$found" -ne 0 ]; then
  echo "운영 바이너리에 개발용 구현이 남아 있습니다: $binary" >&2
  exit 1
fi
echo "찾은 것 없음: $binary"
