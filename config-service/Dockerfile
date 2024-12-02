# Base 이미지
FROM openjdk:17-jdk-slim

# SSH 키 설정을 위한 디렉토리 생성
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# 환경 변수에서 SSH 키를 읽어 파일로 저장하는 스크립트 추가
COPY setup-ssh.sh /usr/local/bin/setup-ssh.sh
RUN chmod +x /usr/local/bin/setup-ssh.sh

COPY build/libs/*.jar /app.jar

# 애플리케이션 실행 명령
ENTRYPOINT ["sh", "-c", "/usr/local/bin/setup-ssh.sh && java -jar /app.jar"]