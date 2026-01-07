#!/bin/bash
set -e

CRON_TMP="/home/ubuntu/crontab_new"
JOB_LINE="* * * * * /home/ubuntu/job.sh"

# 기존 crontab을 임시 파일로 백업 (없어도 에러 무시)
crontab -l 2>/dev/null > "${CRON_TMP}" || true

# 같은 job이 이미 있으면 추가하지 않음
grep -F "${JOB_LINE}" "${CRON_TMP}" >/dev/null 2>&1 || echo "${JOB_LINE}" >> "${CRON_TMP}"

# 새로운 crontab 적용
crontab "${CRON_TMP}"

# 임시 파일 삭제
rm -f "${CRON_TMP}"

echo "crontab updated: ${JOB_LINE}"