# ☁️ AWS 초급 강의 - 첫번째 배포

> Spring Boot 애플리케이션을 AWS EC2에 수동 배포하고,
> 이후 개선 포인트(Docker, CI/CD, Auto Scaling 등)를 단계적으로 고민해보는 학습 프로젝트입니다.

---

## 📑 목차

1. [프로젝트 개요](#1--프로젝트-개요)
2. [기술 스택](#2--기술-스택)
3. [프로젝트 구조](#3--프로젝트-구조)
4. [배포 환경](#4--배포-환경)
5. [배포 절차](#5--배포-절차)
   - 5.1 [로컬에서 GitHub 업로드](#51-로컬에서-github-업로드)
   - 5.2 [EC2에서 GitHub 다운로드](#52-ec2에서-github-다운로드)
   - 5.3 [프로젝트 테스트](#53-프로젝트-테스트)
   - 5.4 [프로젝트 빌드](#54-프로젝트-빌드)
   - 5.5 [nohup으로 백그라운드 실행](#55-nohup으로-백그라운드-실행)
   - 5.6 [오류 로그 남기기 (표준 입출력 리다이렉션)](#56-오류-로그-남기기-표준-입출력-리다이렉션)
   - 5.7 [cron으로 자동 재시작 설정](#57-cron으로-자동-재시작-설정)
6. [향후 고민과 개선 방향](#6--향후-고민과-개선-방향)
   - 6.1 [고민 1: 로컬과 EC2 환경 일치 (Docker)](#고민-1--로컬과-ec2-환경-일치--docker)
   - 6.2 [고민 2: 테스트 전용 서버 (Staging)](#고민-2--테스트-전용-서버--staging)
   - 6.3 [고민 3: 트래픽 폭증 대응 (Auto Scaling)](#고민-3--트래픽-폭증-대응--auto-scaling--elastic-beanstalk)
   - 6.4 [고민 4: 자동 배포 (CI/CD)](#고민-4--자동-배포-cicd)
7. [참고 명령어 모음](#7--참고-명령어-모음)

---

## 1. 📌 프로젝트 개요

AWS EC2 인스턴스에 Spring Boot 애플리케이션을 **수동 배포**하는 전 과정을 학습합니다.
배포 이후 발생할 수 있는 문제점들을 하나씩 고민하며, Docker, Staging 서버, Auto Scaling, CI/CD 등
점진적으로 인프라를 개선해 나가는 로드맵을 함께 정리합니다.

---

## 2. 🛠 기술 스택

| 구분 | 기술 | 버전 |
|------|------|------|
| Language | Java (JDK) | 21 |
| Framework | Spring Boot | 3.4.4 |
| Build Tool | Gradle | Wrapper 사용 |
| Cloud | AWS EC2 | Amazon Linux 2023 / Ubuntu |

### Spring Boot Dependencies

| 의존성 | 설명 |
|--------|------|
| **Spring Web** | REST API 및 웹 애플리케이션 구축을 위한 핵심 모듈 (내장 Tomcat 포함) |
| **Spring Boot DevTools** | 개발 시 자동 재시작(Hot Reload), LiveReload 등 개발 편의 기능 제공 |
| **Lombok** | `@Getter`, `@Setter`, `@Builder` 등 어노테이션으로 보일러플레이트 코드 제거 |

> ⚠️ **DevTools**는 개발 편의용이므로 배포(production) 시에는 자동으로 비활성화됩니다.

---

## 3. 📂 프로젝트 구조

```
aws-v1/
├── src/
│   ├── main/
│   │   ├── java/com/example/awsv1/
│   │   │   └── AwsV1Application.java
│   │   └── resources/
│   │       └── application.yml
│   └── test/
├── build.gradle
├── settings.gradle
├── gradlew
├── gradlew.bat
└── README.md        ← 현재 파일
```

---

## 4. 🌍 배포 환경

- **배포 위치**: AWS EC2 인스턴스
- **접속 방식**: SSH (`.pem` 키 파일 사용)
- **필수 설치 항목 (EC2)**:
  - JDK 21
  - Git

```bash
# Amazon Linux 2023 기준 JDK 21 설치
sudo yum install java-21-amazon-corretto -y

# Ubuntu 기준 JDK 21 설치
sudo apt update
sudo apt install openjdk-21-jdk -y

# Git 설치 (보통 기본 설치되어 있음)
sudo yum install git -y   # Amazon Linux
sudo apt install git -y   # Ubuntu

# 설치 확인
java -version
git --version
```

- **보안 그룹(Security Group) 설정**:
  - SSH: 포트 `22` (내 IP만 허용 권장)
  - HTTP: 포트 `80` 또는 Spring Boot 기본 포트 `8080` 개방

---

## 5. 🚀 배포 절차

전체 흐름을 다이어그램으로 요약하면 다음과 같습니다.

```
[로컬 개발] → git push → [GitHub] → git pull → [EC2] → build → run
```

### 5.1 로컬에서 GitHub 업로드

```bash
# 프로젝트 디렉토리에서
git init
git remote add origin https://github.com/<username>/aws-v1.git

git add .
git commit -m "Initial commit: Spring Boot 프로젝트 생성"
git push -u origin main
```

> 💡 `.gitignore`에 `/build`, `/.gradle`, `/.idea` 등이 포함되어 있는지 반드시 확인하세요.

### 5.2 EC2에서 GitHub 다운로드

```bash
# EC2 SSH 접속
ssh -i "your-key.pem" ec2-user@<EC2-퍼블릭-IP>

# 프로젝트 클론 (최초 1회)
git clone https://github.com/<username>/aws-v1.git
cd aws-v1

# 이후 업데이트 시
git pull origin main
```

### 5.3 프로젝트 테스트

```bash
# Gradle Wrapper에 실행 권한 부여
chmod +x gradlew

# 테스트 실행
./gradlew test
```

- 테스트 결과는 `build/reports/tests/test/index.html`에서 확인 가능합니다.
- 테스트 실패 시 빌드를 진행하지 마세요.

### 5.4 프로젝트 빌드

```bash
# JAR 파일 빌드
./gradlew clean build

# 빌드 결과물 확인
ls -la build/libs/
# 예: aws-v1-0.0.1-SNAPSHOT.jar
```

> 💡 `clean`을 함께 실행하면 이전 빌드 결과물을 제거하고 깨끗한 상태에서 빌드합니다.

### 5.5 nohup으로 백그라운드 실행

`nohup`(no hang up)을 사용하면 SSH 세션이 끊겨도 프로세스가 종료되지 않습니다.

```bash
nohup java -jar build/libs/aws-v1-0.0.1-SNAPSHOT.jar &
```

- `nohup`: 터미널 종료 시에도 프로세스 유지
- `&`: 백그라운드 실행

### 5.6 오류 로그 남기기 (표준 입출력 리다이렉션)

리눅스의 표준 스트림을 활용하여 로그를 파일로 저장합니다.

| 스트림 | 파일 디스크립터 | 설명 |
|--------|----------------|------|
| 표준 입력 (stdin) | 0 | 키보드 입력 |
| 표준 출력 (stdout) | 1 | 정상 출력 메시지 |
| 표준 에러 (stderr) | 2 | 에러/경고 메시지 |

```bash
# stdout과 stderr를 모두 log.out 파일에 저장
nohup java -jar build/libs/aws-v1-0.0.1-SNAPSHOT.jar > log.out 2>&1 &
```

**명령어 해석:**

| 부분 | 의미 |
|------|------|
| `> log.out` | 표준 출력(1)을 log.out 파일로 리다이렉션 |
| `2>&1` | 표준 에러(2)를 표준 출력(1)이 가리키는 곳(log.out)으로 리다이렉션 |

```bash
# 실시간 로그 확인
tail -f log.out

# 최근 100줄 확인
tail -n 100 log.out
```

### 5.7 cron으로 자동 재시작 설정

서버(프로세스)가 예기치 않게 종료되었을 때, `cron`을 이용해 자동으로 재시작하도록 설정합니다.

**Step 1: 헬스 체크 및 재시작 스크립트 작성**

```bash
vi /home/ec2-user/healthcheck.sh
```

```bash
#!/bin/bash

PROJECT_PATH="/home/ec2-user/aws-v1"
JAR_NAME="aws-v1-0.0.1-SNAPSHOT.jar"
LOG_FILE="$PROJECT_PATH/log.out"

# 현재 실행 중인 프로세스 확인
CURRENT_PID=$(pgrep -f "$JAR_NAME")

if [ -z "$CURRENT_PID" ]; then
    echo "[$(date)] 프로세스 미감지. 재시작 합니다." >> "$LOG_FILE"
    cd "$PROJECT_PATH"
    nohup java -jar "build/libs/$JAR_NAME" >> "$LOG_FILE" 2>&1 &
    echo "[$(date)] 프로세스 재시작 완료. PID: $!" >> "$LOG_FILE"
else
    echo "[$(date)] 프로세스 정상 실행 중. PID: $CURRENT_PID" >> "$LOG_FILE"
fi
```

```bash
# 스크립트 실행 권한 부여
chmod +x /home/ec2-user/healthcheck.sh
```

**Step 2: crontab 등록**

```bash
# crontab 편집기 열기
crontab -e
```

```cron
# 매 1분마다 헬스 체크 스크립트 실행
* * * * * /home/ec2-user/healthcheck.sh
```

```
# cron 표현식 참고
# ┌───────── 분 (0~59)
# │ ┌─────── 시 (0~23)
# │ │ ┌───── 일 (1~31)
# │ │ │ ┌─── 월 (1~12)
# │ │ │ │ ┌─ 요일 (0~7, 0과 7은 일요일)
# │ │ │ │ │
# * * * * * 실행할 명령어
```

```bash
# 등록된 crontab 확인
crontab -l
```

---

## 6. 💡 향후 고민과 개선 방향

현재 수동 배포 방식의 한계를 인식하고, 단계적으로 개선해 나가기 위한 로드맵입니다.

### 고민 1 : 로컬과 EC2 환경 일치 → Docker

> **문제**: "내 로컬에서는 되는데, EC2에서는 안 돼요..."

로컬 개발 환경(OS, JDK 버전, 환경변수 등)과 EC2 환경이 다르면 예기치 못한 오류가 발생합니다.

**해결: Docker 가상화 기술**

- Docker는 애플리케이션과 그 실행 환경을 하나의 **컨테이너**로 패키징합니다.
- 로컬, EC2, 어디서든 동일한 컨테이너를 실행하므로 "환경 차이" 문제가 사라집니다.

```
[로컬] Dockerfile → Docker Image → 컨테이너 실행 (테스트)
                        ↓ push
                   [Docker Hub]
                        ↓ pull
[EC2]              Docker Image → 컨테이너 실행 (배포)
```

| 키워드 | 설명 |
|--------|------|
| Dockerfile | 이미지를 만들기 위한 설정 파일 (레시피) |
| Docker Image | 실행 가능한 패키지 (읽기 전용 템플릿) |
| Docker Container | 이미지를 기반으로 실행된 인스턴스 (실제 동작 환경) |
| Docker Hub | 이미지를 저장하고 공유하는 원격 저장소 |

---

### 고민 2 : 테스트 전용 서버 → Staging

> **문제**: "운영 서버에 바로 배포했다가 장애가 나면 어쩌지?"

**해결: Staging(스테이징) 서버 구축**

운영(Production) 환경과 동일한 구성의 테스트 전용 서버를 별도로 운영합니다.

```
[로컬 개발] → [Staging 서버: 테스트] → 검증 완료 → [Production 서버: 운영 배포]
```

| 환경 | 용도 | 특징 |
|------|------|------|
| Local | 개발, 단위 테스트 | 개발자 PC |
| Staging | 통합 테스트, QA | 운영과 동일 환경, 외부 비공개 |
| Production | 실제 사용자 서비스 | 안정성 최우선 |

---

### 고민 3 : 트래픽 폭증 대응 → Auto Scaling / Elastic Beanstalk

> **문제**: "갑자기 사용자가 몰리면 서버 한 대로 버틸 수 있을까?"

**해결: AWS Elastic Beanstalk**

Elastic Beanstalk은 배포, 로드 밸런싱, 오토 스케일링, 모니터링을 자동으로 관리해주는 AWS 서비스입니다.

```
                    ┌─── EC2 인스턴스 1
사용자 → [ELB] ────┼─── EC2 인스턴스 2  ← Auto Scaling
                    └─── EC2 인스턴스 3
```

| 구성 요소 | 역할 |
|-----------|------|
| **ELB** (Elastic Load Balancer) | 트래픽을 여러 인스턴스에 분산 |
| **Auto Scaling Group** | 트래픽에 따라 인스턴스 수를 자동 조절 (Scale Out / In) |
| **CloudWatch** | 서버 상태를 모니터링하고 알림 전송 |

- **Scale Up**: 서버 사양을 높이는 것 (수직 확장)
- **Scale Out**: 서버 수를 늘리는 것 (수평 확장) ← Auto Scaling이 담당

---

### 고민 4 : 자동 배포 → GitHub Actions (CI/CD)

> **문제**: "매번 SSH 접속해서 git pull, build, 재시작... 너무 번거로워요."

**해결: GitHub Actions를 활용한 CI/CD 파이프라인**

GitHub에 코드를 push하면 자동으로 테스트, 빌드, 배포까지 수행됩니다.

```
[git push] → [GitHub Actions]
                 ├── ✅ 코드 체크아웃
                 ├── ✅ JDK 설치
                 ├── ✅ 테스트 실행
                 ├── ✅ JAR 빌드
                 └── ✅ EC2로 배포 (SCP/SSH 또는 Docker)
```

| 용어 | 설명 |
|------|------|
| **CI** (Continuous Integration) | 코드 변경 시 자동으로 테스트 및 빌드 수행 |
| **CD** (Continuous Deployment) | 빌드 결과물을 자동으로 서버에 배포 |
| **Workflow** | GitHub Actions에서 CI/CD 파이프라인을 정의하는 YAML 파일 |

---

## 7. 📋 참고 명령어 모음

### 프로세스 관리

```bash
# 실행 중인 Java 프로세스 확인
ps -ef | grep java

# 특정 포트(8080) 사용 중인 프로세스 확인
sudo lsof -i :8080

# PID로 프로세스 종료
kill -9 <PID>

# jar 이름으로 프로세스 종료
pkill -f "aws-v1-0.0.1-SNAPSHOT.jar"
```

### 로그 확인

```bash
# 실시간 로그 모니터링
tail -f log.out

# 로그에서 에러만 검색
grep -i "error" log.out

# 로그에서 특정 시간대 검색
grep "2025-04-17" log.out
```

### 배포 원라이너 (빠른 재배포)

```bash
# 기존 프로세스 종료 → 빌드 → 실행을 한 줄로
pkill -f "aws-v1" ; cd ~/aws-v1 && git pull origin main && ./gradlew clean build && nohup java -jar build/libs/aws-v1-0.0.1-SNAPSHOT.jar > log.out 2>&1 &
```

---

## 📚 학습 로드맵

```
현재 단계                          향후 학습 방향
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[v1] EC2 수동 배포 (현재)
  └──→ [v2] Docker 컨테이너 배포
         └──→ [v3] Staging + Production 분리
                └──→ [v4] Elastic Beanstalk (Auto Scaling)
                       └──→ [v5] GitHub Actions CI/CD
```

---

> 📝 이 프로젝트는 AWS 배포 학습을 위한 프로젝트이며, 단계별로 인프라를 개선해 나가는 과정을 기록합니다.
