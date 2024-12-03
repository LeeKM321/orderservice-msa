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
        SKIP_PIPELINE = false // 파이프라인 전체 실행 여부를 제어하는 플래그
    }
    stages {
        stage('Pull Codes from Github'){ // 스테이지 제목 (맘대로 써도 됨.)
            steps{
                checkout scm // 젠킨스와 연결된 소스 컨트롤 매니저(git 등)에서 코드를 가져오는 명령어
            }
        }
        stage('Detect Changes') {
            steps {
                script {
                    // 변경된 파일 감지
                    def changedFiles = sh(script: "git diff --name-only origin/main HEAD", returnStdout: true)
                        .trim()
                        .split('\n')
                    def changedServices = []
                    def serviceDirs = env.SERVICE_DIRS.split(",")

                    serviceDirs.each { service ->
                        if (changedFiles.any { it.startsWith(service + "/") }) {
                            changedServices.add(service)
                        }
                    }

                    env.CHANGED_SERVICES = changedServices.join(",")
                    if (env.CHANGED_SERVICES == "") {
                        echo "No changes detected in service directories. Skipping build and deployment."
                        // 성공 상태로 파이프라인 종료
                    env.SKIP_PIPELINE = true // 플래그를 설정하여 이후 스테이지를 건너뛰도록 설정
                    }
                }
            }
        }
        stage('Build Changed Services') {
            when {
                expression { !env.SKIP_PIPELINE.toBoolean() } // 플래그가 false일 때만 실행
            }

            steps {
                script {
                    def changedServices = env.CHANGED_SERVICES.split(",")
                    changedServices.each { service ->
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
            when {
                expression { !env.SKIP_PIPELINE.toBoolean() } // 플래그가 false일 때만 실행
            }

            steps {
                script {
                    withAWS(region: "${REGION}", credentials: "aws-key") {
                        def changedServices = env.CHANGED_SERVICES.split(",")
                        changedServices.each { service ->
                            sh """
                            curl -O https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/0.4.0/linux-amd64/${ecrLoginHelper}
                            chmod +x ${ecrLoginHelper}
                            mv ${ecrLoginHelper} /usr/local/bin/

                            echo '{"credHelpers": {"${ECR_URL}": "ecr-login"}}' > ~/.docker/config.json

                            docker build -t ${service}:latest ${service}
                            docker tag ${service}:latest ${ECR_URL}/${service}:latest
                            docker push ${ECR_URL}/${service}:latest
                            """
                        }
                    }
                }
            }
        }

        stage('Deploy Changed Services to AWS EC2 VM') {
            when {
                expression { !env.SKIP_PIPELINE.toBoolean() } // 플래그가 false일 때만 실행
            }

            steps {
                sshagent(credentials: ["jenkins-ssh-key"]) {
                    sh """
                    # Jenkins에서 배포 서버로 docker-compose.yml 복사
                    scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@${deployHost}:/home/ubuntu/docker-compose.yml

                    ssh -o StrictHostKeyChecking=no ubuntu@${deployHost} '
                    cd /home/ubuntu && \

                    # 기존 컨테이너 중지 및 변경된 컨테이너만 업데이트
                    aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_URL} && \

                    docker-compose pull ${env.CHANGED_SERVICES} && \
                    docker-compose up -d ${env.CHANGED_SERVICES}
                    '
                    """
                }
            }
        }
    }
}