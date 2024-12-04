// 필요한 변수를 선언할 수 있다. (내가 직접 선언하는 변수, 젠킨스 환경변수를 끌고 올 수 있음)
def ecrLoginHelper="docker-credential-ecr-login" // ECR credential helper 이름
def deployHost = "172.31.19.164"

// 젠킨스의 선언형 파이프라인 정의부 시작 (그루비 언어)
pipeline {
    agent any // 어느 젠킨스 서버에서도 실행이 가능
    environment {
        REGION = "ap-northeast-2"
        ECR_URL = "872651651829.dkr.ecr.ap-northeast-2.amazonaws.com"
        SERVICE_DIRS = "config-service,discoveryservice,gateway-service,user-service,ordering-service,product-service"
    }
    stages {
        stage('Pull Codes from Github'){ // 스테이지 제목 (맘대로 써도 됨.)
            steps{
                checkout scm // 젠킨스와 연결된 소스 컨트롤 매니저(git 등)에서 코드를 가져오는 명령어
            }
        }
        stage('Build Codes by Gradle') {
            steps {
                script {
                    def serviceDirs = env.SERVICE_DIRS.split(",")
                    serviceDirs.each { service ->
                        sh """
                        echo "Building ${service}..."
                        cd ${service}
                        ./gradlew clean build -x test
                        ls -al ./build/libs
                        cd ..
                        """
                    }
                }
            }
        }

        stage('Build Docker Image & Push to AWS ECR') {
            steps {
                script {
                    withAWS(region: "${REGION}", credentials: "aws-key") {
                        def serviceDirs = env.SERVICE_DIRS.split(",")
                        serviceDirs.each { service ->
                            sh """
                            curl -O https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/0.4.0/linux-amd64/${ecrLoginHelper}
                            chmod +x ${ecrLoginHelper}
                            mv ${ecrLoginHelper} /usr/local/bin/
                            echo '{"credHelpers": {"${ECR_URL}": "ecr-login"}}' > ~/.docker/config.json
                            # Docker 이미지 빌드 (서비스 이름으로)
                            docker build -t ${service}:latest ${service}
                            # ECR 레포지토리로 태깅
                            docker tag ${service}:latest ${ECR_URL}/${service}:latest
                            # ECR로 푸시
                            docker push ${ECR_URL}/${service}:latest
                            """
                        }
                    }
                }
            }
        }
        stage('Deploy to AWS EC2 VM') {
            steps {
                sshagent(credentials: ["jenkins-ssh-key"]) {
                    //
                    sh """
                    # Jenkins에서 배포 서버로 docker-compose.yml 복사
                    scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@${deployHost}:/home/ubuntu/docker-compose.yml
                    ssh -o StrictHostKeyChecking=no ubuntu@${deployHost} '
                    # Docker compose 파일이 있는 경로로 이동
                    cd /home/ubuntu && \
                    # 기존 컨테이너 중지 및 제거
                    docker-compose down && \
                    aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_URL} && \
                    # Docker Compose로 컨테이너 재배포
                    docker-compose pull && \
                    docker-compose up -d
                    '
                    """
                }
            }
        }
    }
}