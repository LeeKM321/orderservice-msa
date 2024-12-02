#!/bin/bash

# SSH private key를 환경 변수에서 읽어 파일로 저장
echo "$GIT_PRIVATE_KEY" > /root/.ssh/id_ecdsa
chmod 600 /root/.ssh/id_ecdsa

# GitHub의 호스트 키를 known_hosts에 추가
ssh-keyscan -H github.com >> /root/.ssh/known_hosts

# 로그 출력 (선택 사항, 디버깅 용도)
echo "SSH key and known_hosts configured successfully."