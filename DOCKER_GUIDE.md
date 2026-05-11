# 도커 컨테이너화 가이드 (Dockerization Guide)

이 가이드는 의료 MSA 플랫폼을 컨테이너화하고 실행하는 방법을 설명합니다.

## 1. 사전 준비 사항

- **Docker Desktop**: 설치 및 실행 중이어야 합니다.
- **Java 17 (JDK)**: 빌드를 위해 설치되어 있어야 합니다.
- **Gradle**: 프로젝트에 포함된 래퍼를 사용합니다.

## 2. Jar 파일 빌드

도커 이미지를 만들기 전에, 각 Spring Boot 서비스의 실행 가능한 Jar 파일을 생성해야 합니다.

루트 디렉토리에서 다음 명령어를 실행하세요:

```bash
./gradlew clean build -x test
```

성공하면 각 하위 프로젝트의 `build/libs/` 폴더에 `*.jar` 파일이 생성됩니다.

## 3. Docker Compose로 실행

Jar 파일 빌드가 완료되면, 단 하나의 명령어로 전체 클러스터를 실행할 수 있습니다.

```bash
docker-compose up --build
```

### 이 명령어가 수행하는 작업:
- **이미지 빌드**: 모든 서비스(Gateway, Patient, Eureka 등)의 이미지를 빌드합니다.
- **데이터베이스 실행**: 환자, 예약, 처방 서비스를 위한 PostgreSQL 컨테이너를 실행합니다.
- **네트워크 설정**: 서비스들이 서로 통신할 수 있도록 내부 네트워크를 구축합니다.

## 4. 서비스 접속 정보

| 서비스 | 호스트 포트 | 내부 포트 | 설명 |
| :--- | :--- | :--- | :--- |
| **대시보드 UI** | 80 | 80 | 메인 화면 (브라우저 접속) |
| **API 게이트웨이** | 8080 | 8080 | API 요청 진입점 |
| **유레카 서버** | 8761 | 8761 | 서비스 상태 모니터링 대시보드 |

## 5. 주요 설정 (환경 변수 오버라이드)

`docker-compose.yml` 파일은 `application.yml`의 기본 설정을 환경 변수로 덮어씁니다:

- `EUREKA_CLIENT_SERVICEURL_DEFAULTZONE`: 유레카 서버 주소를 `http://eureka-server:8761/eureka/`로 설정합니다.
- `SPRING_DATASOURCE_URL`: 각 서비스가 H2 대신 도커 내 PostgreSQL 컨테이너에 연결하도록 설정합니다.

## 6. 문제 해결 (Troubleshooting)

- **로그 확인**: `docker-compose logs -f [서비스명]`
- **특정 서비스만 재시작**: `docker-compose restart [서비스명]`
- **전체 중지 및 데이터 초기화**: `docker-compose down -v`
