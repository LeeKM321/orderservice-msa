# Base 이미지
FROM openjdk:17-jdk-slim

# SSH 키 설정을 위한 디렉토리 생성
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# curl 설치
# docker-compose에서 health-check를 하는데, 그 때 curl을 이용해서 요청을 보내야 하기 때문.
# rm -rf /var/lib/apt/lists/* -> apt가 가진 캐시를 삭제해서 이미지 크기를 줄이기 (선택사항)
RUN apt-get update && apt-get install -y openssh-client && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# 환경 변수에서 SSH 키를 읽어 파일로 저장하는 스크립트 추가
COPY setup-ssh.sh /usr/local/bin/setup-ssh.sh
RUN chmod +x /usr/local/bin/setup-ssh.sh

COPY build/libs/*.jar /app.jar

# 애플리케이션 실행 명령
ENTRYPOINT ["sh", "-c", "/usr/local/bin/setup-ssh.sh && java -jar /app.jar"]