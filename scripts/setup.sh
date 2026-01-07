#!/bin/bash
set -e

HOME_DIR="/home/ubuntu"
APP_DIR="${HOME_DIR}/aws-v1"
SCRIPTS_DIR="${APP_DIR}/scripts"
CRON_RESTART_DIR="${HOME_DIR}/cron-restart"

# 1. 타임존 설정
bash "${SCRIPTS_DIR}/timezone.sh"

# 2. cron-restart 디렉토리 및 스크립트 복사
mkdir -p "${CRON_RESTART_DIR}"
cp "${SCRIPTS_DIR}/spring-stop.sh" "${CRON_RESTART_DIR}/"
cp "${SCRIPTS_DIR}/spring-restart.sh" "${CRON_RESTART_DIR}/"
chmod +x "${CRON_RESTART_DIR}/"spring-*.sh

# 3. job.sh / myScript.sh 등 권한 및 실행
cp "${SCRIPTS_DIR}/myScript.sh" "${HOME_DIR}/"
cp "${SCRIPTS_DIR}/job.sh" "${HOME_DIR}/"
chmod +x "${HOME_DIR}/"myScript.sh "${HOME_DIR}/"job.sh
bash "${HOME_DIR}/myScript.sh"

# 4. 패키지 설치 (JDK, net-tools)
sudo apt update -y
sudo apt install -y openjdk-21-jdk net-tools git

# 5. 프로젝트 빌드
cd "${APP_DIR}"
chmod u+x gradlew
./gradlew clean build

# 6. Spring Boot 실행
cd build/libs
SPRING_JAR="v1-0.0.1-SNAPSHOT.jar"
nohup java -jar "${SPRING_JAR}" 1>${HOME_DIR}/log.out 2>${HOME_DIR}/err.out &
echo "Spring Boot started."