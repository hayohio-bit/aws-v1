#!/bin/bash
echo "Spring Boot stop..."

SPRING_JAR="v1-0.0.1-SNAPSHOT.jar"
SPRING_PID=$(pgrep -f "${SPRING_JAR}")

echo "PID: ${SPRING_PID}"

if [ -z "${SPRING_PID}" ]; then
  echo "Spring Boot not running."
else
  kill -9 "${SPRING_PID}"
  echo "Spring Boot stopped."
fi