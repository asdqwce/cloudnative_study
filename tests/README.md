# 테스트 실행 가이드

이 프로젝트의 테스트 진입점은 루트 `Makefile`입니다. 개발자 로컬에는 Docker, Docker Compose, Make만 준비하고, Java/Gradle/Newman 실행은 컨테이너 안에서 수행합니다.

통합 테스트는 Testcontainers로 PostgreSQL과 Kafka를 직접 띄워 실제 인프라에 가까운 환경에서 실행합니다. E2E 테스트는 기존처럼 Docker Compose 서비스와 Newman 컨테이너로 전체 사용자 흐름을 검증합니다.

## 준비물

| OS | 기준 환경 |
| --- | --- |
| macOS | Docker Desktop, Make |
| Linux | Docker Engine, Docker Compose plugin, Make |
| Windows | Docker Desktop, Make를 사용할 수 있는 터미널 환경 |

Windows에서는 Git Bash, WSL, Chocolatey/winget으로 설치한 Make 등 `make` 명령을 실행할 수 있는 환경을 사용합니다. Docker Desktop은 Linux container 모드로 실행합니다.

`make test-integration`은 Docker Gradle 러너 안에서 다시 Testcontainers 컨테이너를 띄웁니다. 그래서 러너 컨테이너에는 `/var/run/docker.sock`이 마운트되고, 테스트 프로세스에는 `TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal`이 전달됩니다. Linux에서 `host.docker.internal` 해석이 필요하므로 Makefile은 기본적으로 `--add-host=host.docker.internal:host-gateway`를 붙입니다. Docker Desktop 29처럼 낮은 Docker API 버전 협상을 거부하는 환경을 위해 `DOCKER_API_VERSION=1.41`도 명시합니다.

Testcontainers reusable mode는 팀 기본값으로 강제하지 않습니다. 개인 로컬에서 반복 실행 시간을 줄이고 싶다면 본인 환경의 `~/.testcontainers.properties`에 `testcontainers.reuse.enable=true`를 선택적으로 설정합니다.

## 폴더 구조

```text
tests/
  docker/
    Dockerfile
  integration-support/
    java/
      com/medical/testsupport/AbstractIntegrationTest.java
  e2e/
    postman/
      medical-platform.postman_collection.json
    newman/
      docker.postman_environment.json
    scripts/
      wait-for-services.sh
```

서비스 내부 단위/통합 테스트는 각 모듈의 `src/test/java` 아래에 둡니다. 여러 서비스를 관통하는 Newman E2E 테스트만 루트 `tests/e2e` 아래에 둡니다.

## 통합 테스트 흐름

`patient-service`, `appointment-service`, `prescription-service`, `notification-service`의 통합 테스트는 공통 `AbstractIntegrationTest`를 상속합니다.

| 인프라 | 실행 방식 | 격리 기준 |
| --- | --- | --- |
| PostgreSQL | `PostgreSQLContainer` 공유 | 테스트 실행 ID 기반 schema suffix |
| Kafka | `KafkaContainer` 공유 | 테스트 실행 ID 기반 topic/group suffix |

Spring 설정은 `DynamicPropertySource`로 주입합니다. 테스트 클래스에는 H2 datasource를 직접 지정하지 않으며, Hibernate는 Testcontainers PostgreSQL의 실행별 schema에 테이블을 생성합니다.

Kafka가 필요한 흐름은 mock 로그가 아니라 실제 Kafka topic을 사용합니다. `appointment-service`는 예약 확정 이벤트가 Kafka topic에 발행되는지 확인하고, `notification-service`는 Kafka 이벤트를 소비해 알림을 저장하는지 확인합니다.

`PrescriptionIntegrationTest`의 `PatientClient @MockBean`은 유지합니다. 이 테스트의 범위는 처방 서비스 내부 통합 테스트이고, 서비스 간 실제 HTTP 흐름은 Newman E2E가 담당합니다.

## 실행 명령

```sh
make help
make list
make test-unit
make test-integration
make test-e2e
make test
```

`make test-all`은 `make test`와 같은 전체 테스트 흐름입니다.

| 명령 | 실행 내용 |
| --- | --- |
| `make help` | 사용 가능한 Make 테스트 명령 목록 출력 |
| `make list` | `make help`와 같은 명령 목록 출력 |
| `make test-unit` | Docker 테스트 러너를 빌드한 뒤 Gradle `testUnit` 실행 |
| `make test-integration` | Docker 테스트 러너를 빌드한 뒤 Testcontainers PostgreSQL/Kafka 기반 Gradle `testIntegration` 실행 |
| `make test-e2e` | Docker Compose로 서비스 기동, readiness 확인, Newman 컨테이너 실행, 서비스 정리 |
| `make test` | 단위, 통합, E2E 순서로 전체 실행 |
| `make clean-test` | E2E Compose 리소스와 Gradle 캐시 볼륨 정리 |

## E2E 흐름

Newman 컬렉션은 API Gateway 기준으로 다음 사용자 흐름을 검증합니다.

1. `/auth/token`에서 테스트 토큰 발급
2. `/patient-service/patients`로 환자 생성
3. `/patient-service/patients/{id}`로 환자 조회
4. `/appointment-service/appointments`로 예약 생성
5. `/appointment-service/appointments/{id}/confirm`로 예약 확정
6. `/prescription-service/prescriptions`로 처방 생성
7. `/notification-service/notifications`로 알림 조회

`tests/e2e/scripts/wait-for-services.sh`는 Newman 실행 전에 API Gateway 토큰 엔드포인트와 Eureka 등록 상태를 확인합니다.

## 실패 시 점검 포인트

| 증상 | 점검 |
| --- | --- |
| Docker build 실패 | Docker Desktop/Engine이 실행 중인지 확인 |
| `docker compose` 명령 실패 | Compose plugin 설치 여부 확인 |
| `make` 명령 없음 | macOS/Linux는 Make 설치, Windows는 Git Bash/WSL/Make 설치 확인 |
| Testcontainers가 Docker에 연결하지 못함 | `/var/run/docker.sock` 마운트 여부와 Docker daemon 실행 상태 확인 |
| 통합 테스트에서 mapped port 접속 실패 | `TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal` 값과 `--add-host=host.docker.internal:host-gateway` 지원 여부 확인 |
| Docker API 400 응답 | `DOCKER_API_VERSION=1.41` 이상으로 실행되는지 확인 |
| Kafka 이벤트 테스트 timeout | topic suffix가 테스트 실행 ID로 주입됐는지, consumer group이 이전 실행과 충돌하지 않는지 확인 |
| E2E readiness timeout | `docker compose -p medical-platform-test ps`와 서비스 로그 확인 |
| Newman 401 응답 | 토큰 발급 요청이 먼저 성공했는지, Authorization 헤더가 유지되는지 확인 |
| Newman 404 응답 | Gateway 라우트와 서비스 컨트롤러 경로가 맞는지 확인 |

E2E 실패 후 수동 정리는 다음 명령을 사용합니다.

```sh
make e2e-down
```
