#!/bin/bash
set -e  # Exit on error, standard for deploy scripts
# 1. 배포 프로세스
echo " Deployment starting... "
echo " 1. JDK install "
echo " 2. GitHub project download "
echo " 3. gradlew 실행 권한 부여 "
echo " 4. Project build "
echo " 5. Ubuntu 타임존 설정 "
echo " 6. nohup으로 Spring Boot 실행 "

# 2. 스프링 서버 종료 시 재시작
echo " crontab 등록 - Spring restart... "
CRON_TMP="crontab_new"
JOB_LINE="* * * * * /home/ubuntu/cron-restart/spring-restart.sh"

# 기존 crontab 백업 + 중복 체크 + 새 job 추가
(crontab -l 2>/dev/null || true; echo "$JOB_LINE") | crontab -
rm -f "$CRON_TMP"

echo "배포 완료!"
