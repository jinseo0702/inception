#!/bin/sh

install_and_verify() {
  local pkg=$1
  local check_cmd=$2
  local next_step=$3
  
  echo "Installing $pkg..."
  apk add $pkg
  
  echo "Verifying $pkg installation..."
  until eval "$check_cmd"; do
    echo "Waiting for $pkg to be ready..."
    sleep 1
  done
  
  echo "$pkg is ready, proceeding with configuration"
  eval "$next_step"
}

# 인자로 전달된 패키지와 검증 명령, 다음 단계를 실행
if [ $# -ge 3 ]; then
  install_and_verify "$1" "$2" "$3"
else
  echo "사용법: $0 '패키지명' '검증명령어' '다음단계명령어'"
  exit 1
fi

echo "패키지 설치 및 설정이 완료되었습니다!"
