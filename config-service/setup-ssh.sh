#!/bin/bash

# .env 파일에서 PRIVATE KEY를 읽어옵니다.
PRIVATE_KEY=${GIT_PRIVATE_KEY}

# 줄바꿈(\n)을 개행 문자로 변경
FORMATTED_KEY=$(echo -e "$PRIVATE_KEY")

# SSH 키 파일 생성
mkdir -p /root/.ssh
cat <<EOF > /root/.ssh/id_ecdsa
$FORMATTED_KEY
EOF
chmod 600 /root/.ssh/id_ecdsa

# GitHub의 호스트 키를 known_hosts에 추가
ssh-keyscan -H github.com >> /root/.ssh/known_hosts

# 로그 출력 (선택 사항, 디버깅 용도)
echo "SSH key and known_hosts configured successfully."