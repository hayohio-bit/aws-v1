SPRING_JAR="v1-0.0.1-SNAPSHOT.jar"
SPRING_PATH="/home/ubuntu/aws-v1/build/libs/${SPRING_JAR}"
LOG_FILE="/home/ubuntu/cron-restart/spring-restart.log"

SPRING_PID=$(pgrep -f "${SPRING_JAR}")

echo "PID: ${SPRING_PID}"
echo "JAR: ${SPRING_PATH}"

if [ -z "${SPRING_PID}" ]; then
  echo "Spring: stopped"
  echo "$(date) - restart Spring" >> "${LOG_FILE}"
  nohup java -jar "${SPRING_PATH}" 1> /home/ubuntu/log.out 2> /home/ubuntu/err.out &
else
  echo "Spring: running (PID=${SPRING_PID})"
fi